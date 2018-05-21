defmodule Snitch.Domain.ShipmentEngine do
  @moduledoc """
  Implements functions to handle creation of the optimal shipment.

  The package struct:
  ```
  %{
    hash: TBD
    items: [
      %{
        variant: %Variant{},
        line_item: %LineItem{},
        variant_id: 0,
        state: :fulfilled | :backorder,
        quantity: 0,
        delta: line_item.quantity - package_quantity
       }
    ],
    zone: %Zone{}
    shipping_methods: [%ShippingMethod{}],
    origin: %StockLocation{}, # the `:stock_items` will not be "loaded"
    category: %ShippingCategory{},
    backorders?: true | false,
    variants: [variant_id]
   }
  ```
  pckgs = [%{name: "p1", variants: [1,3]}, %{name: "p2", variants: [1,2,3,4]}, 
    %{name: "p3", variants: [1]}, %{name: "p4", variants: [2,4]}]
  """
  import Aruspex.Problem, only: [new: 0, add_variable: 3, post: 4, post: 3]
  @domain [true, false]

  def run_through_engine(packages, order) do
    edges = create_csp(packages)
    problem = new()
    domain = @domain

    Enum.map(packages, &add_variable(problem, &1, domain))

    Enum.map(edges, fn {x, y} ->
      problem
      |> post(x, y, &(not (&1 and &2)))
    end)

    result = problem |> Aruspex.Strategy.SimulatedAnnealing.set_strategy() |> Enum.take(1)
  end

  defp create_csp(packages) do
    packages
    |> Enum.map(&group_package_with_item(&1))
    |> List.flatten()
    |> group_packages_by_item()
    |> packages_with_same_item()
    |> filter_self_edges()
    |> find_unique_edges()
  end

  # groups packages by item returns a map 
  # %{item: [{package,item1}, {package, item1}]}
  defp group_packages_by_item(packages) do
    Enum.group_by(packages, fn {_, x} -> x end)
  end

  # Returns a tuple of type {package, item}
  defp group_package_with_item(package) do
    Enum.map(package.variants, fn variant -> {package, variant} end)
  end

  # returns a [{package, package}] type
  defp packages_with_same_item(packages) do
    Enum.map(packages, fn {_, x} ->
      for {s, _} <- x,
          {y, _} <- x,
          do: {s, y}
    end)
  end

  defp filter_self_edges(packages) do
    edges =
      for x <- packages,
          do:
            x
            |> Enum.filter(fn {p, q} -> p != q end)

    List.flatten(edges)
  end

  def find_unique_edges(packages) do
    Enum.reduce(packages, [], fn {x, y}, acc ->
      case Enum.member?(acc, {x, y}) or Enum.member?(acc, {y, x}) do
        true -> acc
        false -> acc ++ [{x, y}]
      end
    end)
  end
end
