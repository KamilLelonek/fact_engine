defmodule Mix.Tasks.Parse do
  use Mix.Task

  alias FactEngine.FileReader

  @response_separator "---"
  @parse_options [strict: [input: :string, output: :string]]

  def run(argv) do
    argv
    |> parse_arguments()
    |> process_command()
  end

  defp parse_arguments(argv) do
    argv
    |> OptionParser.parse(@parse_options)
    |> case do
      {[input: input, output: output], _, _} -> {input, output}
      {[output: output, input: input], _, _} -> {input, output}
      _ -> :error
    end
  end

  defp process_command(:error) do
    IO.puts("usage: mix parse --input <path_to_input_file> --output <path_to_output_file>")

    exit({:shutdown, 1})
  end

  defp process_command({input, output}) do
    input
    |> FileReader.call()
    |> FactEngine.process()
    |> write_responses(output)
  end

  defp write_responses(responses, output) do
    {:ok, file} = File.open(output, [:write])

    Enum.each(responses, fn response ->
      IO.puts(file, @response_separator)
      format_response(response, file)
    end)
  end

  defp format_response(response, file)
       when is_list(response),
       do: Enum.each(response, &format_response(&1, file))

  defp format_response(response, file) when is_map(response) do
    response
    |> Map.keys()
    |> Enum.each(&IO.puts(file, [&1, ":  ", response[&1], "  "]))
  end

  defp format_response(response, file), do: IO.puts(file, inspect(response))
end
