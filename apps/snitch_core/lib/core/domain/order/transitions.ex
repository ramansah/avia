defmodule Snitch.Domain.Order.Transitions do
  @moduledoc """
  Helpers for the `Order` state machine.

  The `Snitch.Domain.Order.DefaultMachine` makes direct use of these helpers.

  By documenting these handy functions, we encourage the developer of a custom
  state machine to use, extend or compose them to build large event transitions.
  """

  use Snitch.Domain

  alias BeepBop.Context
  alias Snitch.Data.Model.Package
  alias Snitch.Data.Schema.Order

  alias Snitch.Domain.Order, as: OrderDomain
  alias Snitch.Domain.Package, as: PackageDomain
  alias Snitch.Domain.{Shipment, ShipmentEngine, Splitters.Weight}

  @doc """
  Embeds the addresses and computes some totals of the `order`.

  The following fields are required under the `:state` key:
  * `:billing_address` The billing `Address` params
  * `:shipping_address` The shipping `Address` params

  The following fields are computed: `item_total`, `tax_total` and `total`.
  `total` = `item_total` + `tax_total`
  > The promo and adjustment totals are ignored for now.
  """
  @spec associate_address(Context.t()) :: Context.t()
  def associate_address(
        %Context{
          valid?: true,
          struct: order,
          multi: multi,
          state: %{
            billing_address: billing,
            shipping_address: shipping
          }
        } = context
      ) do
    changeset =
      order
      |> Order.partial_update_changeset(%{billing_address: billing, shipping_address: shipping})
      |> OrderDomain.compute_taxes_changeset()

    if changeset.valid? do
      struct(context, multi: Multi.update(multi, :order, changeset))
    else
      struct(context, valid?: false, errors: [order: changeset])
    end
  end

  def associate_address(%Context{} = context), do: struct(context, valid?: false)

  @doc """
  Computes a shipment fulfilling the `order`.

  Returns a new `Context.t` struct with the `shipment` under the the [`:state`,
  `:shipment`] key-path.

  > The `:state` key of the `context` is not utilised here.

  ## Note

  If `shipment` is `[]`, we DO NOT mark the `context` "invalid".
  """
  @spec compute_shipments(Context.t()) :: Context.t()
  # TODO: This function does not gracefully handle errors, they are raised!
  def compute_shipments(%Context{valid?: true, struct: order, state: state} = context) do
    order =
      if is_nil(order.shipping_address) do
        %{order | shipping_address: state.shipping_address}
      else
        order
      end

    shipment =
      order
      |> Shipment.default_packages()
      |> ShipmentEngine.run(order)
      |> Weight.split()

    struct(context, state: %{shipment: shipment})
  end

  def compute_shipments(%Context{valid?: false} = context), do: context

  @doc """
  Persists the computed shipment to the DB.

  `Package`s and their `PackageItem`s are inserted together in a DB transaction.

  The `packages` are added to the `:state` under the `:packages` key.
  Thus the signature of `context.state.packages` is,
  ```
  context.state.packages :: {:ok, [Pacakge.t()]} | {:error, Ecto.Changeset.t()}
  ```
  """
  @spec persist_shipment(Context.t()) :: Context.t()
  def persist_shipment(%Context{valid?: true, struct: %Order{} = order} = context) do
    %{state: %{shipment: shipment}} = context

    packages =
      Repo.transaction(fn ->
        shipment
        |> Stream.map(&Shipment.to_package(&1, order))
        |> Stream.map(&Package.create/1)
        |> fail_fast_reduce()
        |> case do
          {:error, error} ->
            Repo.rollback(error)

          {:ok, packages} ->
            packages
        end
      end)

    state = Map.put(context.state, :packages, packages)
    struct(context, state: state)
  end

  def persist_shipment(%Context{valid?: false} = context), do: context

  @doc """
  Persists the shipping preferences of the user in each `package` of the `order`.

  Along with the chosen `ShippingMethod`, we update pacakge price fields. User's
  selection is assumed to be under the `context.state.shipping_preferences` key-path.

  ## Schema of the `:state`
  ```
  %{
    shipping_preferences: [
      %{
        package_id: string,
        shipping_method_id: non_neg_integer
      }
    ]
  }
  ```

  ## Assumptions
  * For each `package` of the `order`, a valid `shipping_method` must be chosen.
    > If an `order` has 3 packages, then
      `length(context.state.shipping_preferences)` must be `3`.
  * The chosen `shipping_method` for the `package` must be one among the
    `package.shipping_methods`.
  """
  @spec persist_shipping_preferences(Context.t()) :: Context.t()
  def persist_shipping_preferences(%Context{valid?: true, struct: %Order{} = order} = context) do
    %{state: %{shipping_preferences: shipping_preferences}, multi: multi} = context

    packages = Map.fetch!(Repo.preload(order, [:packages]), :packages)

    if validate_shipping_preferences(packages, shipping_preferences) do
      function = fn _ ->
        shipping_preferences
        |> Stream.map(fn %{package_id: package_id, shipping_method_id: shipping_method_id} ->
          packages
          |> Enum.find(fn %{id: id} -> id == package_id end)
          |> PackageDomain.set_shipping_method(shipping_method_id)
        end)
        |> fail_fast_reduce()
      end

      struct(context, multi: Multi.run(multi, :packages, function))
    else
      struct(context, valid?: false, errors: [shipping_preferences: "is invalid"])
    end
  end

  defp validate_shipping_preferences([], _), do: true

  defp validate_shipping_preferences(packages, selection) do
    # selection must be over all packages, no package can be skipped.
    # TODO: Replace with some nice API contract/validator.
    package_ids =
      packages
      |> Enum.map(fn %{id: id} -> id end)
      |> MapSet.new()

    selection
    |> Enum.map(fn %{package_id: p_id} -> p_id end)
    |> MapSet.new()
    |> MapSet.equal?(package_ids)
  end

  defp fail_fast_reduce(things) do
    Enum.reduce_while(things, {:ok, []}, fn
      {:ok, thing}, {:ok, acc} ->
        {:cont, {:ok, [thing | acc]}}

      {:error, _} = error, _ ->
        {:halt, error}
    end)
  end
 
  defp calc_payable_amount(order) do
    packages_total = Package.compute_package_total(order)
    total_amount = Money.add!(packages_total, order.total)
    amount_paid_before = Payment.compute_order_payments(order)
    Money.sub!(total_amount, amount_paid_before)
  end

  @spec compute_order_payment(Context.t()) :: Context.t()
  def compute_order_payment(
        %Context{valid?: true, struct: %Order{id: order_id} = order} = context
      ) do
    %{state: %{payment: payment}, multi: multi} = context
    amount_to_pay = calc_payable_amount(order)
    payment_method = PaymentMethod.get(payment.payment_method_id)
    # case payment_method.code do
      # "chk" ->
        # process_payment_chk(payment_method, order)
    #
    #   "ccd" ->
    #     process_payment_chk(payment_method, order)
    # end
  end
end
