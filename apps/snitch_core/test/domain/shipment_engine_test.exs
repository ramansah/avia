defmodule Snitch.Domain.ShipmentEngineTest do
  use ExUnit.Case, async: true
  use Snitch.DataCase

  alias Snitch.Data.Schema.{Order, StockLocation}
  import Snitch.{OrderCase, StockCase, ShipmentEngineCase}
  import Snitch.Factory

  @sl_manifest %{
    "default" => %{
      default: true
    },
    "backup" => %{},
    "origin" => %{}
  }

  setup :variants
  setup :stock_locations

  @tag variant_count: 4
  test "foo", context do
    %{variants: vs} = context
    line_items = line_items_with_price(vs, [3, 3, 3, 3])
    order = %Order{id: 42, line_items: line_items, shipping_address: insert(:address)}
    packages = packages(line_items, context)
  end

  defp stock_locations(context) do
    locations =
      context
      |> Map.get(:stock_location_manifest, @sl_manifest)
      |> stock_locations_with_manifest()

    {_, stock_locations} = Repo.insert_all(StockLocation, locations, returning: true)

    [stock_locations: stock_locations]
  end
end
