defmodule Snitch.Data.Schema.Setting.General do
  @moduledoc """
  Models general settings in spree.

  Provides a way to store the general configurations for
  a store. e.g. the contact information, meta information etc.
  """

  # TODO Current implmentation is very basic, come up with a better
  #      solution to implemetn a {k,v} type which is generic. General
  #      setting should have a way to add new keys.

  use Snitch.Data.Schema

  @type t :: %__MODULE__{}

  schema "snitch_general_settings" do
    field(:site_name, :string)
    field(:seo_title, :string)
    field(:meta_keywords, :string)
    field(:meta_description, :string)
    field(:mail_from, :string)

    timestamps()
  end

  @email_regex ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/
  @create_fields ~w(site_name seo_title meta_keywords meta_description mail_from)a
  @update_fields @create_fields

  @doc """
  Returns a changeset to create `GeneralSetting`s.
  """
  @spec create_changeset(t, map) :: Ecto.Changeset.t()
  def create_changeset(%__MODULE__{} = setting, params) do
    setting
    |> cast(params, @create_fields)
    |> validate_format(:mail_from, ~r/@/)
  end

  @doc """
  Returns a changeset to update `GeneralSetting`s.
  """
  @spec update_changeset(t, map) :: Ecto.Changeset.t()
  def update_changeset(%__MODULE__{} = setting, params) do
    setting
    |> cast(params, @update_fields)
    |> validate_format(:mail_from, @email_regex)
  end
end
