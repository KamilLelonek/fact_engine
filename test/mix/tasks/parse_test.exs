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
      for directory <- 3..4 do
        Parse.run(["--input", "test/fixtures/#{directory}/in.txt", "--output", @output_file])

        assert File.read!(@output_file) =~ File.read!("test/fixtures/#{directory}/out.txt")
      end
    end
  end
end
