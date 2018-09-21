defmodule AdminAppWeb.ZoneView do
  use AdminAppWeb, :view

  alias Snitch.Data.Model.{State, Country}

  def get_zones() do
    [Map.new() |> Map.put(:name, "Country") |> Map.put(:value, "C")] ++
      [Map.new() |> Map.put(:name, "State") |> Map.put(:value, "S")]
  end

  def get_states() do
    State.formatted_list()
  end

  def get_countries() do
    Country.formatted_list()
  end

  def get_zone_by_type(zone) do
    case zone.zone_type do
      "C" -> "Country"
      "S" -> "State"
    end
  end
end
