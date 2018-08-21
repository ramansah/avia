defmodule Snitch.Data.Model.Setting.General do
  @moduledoc """
  General Settings API.
  """

  use Snitch.Data.Model
  alias Snitch.Data.Schema.Setting
  alias Snitch.Repo

  @doc """
  Creates new  `general settings` with supplied `params`.
  """
  @spec create(map) :: {:ok, Setting.General.t()} | {:error, Ecto.Changeset.t()}
  def create(params) do
    QH.create(Setting.General, params, Repo)
  end

  @doc """
  Updates a `general_settings` with the supplied params.

  To update either the `id` field should be supplied in the
  `params` map or, the `struct` of the type `Setting.General`
  to be updated should be passed as second argument.
  """
  @spec update(map) :: {:ok, Setting.General.t() | nil} | {:error, Ecto.Changeset.t()}
  def update(params, instance \\ nil) do
    QH.update(Setting.General, params, instance, Repo)
  end

  @doc """
  Deletes `general settings` setup in the system.

  Takes as input `id` or `struct`.
  """
  @spec delete(integer | Setting.General.t()) ::
          {:ok, Setting.General.t()}
          | {:error, Ecto.ChangeSet.t()}
          | {:error, :not_found}
  def delete(param) do
    QH.delete(Setting.General, param, Repo)
  end

  @doc """
  Returns `Setting.General` struct.

  Takes as input `id`.
  """
  @spec get(integer) :: Setting.General.t() | nil
  def get(id) do
    QH.get(Setting.General, id, Repo)
  end

  @doc """
  Returns a general setting if found otherwise retrns
  nil.
  """
  @spec check_if_present() :: Setting.General.t() | nil
  def check_if_present() do
    case Repo.all(Setting.General) do
      [] ->
        nil

      [hd | _] ->
        hd
    end
  end
end
