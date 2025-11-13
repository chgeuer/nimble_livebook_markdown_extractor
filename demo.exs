#!/usr/bin/env elixir

# Demo script to parse the sample.md.livemd file
Mix.install([
  {:nimble_parsec, "~> 1.4"}
])

Code.require_file("lib/nimble_livebook_markdown_extractor.ex")

# Read the sample file
content = File.read!("sample.md.livemd")

IO.puts("=== Parsing sample.md.livemd ===\n")

# Extract only real code cells
case NimbleLivebookMarkdownExtractor.extract_code_cells(content) do
  {:ok, code_cells} ->
    IO.puts("Found #{length(code_cells)} real Elixir code cells:\n")

    code_cells
    |> Enum.with_index(1)
    |> Enum.each(fn {code, index} ->
      IO.puts("--- Code Cell #{index} ---")
      IO.puts(code)
      IO.puts("")
    end)

  {:error, reason} ->
    IO.puts("Error: #{reason}")
end

IO.puts("\n=== All code cells with metadata ===\n")

# Extract all code cells with metadata
case NimbleLivebookMarkdownExtractor.extract_all_code_cells(content) do
  {:ok, code_cells} ->
    code_cells
    |> Enum.with_index(1)
    |> Enum.each(fn {{code, is_markdown}, index} ->
      marker = if is_markdown, do: "[MARKDOWN EXAMPLE]", else: "[REAL CODE]"
      IO.puts("--- Cell #{index} #{marker} ---")
      IO.puts(code)
      IO.puts("")
    end)

  {:error, reason} ->
    IO.puts("Error: #{reason}")
end
