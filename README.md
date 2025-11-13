# NimbleLivebookMarkdownExtractor

A robust NimbleParsec-based parser for extracting executable Elixir code from LiveBook markdown files.

## Overview

LiveBook notebooks (`.livemd` files) are markdown documents that contain executable Elixir code cells. This library provides a reliable way to extract these code cells while intelligently filtering out markdown examples that are marked as non-executable.

**Perfect for LLM Coding Agents:** When working with AI coding assistants like GitHub Copilot, Claude Code, or Cursor, this module provides a scriptable way to extract and test Elixir code from LiveBooks. AI agents can use this to validate notebooks, debug iteratively, and automate testing workflows. See [AI_AGENT_GUIDE.md](AI_AGENT_GUIDE.md) for detailed examples.

### Key Features

- **Precise Parsing** - Uses NimbleParsec combinators for robust, declarative parsing
- **Smart Filtering** - Automatically excludes code blocks marked with `<!-- livebook:{"force_markdown":true} -->`
- **Multiple APIs** - Three extraction modes to fit different use cases
- **Thoroughly Tested** - 14 tests covering edge cases and real-world scenarios
- **AI-Agent Ready** - Scriptable extraction for automated testing and validation

## Installation

```elixir
def deps do
  [
    {:nimble_livebook_markdown_extractor, github: "chgeuer/nimble_livebook_markdown_extractor" }
  ]
end
```

## Usage

See [QUICK_START.md](QUICK_START.md) for common patterns and recipes.

### Quick Start

```elixir
# Read a LiveBook file
content = File.read!("notebook.livemd")

# Extract only executable code as a single string
code = NimbleLivebookMarkdownExtractor.extract_executable_code(content)
IO.puts(code)
```

**For AI Coding Agents - Extract and Test:**

```elixir
# Extract executable code from a LiveBook
code = File.read!("notebook.livemd")
       |> NimbleLivebookMarkdownExtractor.extract_executable_code()

# Test the extracted code
File.write!("/tmp/test.exs", code)
System.cmd("elixir", ["/tmp/test.exs"])
|> case do
  {_, 0} -> IO.puts("✅ LiveBook code is valid")
  {error, _} -> IO.puts("❌ Error: #{error}")
end
```

### Three Extraction Modes

#### 1. Single String Output (Compatible API)

Best for: Compatibility with existing parsers, getting all code at once

```elixir
content = """
```elixir
a = 1
```

<!-- livebook:{"force_markdown":true} -->

```elixir
b = 2  # This is just an example
```

```elixir
c = 3
```
"""

result = NimbleLivebookMarkdownExtractor.extract_executable_code(content)
# Returns: "a = 1\n\nc = 3"
```

#### 2. List of Code Cells

Best for: Processing each code cell individually, analyzing cell structure

```elixir
{:ok, cells} = NimbleLivebookMarkdownExtractor.extract_code_cells(content)
# Returns: {:ok, ["a = 1\n", "c = 3\n"]}

Enum.each(cells, fn cell ->
  # Process each executable cell
  analyze_dependencies(cell)
end)
```

#### 3. All Cells with Metadata

Best for: Distinguishing between real code and examples, documentation generation

```elixir
{:ok, all_cells} = NimbleLivebookMarkdownExtractor.extract_all_code_cells(content)
# Returns: {:ok, [{"a = 1\n", false}, {"b = 2  # This is just an example\n", true}, {"c = 3\n", false}]}

Enum.each(all_cells, fn {code, is_markdown_example} ->
  if is_markdown_example do
    IO.puts("📝 Example: #{code}")
  else
    IO.puts("▶️ Executable: #{code}")
  end
end)
```

## How It Works

The parser uses NimbleParsec to:

1. **Scan the document** character by character
2. **Detect markers** - Finds `<!-- livebook:{"force_markdown":true} -->` comments
3. **Parse code fences** - Identifies Elixir code blocks (` ```elixir ... ``` `)
4. **Associate markers** - Links force_markdown markers to their following code block
5. **Filter intelligently** - Returns only executable code or all code with metadata

### What Gets Filtered

Code blocks preceded by this marker are considered non-executable examples:

```markdown
<!-- livebook:{"force_markdown":true} -->

```elixir
# This code won't be extracted by extract_code_cells()
example_function()
```
```

## Examples

### Real-World LiveBook

Given this LiveBook content:

```markdown
# My Data Pipeline

## Setup

```elixir
Mix.install([
  {:req, "~> 0.5"},
  {:jason, "~> 1.4"}
])
```

## Implementation

```elixir
defmodule Pipeline do
  def fetch_data(url) do
    Req.get!(url).body
  end
