defmodule FactEngine.ParserTest do
  use ExUnit.Case, async: true

  alias FactEngine.Parser
  alias FactEngine.Action
  alias FactEngine.Substitution

  @input_single_attribute "INPUT is_a_cat (bowler_cat)"
  @input_multiple_attributes "INPUT are_friends (alex, sam)"
  @query_no_substitutions "QUERY is_a_cat (lucy)"
  @query_single_substitution "QUERY are_friends (X, sam)"
  @query_multiple_substitutions "QUERY are_friends (X, Y)"
  @query_complex_substitutions "QUERY loves (garfield, FavoriteFood)"

  describe "call/1" do
    test "should parse the given INPUT with a single Attribute" do
      assert %Action{
               arity: 1,
               attributes: ["bowler_cat"],
               fact: "is_a_cat",
               type: "INPUT"
             } = Parser.call(@input_single_attribute)
    end

    test "should parse the given INPUT with multiple Attributes" do
      assert %Action{
               arity: 2,
               attributes: ["alex", "sam"],
               fact: "are_friends",
               type: "INPUT"
             } = Parser.call(@input_multiple_attributes)
    end

    test "should parse the given QUERY without any Substitutions" do
      assert %Action{
               arity: 1,
               attributes: ["lucy"],
               fact: "is_a_cat",
               type: "QUERY"
             } = Parser.call(@query_no_substitutions)
    end

    test "should parse the given QUERY with a single Substitution" do
      assert %Action{
               arity: 2,
               attributes: [%Substitution{symbol: "X"}, "sam"],
               fact: "are_friends",
               type: "QUERY"
             } = Parser.call(@query_single_substitution)
    end

    test "should parse the given QUERY with multiple Substitutions" do
      assert %Action{
               arity: 2,
               attributes: [
                 %Substitution{symbol: "X"},
                 %Substitution{symbol: "Y"}
               ],
               fact: "are_friends",
               type: "QUERY"
             } = Parser.call(@query_multiple_substitutions)
    end

    test "should parse the given QUERY with a complex Substitution" do
      assert %FactEngine.Action{
               arity: 2,
               attributes: ["garfield", %FactEngine.Substitution{symbol: "FavoriteFood"}],
               fact: "loves",
               type: "QUERY"
             } = Parser.call(@query_complex_substitutions)
    end
  end
end
