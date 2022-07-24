defmodule FactEngine.Parser do
  alias FactEngine.Action
  alias FactEngine.Substitution

  @delimiter ", "
  @regex_line ~r/[[:space:]]/
  @regex_attributes ~r/[[:alpha:] | [:space:] | _ | #{@delimiter}]+/
  @regex_substitution ~r/^[[:upper:]]{1}[[:alnum:]]*$/

  @doc """

  PART 1 |    PART 2   | PART 3
  TYPE   |     FACT    | ARGUMENTS
  INPUT    are_friends   (frog, toad)
  """
  @spec call(String.t()) :: Action.t()
  def call(line) do
    [type, fact, attributes] = String.split(line, @regex_line, parts: 3)
    {arity, attributes} = extract_attributes(attributes)

    Action.new(type, fact, arity, attributes)
  end

  defp extract_attributes(attributes) do
    with [match] <- Regex.run(@regex_attributes, attributes) do
      attributes =
        match
        |> String.split(@delimiter)
        |> Enum.map(&maybe_match_substitution/1)

      {length(attributes), attributes}
    end
  end

  defp maybe_match_substitution(attribute) do
    case Regex.run(@regex_substitution, attribute) do
      nil -> attribute
      [substitution] -> Substitution.new(substitution)
    end
  end
end
