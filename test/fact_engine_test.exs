defmodule FactEngineTest do
  use ExUnit.Case, async: true

  alias FactEngine.Action
  alias FactEngine.Substitution

  describe "eval_input/1" do
    test "should evaluate an input with an empty initial state" do
      assert %{"is_a_cat" => %{1 => %{"bob" => true}}} =
               FactEngine.eval_input("is_a_cat", 1, ["bob"], %{})
    end

    test "should evaluate an input with an initial state" do
      result = FactEngine.eval_input("is_a_cat", 1, ["kcf"], %{})

      assert %{"is_a_cat" => %{1 => %{"kcf" => true, "fatty" => true}}} =
               FactEngine.eval_input("is_a_cat", 1, ["fatty"], result)
    end

    test "should evaluate an input with multiple intial facts" do
      result1 = FactEngine.eval_input("is_a_cat", 1, ["kcf"], %{})
      result2 = FactEngine.eval_input("is_a_dog", 1, ["lia"], result1)

      assert %{
               "is_a_cat" => %{1 => %{"kcf" => true, "chester" => true}},
               "is_a_dog" => %{1 => %{"lia" => true}}
             } = FactEngine.eval_input("is_a_cat", 1, ["chester"], result2)
    end

    test "should evaluate an input with different arities" do
      result = FactEngine.eval_input("is_a_cat", 1, ["johnny"], %{})

      assert %{
               "is_a_cat" => %{1 => %{"johnny" => true}},
               "are_friends" => %{2 => %{"sam" => %{"peter" => true}}}
             } = FactEngine.eval_input("are_friends", 2, ["sam", "peter"], result)
    end
  end

  describe "eval_query/1" do
    test "should query 1 existing 1-arity fact" do
      assert [true] =
               FactEngine.eval_query("is_a_dog", 1, ["lia"], %{
                 "is_a_dog" => %{1 => %{"lia" => true}}
               })
    end

    test "should query 2 different symbols" do
      facts = %{
        "are_friends" => %{
          2 => %{"peter" => %{"john" => true, "frank" => true}, "willy" => %{"frank" => true}}
        }
      }

      assert [
               %{"X" => "willy", "Y" => "frank"},
               %{"X" => "peter", "Y" => "john"},
               %{"X" => "peter", "Y" => "frank"}
             ] =
               FactEngine.eval_query(
                 "are_friends",
                 2,
                 [%Substitution{symbol: "X"}, %Substitution{symbol: "Y"}],
                 facts
               )
    end

    test "should not query a notexisting symbol" do
      assert [false] = FactEngine.eval_query("is_a_cat", 1, [%Substitution{symbol: "X"}], %{})
    end

    test "should query 2 identical symbols and one different with no matches" do
      facts = %{
        "triple" => %{
          3 => %{4 => %{5 => true}},
          5 => %{12 => %{13 => true}}
        }
      }

      assert [false] =
               FactEngine.eval_query(
                 "triple",
                 3,
                 [
                   %Substitution{symbol: "X"},
                   %Substitution{symbol: "X"},
                   %Substitution{symbol: "Y"}
                 ],
                 facts
               )
    end
  end

  describe "process/1" do
    test "should process a single existing fact" do
      action1 = %Action{type: "INPUT", fact: "is_a_cat", arity: 1, attributes: ["peter"]}
      action2 = %Action{type: "QUERY", fact: "is_a_cat", arity: 1, attributes: ["peter"]}

      assert [true] = FactEngine.process([action1, action2])
    end

    test "should not process a fact with a non-matching attribute" do
      action1 = %Action{type: "INPUT", fact: "is_a_cat", arity: 1, attributes: ["peter"]}
      action2 = %Action{type: "QUERY", fact: "is_a_cat", arity: 1, attributes: ["john"]}

      assert [false] = FactEngine.process([action1, action2])
    end

    test "should process multiple queries" do
      action1 = %Action{
        type: "INPUT",
        fact: "are_friends",
        arity: 2,
        attributes: ["peter", "john"]
      }

      action2 = %Action{
        type: "QUERY",
        fact: "are_friends",
        arity: 2,
        attributes: ["peter", "john"]
      }

      action3 = %Action{
        type: "QUERY",
        fact: "are_friends",
        arity: 2,
        attributes: ["mike", "tim"]
      }

      action4 = %Action{
        type: "QUERY",
        fact: "are_friends",
        arity: 2,
        attributes: ["john", "peter"]
      }

      assert [true, false, false] = FactEngine.process([action1, action2, action3, action4])
    end

    test "should process queries with a single substitution" do
      action1 = %Action{type: "INPUT", fact: "is_a_cat", arity: 1, attributes: ["kcf"]}
      action2 = %Action{type: "INPUT", fact: "is_a_dog", arity: 1, attributes: ["lia"]}

      action3 = %Action{
        type: "INPUT",
        fact: "is_a_cat",
        arity: 1,
        attributes: ["chester"]
      }

      action4 = %Action{
        type: "QUERY",
        fact: "is_a_cat",
        arity: 1,
        attributes: [%Substitution{symbol: "X"}]
      }

      assert [%{"X" => "kcf"}, %{"X" => "chester"}] =
               FactEngine.process([action1, action2, action3, action4])
    end

    test "should process queries with multiple substitutions" do
      action1 = %Action{
        type: "INPUT",
        fact: "are_friends",
        arity: 2,
        attributes: ["peter", "john"]
      }

      action2 = %Action{
        type: "INPUT",
        fact: "are_friends",
        arity: 2,
        attributes: ["peter", "frank"]
      }

      action3 = %Action{
        type: "INPUT",
        fact: "are_friends",
        arity: 2,
        attributes: ["willy", "john"]
      }

      action4 = %Action{
        type: "QUERY",
        fact: "are_friends",
        arity: 2,
        attributes: [%Substitution{symbol: "X"}, %Substitution{symbol: "Y"}]
      }

      assert [
               %{"X" => "willy", "Y" => "john"},
               %{"X" => "peter", "Y" => "john"},
               %{"X" => "peter", "Y" => "frank"}
             ] = FactEngine.process([action1, action2, action3, action4])
    end
  end

  describe "reduce_result/4" do
    test "should process a simple fact" do
      facts = %{"lia" => true}

      assert [true] =
               facts
               |> Map.keys()
               |> Enum.map(&FactEngine.process_attribute(&1, ["lia"], facts, %{}))
               |> FactEngine.reduce_results()
    end

    test "should process nested facts with multiple substitutions" do
      facts = %{
        "lia" => %{"sam" => true, "frank" => true},
        "coo" => %{"lia" => true},
        "bill" => %{"sam" => true, "john" => true}
      }

      assert [
               %{"X" => "lia", "Y" => "sam"},
               %{"X" => "lia", "Y" => "frank"},
               %{"X" => "coo", "Y" => "lia"},
               %{"X" => "bill", "Y" => "sam"},
               %{"X" => "bill", "Y" => "john"}
             ] =
               facts
               |> Map.keys()
               |> Enum.map(
                 &FactEngine.process_attribute(
                   &1,
                   [%Substitution{symbol: "X"}, %Substitution{symbol: "Y"}],
                   facts,
                   %{}
                 )
               )
               |> List.flatten()
               |> FactEngine.reduce_results()
    end

    test "should process nested facts with a single substitution" do
      facts = %{
        "lia" => %{"sam" => true, "frank" => true, "lia" => true},
        "coo" => %{"lia" => true},
        "bill" => %{"sam" => true, "john" => true}
      }

      assert [%{"X" => "lia"}, %{"X" => "bill"}] =
               facts
               |> Map.keys()
               |> Enum.map(
                 &FactEngine.process_attribute(
                   &1,
                   [%Substitution{symbol: "X"}, "sam"],
                   facts,
                   %{}
                 )
               )
               |> List.flatten()
               |> FactEngine.reduce_results()
    end

    test "should process attributes and substitutions" do
      facts = %{
        "3" => %{"4" => %{"5" => true}, "10" => %{"6" => true}},
        "5" => %{"12" => %{"13" => true}}
      }

      assert [%{"X" => "3", "Y" => "5"}] =
               facts
               |> Map.keys()
               |> Enum.map(
                 &FactEngine.process_attribute(
                   &1,
                   [%Substitution{symbol: "X"}, "4", %Substitution{symbol: "Y"}],
                   facts,
                   %{}
                 )
               )
               |> List.flatten()
               |> FactEngine.reduce_results()
    end

    test "should process complex facts" do
      facts = %{
        "lia" => %{"sam" => true, "frank" => true, "lia" => true},
        "coo" => %{"lia" => true},
        "bill" => %{"sam" => true, "john" => true}
      }

      assert [true] =
               facts
               |> Map.keys()
               |> Enum.map(&FactEngine.process_attribute(&1, ["coo", "lia"], facts, %{}))
               |> List.flatten()
               |> FactEngine.reduce_results()
    end

    test "should not process a notexisting attributes" do
      facts = %{
        "lia" => %{"sam" => true, "frank" => true, "lia" => true},
        "coo" => %{"lia" => true},
        "bill" => %{"sam" => true, "john" => true}
      }

      assert [false] =
               facts
               |> Map.keys()
               |> Enum.map(&FactEngine.process_attribute(&1, ["lia", "bill"], facts, %{}))
               |> List.flatten()
               |> FactEngine.reduce_results()
    end

    test "should process identical substitutions" do
      facts = %{
        "lia" => %{"sam" => true, "frank" => true, "lia" => true},
        "coo" => %{"lia" => true},
        "bill" => %{"sam" => true, "john" => true}
      }

      assert [%{"X" => "lia"}] =
               facts
               |> Map.keys()
               |> Enum.map(
                 &FactEngine.process_attribute(
                   &1,
                   [%Substitution{symbol: "X"}, %Substitution{symbol: "X"}],
                   facts,
                   %{}
                 )
               )
               |> List.flatten()
               |> FactEngine.reduce_results()
    end
  end

  describe "update_dictionary/2" do
    test "should update complex dictionary" do
      assert %{"lia" => %{"sam" => %{"walter" => true, "john" => true}}} =
               FactEngine.update_dictionary(
                 ["lia", "sam", "john"],
                 %{
                   "lia" => %{"sam" => %{"walter" => true}}
                 }
               )
    end

    test "should update nested dictionary" do
      result = FactEngine.update_dictionary(["peter", "frank"], %{"peter" => %{"john" => true}})

      assert %{"peter" => %{"john" => true, "frank" => true}} = result

      assert %{"peter" => %{"john" => true, "frank" => true}, "willy" => %{"frank" => true}} =
               FactEngine.update_dictionary(["willy", "frank"], result)
    end
  end

  describe "reduce_result/1" do
    test "should reduce boolean results to true" do
      assert [true] = FactEngine.reduce_results([true, false])
    end

    test "should reduce boolean results to false" do
      assert [false] = FactEngine.reduce_results([false, false, false])
    end

    test "should reduce a single result" do
      assert [true] = FactEngine.reduce_results([true])
    end

    test "should reduce map results" do
      assert [%{c: "d"}, %{a: "b"}] =
               FactEngine.reduce_results([true, %{a: "b"}, %{c: "d"}, false])
    end

    test "should not reduce empty results" do
      assert [false] = FactEngine.reduce_results([])
    end
  end
end
