defmodule Snitch.ShipmentEngineCase do
  @moduledoc """
  Test helper for creating packages for shipment engine.

  Creates packages based on the type of package for given lineitems.
  > A package of type [1,0,1,0] means the package will fulfill 
    first and third lineitem.
  """
  alias Snitch.Data.Schema.LineItem

  @package %{
    items: [
      %{
        variant: nil,
        line_item: nil,
        variant_id: 0,
        state: nil,
        quantity: 0,
        delta: 0
      }
    ],
    origin: %{},
    backorders?: true,
    variants: MapSet.new()
  }

  @package_types [[1, 0, 1, 0], [1, 1, 1, 1], [1, 0, 0, 0], [0, 1, 0, 1]]

  @doc """
  Returns #{length(@package_types)} pacakges with varied degree of fulfillment
  for given `lisitems`.
  """
  @spec packages([%LineItem{}], map) :: term
  def packages(lineitems, %{stock_locations: sls, variants: vs}) do
    for i <- @package_types do
      package_with_items(lineitems, sls, vs, i)
    end
  end

  defp package_with_items(lineitems, stocks, variants, item_fulfillment) do
    stock = Enum.random(stocks)

    items =
      lineitems
      |> Enum.zip(variants)
      |> Enum.zip(item_fulfillment)
      |> Enum.map(fn {{li, v}, itf} ->
        if itf == 1 do
          %{
            variant: v,
            lineitem: li,
            state: :fulfilled,
            quantity: li.quantity,
            delta: 0
          }
        end
      end)
      |> Enum.filter(fn x -> is_nil(x) == false end)

    bo = Enum.any?(item_fulfillment, fn x -> x == 0 end)
    value = %{@package | items: items, origin: stock, backorders?: bo}
  end
end
