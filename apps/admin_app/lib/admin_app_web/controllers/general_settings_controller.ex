defmodule AdminAppWeb.GeneralSettingsController do
  use AdminAppWeb, :controller
  alias Snitch.Data.Model.Setting.General, as: GeneralSetting
  alias Snitch.Data.Schema.Setting.General, as: SettingSchema

  def new(conn, _params) do
    case GeneralSetting.check_if_present() do
      nil ->
        changeset = SettingSchema.create_changeset(%SettingSchema{}, %{})
        render(conn, "new.html", changeset: changeset)

      setting ->
        changeset = SettingSchema.update_changeset(setting, %{})
        render(conn, "edit.html", changeset: changeset, setting: setting)
    end
  end

  def create(conn, %{"general_settings" => settings}) do
    case GeneralSetting.create(settings) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Settings Updated!")
        |> redirect(to: "/")

      {:error, changeset} ->
        conn
        |> put_flash(:error, "Some error occured")
        |> render("new.html", changeset: changeset)
    end
  end

  def update(conn, %{"id" => id, "general_settings" => params}) do
    setting = id |> String.to_integer() |> GeneralSetting.get()

    case GeneralSetting.update(params, setting) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Settings Updated!")
        |> redirect(to: "/")

      {:error, changeset} ->
        conn
        |> put_flash(:error, "Some error occured")
        |> render("edit.html", changeset: %{changeset | action: :update}, setting: setting)
    end
  end
end
