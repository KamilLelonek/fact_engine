defmodule FactEngine.FileReaderTest do
  use ExUnit.Case, async: true

  alias FactEngine.FileReader
  alias FactEngine.Substitution
  alias FactEngine.Action

  describe "call/1" do
    test "should parse the given file" do
      assert [
               %Action{
                 arity: 1,
                 attributes: [%Substitution{symbol: "X"}],
                 fact: "is_a_cat",
                 type: "QUERY"
               },
               %Action{
                 arity: 1,
                 attributes: ["lucy"],
                 fact: "is_a_cat",
                 type: "INPUT"
               },
               %Action{
                 arity: 1,
                 attributes: ["garfield"],
                 fact: "is_a_cat",
                 type: "INPUT"
               },
               %Action{
                 arity: 2,
                 attributes: ["garfield", "lasagna"],
                 fact: "loves",
                 type: "INPUT"
               },
               %Action{
                 arity: 1,
                 attributes: ["bowler_cat"],
                 fact: "is_a_cat",
                 type: "INPUT"
               },
               %Action{
                 arity: 1,
                 attributes: [%Substitution{symbol: "X"}],
                 fact: "is_a_cat",
                 type: "QUERY"
               },
               %Action{
                 arity: 2,
                 attributes: ["garfield", %Substitution{symbol: "FavoriteFood"}],
                 fact: "loves",
                 type: "QUERY"
               }
             ] = FileReader.call("test/fixtures/in.txt")
    end
  end
end
