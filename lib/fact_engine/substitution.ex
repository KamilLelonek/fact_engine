defmodule FactEngine.Substitution do
  @keys ~w(symbol)a

  @enforce_keys @keys

  defstruct @keys

  @type t :: %__MODULE__{
          symbol: String.t()
        }

  @spec new(String.t()) :: t()
  def new(symbol), do: %__MODULE__{symbol: symbol}
end
