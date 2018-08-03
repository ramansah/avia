defmodule Snitch.Domain.Payment.DefaultMachine do
  @moduledoc """
  The (default) Payment state machine.
  """

  use Snitch.Domain
  use BeepBop, ecto_repo: Repo

  alias Snitch.Data.Schema.Payment
  alias Snitch.Domain.Payment.Transitions

  state_machine Payment, :state, ~w(init pending paid failed)a do
    @doc """
    Creates Payment record
    and associates selected payment method
    """
    event(:initiate_payment, %{from: [:init], to: :pending}, fn context ->
      Transitions.create_payment(context)
    end)
  end
end
