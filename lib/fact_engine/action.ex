defmodule FactEngine.Action do
  @keys ~w(type fact arity attributes)a

  @enforce_keys @keys

  defstruct @keys

  @type t :: %__MODULE__{
          type: String.t(),
          fact: String.t(),
          arity: pos_integer(),
          attributes: list(String.t() | FactEngine.Substitution.t())
        }

  @spec new(
          String.t(),
          String.t(),
          pos_integer(),
          list(String.t() | FactEngine.Substitution.t())
        ) ::
          t()
  def new(type, fact, arity, attributes) do
    %__MODULE__{
      type: type,
      fact: fact,
      arity: arity,
      attributes: attributes
    }
  end
end
