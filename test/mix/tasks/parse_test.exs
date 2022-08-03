defmodule Mix.Tasks.ParseTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias Mix.Tasks.Parse

  @output_file "out.txt"

  setup do
    on_exit(fn -> File.rm(@output_file) end)

    :ok
  end

  describe "run/1" do
    test "should not parse an invalid input and print usage" do
      assert capture_io(fn ->
               assert {:shutdown, 1} = catch_exit(Parse.run([]))
             end) =~
               "usage: mix parse --input <path_to_input_file> --output <path_to_output_file>"
    end

    test "should parse the given input" do
      Parse.run(["--input", "test/fixtures/in.txt", "--output", "out.txt"])

      assert File.read!(@output_file) =~
               "---\nfalse\n---\nX:  lucy  \n---\nX:  garfield  \n---\nX:  bowler_cat  \n---\nFavoriteFood:  lasagna  \n"
    end
  end
end
