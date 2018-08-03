defmodule Snitch.Domain.Payment.Transitions do
  @moduledoc """
  Helpers for the `Payment` state machine.
  """

  alias Snitch.Data.Model.Payment, as: PModel
  alias BeepBop.Context

  def persist_payment_method(
        %Context{
          valid?: true,
          state: %{
            payment_type: "ccd",
            amount: amount,
            card: card
          },
          struct: order
        } = context
      ) do
    params = %{amount: amount, payment_type: "ccd"}

    {:ok, %{payment: payment, card_payment: card_payment}} =
      CardPayment.create("card-payment", order.id, params, %{card: Map.from_struct(card)})

    struct(context, struct: payment)
  end
end