end
```

Here's how to use it:

<!-- livebook:{"force_markdown":true} -->

```elixir
Pipeline.fetch_data("https://example.com/api/data")
```

## Actual Usage

```elixir
data = Pipeline.fetch_data("https://api.github.com")
IO.inspect(data)
```
```

The parser extracts:

```elixir
# Using extract_code_cells/1
{:ok, [
  "Mix.install([\n  {:req, \"~> 0.5\"},\n  {:jason, \"~> 1.4\"}\n])\n",
  "defmodule Pipeline do\n  def fetch_data(url) do\n    Req.get!(url).body\n  end\nend\n",
  "data = Pipeline.fetch_data(\"https://api.github.com\")\nIO.inspect(data)\n"
]}

# Using extract_executable_code/1
"Mix.install([\n  {:req, \"~> 0.5\"},\n  {:jason, \"~> 1.4\"}\n])\n\ndefmodule Pipeline do\n  def fetch_data(url) do\n    Req.get!(url).body\n  end\nend\n\ndata = Pipeline.fetch_data(\"https://api.github.com\")\nIO.inspect(data)"
```

Notice that the example usage with `Pipeline.fetch_data("https://example.com/api/data")` is **not** extracted because it's marked as `force_markdown`.

## Use Cases

### LLM Coding Agents (Primary Use Case)

When working with Large Language Model coding agents like **GitHub Copilot**, **Claude Code**, or **Cursor**, you often need to test code within LiveBook notebooks. This module provides a scriptable way for AI coding agents to extract and execute the actual Elixir source code from a LiveBook for testing purposes.

**Example workflow with an LLM coding agent:**

```elixir
# AI agent can extract code from a LiveBook for testing
livebook_content = File.read!("my_notebook.livemd")

# Extract only the executable code
code = NimbleLivebookMarkdownExtractor.extract_executable_code(livebook_content)

# Create a temporary test file
File.write!("/tmp/extracted_code.exs", code)

# Run the extracted code for testing
{output, exit_code} = System.cmd("elixir", ["/tmp/extracted_code.exs"])

# AI agent can analyze the results
if exit_code == 0 do
  IO.puts("✅ LiveBook code executes successfully")
else
  IO.puts("❌ Error in LiveBook code:\n#{output}")
end
```

This enables AI coding agents to:
- **Validate LiveBooks** - Test that notebook code actually runs
- **Debug iteratively** - Extract, run, analyze errors, and fix
- **Automate testing** - Integrate LiveBook validation in CI/CD pipelines
- **Generate reports** - Analyze code quality and dependencies from notebooks

### Other Use Cases

- **Code Analysis** - Extract code for dependency analysis, security scanning, or metrics
- **Documentation** - Generate documentation from LiveBook examples while excluding non-executable samples
- **Education** - Analyze student LiveBook submissions programmatically
- **Migration** - Convert LiveBooks to other formats (`.ex`, `.exs`, or other notebook formats)
- **CI/CD Integration** - Validate that LiveBook code cells are syntactically correct and executable

## Running the Demo

Try the included demonstration:

```bash
elixir demo.exs
```

This parses `sample.md.livemd` and shows:
- All real code cells (filtered)
- All cells with metadata (including examples)

## Testing

Run the comprehensive test suite:

```bash
mix test
```

**Test Coverage:**
- ✅ Real LiveBook files (sample.md.livemd)
- ✅ Simple single-cell extraction
- ✅ Multiple force_markdown blocks
- ✅ Complex multi-line code with modules
- ✅ Empty documents
- ✅ Preserving blank lines within cells
- ✅ All three extraction APIs

## API Reference

### `extract_executable_code/1`

```elixir
@spec extract_executable_code(String.t()) :: String.t()
```

Extracts all executable code as a single string with cells joined by blank lines. Returns empty string on error.

### `extract_code_cells/1`

```elixir
@spec extract_code_cells(String.t()) :: {:ok, [String.t()]} | {:error, String.t()}
```

Extracts executable code cells as a list. Each cell preserves its internal structure including blank lines.

### `extract_all_code_cells/1`

```elixir
@spec extract_all_code_cells(String.t()) :: {:ok, [{String.t(), boolean()}]} | {:error, String.t()}
```

Extracts all code cells with metadata. Returns tuples of `{code, is_force_markdown}`.

## Implementation Details

### Parser Architecture

Built with NimbleParsec combinators:
- `force_markdown_marker` - Matches the special comment
- `code_fence_open` - Matches ` ```elixir `
- `code_fence_close` - Matches ` ``` `
- `code_content` - Captures code between fences
- `code_block` - Complete block with optional marker
- `non_code_content` - Advances through other content

### Edge Cases Handled

- Blank lines within code cells (preserved)
- Multiple consecutive code blocks
- Multiple force_markdown markers
- Empty code cells
- Code blocks with no content
- Documents with no code blocks
- Nested or malformed markdown

