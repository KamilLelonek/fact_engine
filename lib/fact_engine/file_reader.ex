defmodule FactEngine.FileReader do
  @newline ~r/\R/

  alias FactEngine.Parser
  alias FactEngine.Action

  @spec call(String.t()) :: list(Action.t())
  def call(name) do
    name
    |> File.read!()
    |> String.split(@newline, trim: true)
    |> Enum.map(&Parser.call/1)
  end
end
