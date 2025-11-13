# Quick Start Guide

## 1. Extract All Executable Code (String)

```elixir
content = File.read!("notebook.livemd")
code = NimbleLivebookMarkdownExtractor.extract_executable_code(content)

# Use the code
Code.eval_string(code)
```

## 2. Process Individual Cells

```elixir
{:ok, cells} = NimbleLivebookMarkdownExtractor.extract_code_cells(content)

Enum.each(cells, fn cell ->
  # Analyze each cell
  case Code.string_to_quoted(cell) do
    {:ok, ast} -> analyze_ast(ast)
    {:error, _} -> IO.puts("Syntax error in cell")
  end
end)
```

## 3. Distinguish Real Code from Examples

```elixir
{:ok, all_cells} = NimbleLivebookMarkdownExtractor.extract_all_code_cells(content)

{real_code, examples} = 
  Enum.split_with(all_cells, fn {_code, is_example} -> !is_example end)

IO.puts("Found #{length(real_code)} executable cells")
IO.puts("Found #{length(examples)} documentation examples")
```

## 4. Build Code Analysis Pipeline

```elixir
content
|> NimbleLivebookMarkdownExtractor.extract_code_cells()
|> case do
  {:ok, cells} ->
    cells
    |> Enum.map(&analyze_dependencies/1)
    |> Enum.reduce(%{}, &Map.merge/2)
  
  {:error, reason} ->
    IO.puts("Parse error: #{reason}")
    %{}
end
```

## Common Patterns

### Extract and Execute

```elixir
content
|> NimbleLivebookMarkdownExtractor.extract_executable_code()
|> Code.eval_string()
```

### Find All Module Definitions

```elixir
{:ok, cells} = NimbleLivebookMarkdownExtractor.extract_code_cells(content)

modules = 
  cells
  |> Enum.flat_map(fn cell ->
    cell
    |> Code.string_to_quoted()
    |> case do
      {:ok, {:defmodule, _, [{:__aliases__, _, parts} | _]}} ->
        [Enum.join(parts, ".")]
      _ ->
        []
    end
  end)

IO.inspect(modules, label: "Defined modules")
```

### Count Lines of Code

```elixir
{:ok, cells} = NimbleLivebookMarkdownExtractor.extract_code_cells(content)

total_lines = 
  cells
  |> Enum.map(&String.split(&1, "\n"))
  |> Enum.map(&length/1)
  |> Enum.sum()

IO.puts("Total lines of executable code: #{total_lines}")
```

### Extract Dependencies

```elixir
content
|> NimbleLivebookMarkdownExtractor.extract_executable_code()
|> then(fn code ->
  ~r/Mix\.install\(\[(.*?)\]/s
  |> Regex.run(code)
  |> case do
    [_, deps] -> deps
    nil -> "No dependencies found"
  end
end)
|> IO.puts()
```
