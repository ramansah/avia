defmodule AdminAppWeb.ZoneController do
  use AdminAppWeb, :controller

  alias Snitch.Data.Model.Zone
  alias Snitch.Data.Schema.Zone, as: ZoneSchema
  alias Snitch.Repo

  def index(conn, _params) do
    zones = Zone.get_all()
    render(conn, "index.html", zones: zones)
  end

  def new(conn, _params) do
    changeset = ZoneSchema.create_changeset(%ZoneSchema{}, %{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, params) do
    zone_changeset = ZoneSchema.create_changeset(%ZoneSchema{}, params["zone"])
    zone_multi = Zone.creation_multi(zone_changeset, params["zone"]["members"])

    case Repo.transaction(zone_multi, []) do
      {:ok, _response} ->
        conn
        |> put_flash(:info, "Zone created!!")
        |> redirect(to: zone_path(conn, :index))

      {:error, _, changset, _} ->
        conn
        |> put_flash(:error, "Sorry there were some errors !!")
        |> render("new.html", changeset: changset)
    end
  end
end
