# AI Agent Guide: Using NimbleLivebookMarkdownExtractor

## For GitHub Copilot, Claude Code, Cursor, and other AI Coding Assistants

This guide shows how AI coding agents can use `NimbleLivebookMarkdownExtractor` to extract and test Elixir code from LiveBook notebooks.

## Problem Statement

LiveBook notebooks mix executable code with documentation examples. When an AI agent needs to test or validate LiveBook code, it must:
1. Extract only the executable code cells
2. Filter out markdown examples (marked with `force_markdown`)
3. Run the code to verify it works
4. Analyze results and report issues

## Solution: NimbleLivebookMarkdownExtractor

This module provides a scriptable, reliable way to extract executable Elixir code from LiveBooks.

## Quick Examples for AI Agents

### 1. Basic Extraction and Test

```elixir
# Read LiveBook
content = File.read!("notebook.livemd")

# Extract executable code
code = NimbleLivebookMarkdownExtractor.extract_executable_code(content)

# Test by writing to temp file and executing
File.write!("/tmp/test_notebook.exs", code)
{output, exit_code} = System.cmd("elixir", ["/tmp/test_notebook.exs"])

case exit_code do
  0 -> {:ok, "LiveBook code executes successfully", output}
  _ -> {:error, "Execution failed", output}
end
```

### 2. Syntax Validation Only

```elixir
# Extract and check syntax without executing
content
|> File.read!()
|> NimbleLivebookMarkdownExtractor.extract_executable_code()
|> Code.string_to_quoted()
|> case do
  {:ok, _ast} -> 
    {:ok, "Valid Elixir syntax"}
  {:error, {line, error, token}} ->
    {:error, "Syntax error at line #{line}: #{error} #{token}"}
end
```

### 3. Process Individual Cells

```elixir
# Extract cells separately for granular testing
{:ok, cells} = NimbleLivebookMarkdownExtractor.extract_code_cells(content)

results = Enum.with_index(cells, 1)
|> Enum.map(fn {cell, index} ->
  case Code.string_to_quoted(cell) do
    {:ok, _} -> {:ok, index, "Cell #{index} valid"}
    {:error, reason} -> {:error, index, "Cell #{index} invalid: #{inspect(reason)}"}
  end
end)

# Report which cells have issues
Enum.filter(results, &match?({:error, _, _}, &1))
```

### 4. Full Validation Pipeline

```elixir
defmodule AIAgentValidator do
  @moduledoc """
  LiveBook validation helpers for AI coding agents.
  """
  
  def validate_livebook(path) do
    with {:ok, content} <- File.read(path),
         code <- NimbleLivebookMarkdownExtractor.extract_executable_code(content),
         {:ok, _ast} <- Code.string_to_quoted(code),
         {:ok, result} <- execute_code(code) do
      {:ok, "✅ #{path} is valid and executable", result}
    else
      {:error, reason} -> {:error, "❌ #{path} failed: #{inspect(reason)}"}
    end
  end
  
  defp execute_code(code) do
    temp_file = "/tmp/livebook_test_#{:rand.uniform(999999)}.exs"
    File.write!(temp_file, code)
    
    {output, exit_code} = System.cmd("elixir", [temp_file])
    File.rm(temp_file)
    
    case exit_code do
      0 -> {:ok, output}
      _ -> {:error, output}
    end
  end
end

# Usage by AI agent
Path.wildcard("**/*.livemd")
|> Enum.each(fn path ->
  case AIAgentValidator.validate_livebook(path) do
    {:ok, message, _output} -> IO.puts(message)
    {:error, message} -> IO.puts(message)
  end
end)
```

### 5. CI/CD Integration

```elixir
# Script for AI agents to run in CI/CD pipelines
defmodule LiveBookCI do
  def validate_all do
    notebooks = Path.wildcard("notebooks/**/*.livemd")
    
    results = Enum.map(notebooks, fn path ->
      content = File.read!(path)
      code = NimbleLivebookMarkdownExtractor.extract_executable_code(content)
      
      case Code.string_to_quoted(code) do
        {:ok, _} -> {:ok, path}
        {:error, reason} -> {:error, path, reason}
      end
    end)
    
    failures = Enum.filter(results, &match?({:error, _, _}, &1))
    
    if Enum.empty?(failures) do
      IO.puts("✅ All #{length(notebooks)} LiveBooks are valid")
      System.halt(0)
    else
      IO.puts("❌ #{length(failures)} LiveBooks have issues:")
      Enum.each(failures, fn {:error, path, reason} ->
        IO.puts("  - #{path}: #{inspect(reason)}")
      end)
      System.halt(1)
    end
  end
end

LiveBookCI.validate_all()
```

