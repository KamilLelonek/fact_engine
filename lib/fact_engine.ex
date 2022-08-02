defmodule FactEngine do
  alias FactEngine.Action
  alias FactEngine.Substitution

  @acc {%{}, []}

  @spec process([String.t()]) :: [String.t()]
  def process(lines) do
    with {_facts, result} <- Enum.reduce(lines, @acc, &reduce_action/2),
         do: List.flatten(result)
  end

  defp reduce_action(action, {facts, responses}) do
    case action do
      %Action{type: "INPUT", fact: fact, arity: arity, attributes: attributes} ->
        {eval_input(fact, arity, attributes, facts), responses}

      %Action{type: "QUERY", fact: fact, arity: arity, attributes: attributes} ->
        {facts, responses ++ [eval_query(fact, arity, attributes, facts)]}
    end
  end

  def eval_input(fact, arity, attributes, facts) do
    case facts[fact] do
      nil -> create_fact(fact, arity, attributes, facts)
      _ -> update_fact(fact, arity, attributes, facts)
    end
  end

  def eval_query(fact, arity, attributes, facts) do
    case facts[fact] do
      %{^arity => dictionary} -> reduce_results(dictionary, attributes)
      nil -> [false]
    end
  end

  def process_attribute(key, [%Substitution{symbol: symbol} | []], _dictionary, acc) do
    case acc do
      %{^symbol => ^key} -> acc
      %{^symbol => _} -> []
      _ -> Map.put_new(acc, symbol, key)
    end
  end

  def process_attribute(key, [%Substitution{symbol: symbol} | rest], dictionary, acc) do
    case acc do
      %{^symbol => ^key} -> transform_dictionary(dictionary, key, rest, acc)
      %{^symbol => _} -> []
      _ -> transform_dictionary(dictionary, key, rest, Map.put_new(acc, symbol, key))
    end
  end

  def process_attribute(key, [key | []], _dictionary, acc) when map_size(acc) == 0, do: true
  def process_attribute(key, [key | []], _dictionary, acc), do: acc
  def process_attribute(_key, [_ | []], _dictionary, _acc), do: false

  def process_attribute(key, [key | rest], dictionary, acc),
    do: transform_dictionary(dictionary, key, rest, acc)

  def process_attribute(_key, [_fact | _rest], _dictionary, _acc), do: false

  defp transform_dictionary(dictionary, key, rest, accumulator) do
    dictionary
    |> Map.get(key)
    |> Map.keys()
    |> Enum.map(&process_attribute(&1, rest, dictionary[key], accumulator))
  end

  defp create_fact(fact, arity, attributes, facts) do
    %{}
    |> create_dictionary(Enum.reverse(attributes))
    |> then(&Map.put_new(facts, fact, %{arity => &1}))
  end

  defp create_dictionary(dictionary, []), do: dictionary

  defp create_dictionary(dictionary, [fact | rest]) do
    dictionary
    |> Map.keys()
    |> List.first()
    |> create_dictionary(dictionary, fact, rest)
  end

  defp create_dictionary(nil, dictionary, fact, rest),
    do: create_dictionary(Map.put_new(dictionary, fact, true), rest)

  defp create_dictionary(key, dictionary, fact, rest) do
    dictionary
    |> Map.put_new(fact, %{key => dictionary[key]})
    |> then(&create_dictionary(Map.delete(&1, key), rest))
  end

  defp update_fact(key, arity, attributes, facts) do
    with %{^arity => dictionary} <- facts[key] do
      attributes
      |> update_dictionary(dictionary)
      |> then(&Map.replace!(facts, key, %{arity => &1}))
    end
  end

  def update_dictionary([fact | []], dictionary), do: Map.put_new(dictionary, fact, true)

  def update_dictionary([fact | rest], dictionary) do
    dictionary
    |> Map.get(fact)
    |> case do
      nil -> Map.put_new(dictionary, fact, create_dictionary(%{}, rest))
      _ -> %{fact => update_dictionary(rest, dictionary[fact])}
    end
  end

  def update_dictionary(attributes, nil), do: create_dictionary(%{}, Enum.reverse(attributes))

  def reduce_results(dictionary, attributes) do
    dictionary
    |> Map.keys()
    |> Enum.map(&process_attribute(&1, attributes, dictionary, %{}))
    |> reduce_results()
  end

  def reduce_results([]), do: [false]

  def reduce_results(results) do
    results
    |> Enum.filter(&filter_results/1)
    |> select_results(results)
    |> extract_result()
  end

  defp filter_results(result) when is_boolean(result), do: false
  defp filter_results([result]) when is_boolean(result), do: false
  defp filter_results(_), do: true

  defp select_results([], results), do: [Enum.reduce(results, &(&1 or &2))]
  defp select_results(items, _results), do: items |> List.flatten() |> Enum.reverse()

  defp extract_result([]), do: [false]
  defp extract_result(result), do: result
end
