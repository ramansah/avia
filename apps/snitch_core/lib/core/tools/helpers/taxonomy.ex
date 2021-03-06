defmodule Snitch.Tools.Helper.Taxonomy do
  @moduledoc """
  Provides helper funtions to easily create taxonomy.
  """

  alias Snitch.Domain.Taxonomy, as: TaxonomyDomain
  alias Snitch.Data.Schema.{Taxon, Taxonomy}
  alias Snitch.Repo

  @doc """
  Creates taxonomy from the hierarchy passed.

  Structure of hierarchy should be in following format
        {"Brands",
          [
            {"Bags", []},
            {"Mugs", []},
            {"Clothing",
             [
               {"Shirts", []},
               {"T-Shirts", []}
          ]}
        ]}
  """
  @spec create_taxonomy({String.t(), []}) :: Taxonomy.t()
  def create_taxonomy({parent, children}) do
    taxonomy =
      %Taxonomy{name: parent}
      |> Taxonomy.changeset()
      |> Repo.insert!()

    taxon = Repo.preload(%Taxon{name: parent, taxonomy_id: taxonomy.id}, :taxonomy)

    root = TaxonomyDomain.add_root(taxon)

    for taxon <- children do
      create_taxon(taxon, root)
    end

    taxonomy
    |> Taxonomy.changeset(%{root_id: root.id})
    |> Repo.update!()
  end

  defp create_taxon({parent, children}, root) do
    child =
      Repo.preload(%Taxon{name: parent, taxonomy_id: root.taxonomy_id, parent_id: root.id}, [
        :taxonomy,
        :parent
      ])

    root = TaxonomyDomain.add_taxon(root, child, :child)

    for taxon <- children do
      create_taxon(taxon, root)
    end
  end

  def convert_to_map(taxonomy) do
    root = convert_taxon(taxonomy.taxons)

    %{
      id: taxonomy.id,
      name: taxonomy.name,
      root: root
    }
  end

  def convert_taxon([]) do
    []
  end

  def convert_taxon({taxon, children}) do
    %{
      id: taxon.id,
      name: taxon.name,
      pretty_name: "",
      permlink: "",
      parent_id: taxon.parent_id,
      taxonomy_id: taxon.taxonomy_id,
      taxons: Enum.map(children, &convert_taxon/1)
    }
  end
end