## Common AI Agent Workflows

### Workflow 1: Test Before Committing

```elixir
# AI agent checks LiveBook before commit
livebook_path = System.get_env("LIVEBOOK_PATH") || "notebook.livemd"

result = livebook_path
|> File.read!()
|> NimbleLivebookMarkdownExtractor.extract_executable_code()
|> then(fn code ->
  File.write!("/tmp/test.exs", code)
  System.cmd("elixir", ["/tmp/test.exs"])
end)

case result do
  {_, 0} -> 
    IO.puts("✅ LiveBook is ready to commit")
    System.halt(0)
  {error, _} -> 
    IO.puts("❌ LiveBook has issues:\n#{error}")
    System.halt(1)
end
```

### Workflow 2: Iterative Debugging

```elixir
# AI agent extracts, tests, analyzes errors
defmodule DebugHelper do
  def debug_livebook(path) do
    content = File.read!(path)
    {:ok, cells} = NimbleLivebookMarkdownExtractor.extract_code_cells(content)
    
    # Test each cell
    cells
    |> Enum.with_index(1)
    |> Enum.reduce_while(:ok, fn {cell, index}, _acc ->
      case Code.string_to_quoted(cell) do
        {:ok, _} -> 
          IO.puts("✅ Cell #{index} OK")
          {:cont, :ok}
        {:error, {line, error, token}} ->
          IO.puts("❌ Cell #{index} failed at line #{line}")
          IO.puts("Error: #{error} #{token}")
          IO.puts("Cell content:")
          IO.puts(cell)
          {:halt, {:error, index}}
      end
    end)
  end
end

# AI agent uses this to find which cell has the issue
DebugHelper.debug_livebook("notebook.livemd")
```

### Workflow 3: Extract Dependencies

```elixir
# AI agent finds what dependencies are needed
content
|> File.read!()
|> NimbleLivebookMarkdownExtractor.extract_executable_code()
|> then(fn code ->
  case Regex.run(~r/Mix\.install\(\[(.*?)\]/s, code) do
    [_, deps_str] -> 
      IO.puts("Dependencies found:")
      IO.puts(deps_str)
    nil -> 
      IO.puts("No Mix.install found")
  end
end)
```

## API Quick Reference

```elixir
# Get all code as single string (compatible API)
code = NimbleLivebookMarkdownExtractor.extract_executable_code(content)

# Get cells as list for individual processing
{:ok, cells} = NimbleLivebookMarkdownExtractor.extract_code_cells(content)

# Get all cells with metadata (including examples)
{:ok, cells_with_meta} = NimbleLivebookMarkdownExtractor.extract_all_code_cells(content)
# Returns: [{code, is_force_markdown}, ...]
```

## Best Practices for AI Agents

1. **Always validate syntax** before executing code
2. **Use temporary files** for execution, then clean up
3. **Process cells individually** for better error reporting
4. **Filter out force_markdown** cells (automatically done by `extract_code_cells`)
5. **Capture both stdout and stderr** when executing
6. **Set timeouts** for execution to prevent hanging
7. **Log results** for debugging and reporting

## Error Handling

```elixir
# Robust error handling example
def safe_extract_and_test(path) do
  with {:ok, content} <- File.read(path),
       code <- NimbleLivebookMarkdownExtractor.extract_executable_code(content),
       false <- String.trim(code) == "" do
    # Code extracted successfully
    {:ok, code}
  else
    {:error, reason} -> {:error, "Failed to read file: #{reason}"}
    true -> {:error, "No executable code found in LiveBook"}
  end
end
```

## Summary for AI Agents

✅ Use `extract_executable_code/1` for simple extraction  
✅ Use `extract_code_cells/1` for cell-by-cell testing  
✅ Use `extract_all_code_cells/1` to see all cells including examples  
✅ Always test in a temporary file before committing  
✅ Validate syntax with `Code.string_to_quoted/1` before executing  
✅ Perfect for CI/CD, pre-commit hooks, and automated testing  

---

**Ready to use in your AI agent workflows!**
