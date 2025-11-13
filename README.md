# NimbleLivebookMarkdownExtractor

A robust NimbleParsec-based parser for extracting executable Elixir code from LiveBook markdown files.

## Overview

LiveBook notebooks (`.livemd` files) are markdown documents that contain executable Elixir code cells. This library provides a reliable way to extract these code cells while intelligently filtering out markdown examples that are marked as non-executable.

### Key Features

- **Precise Parsing** - Uses NimbleParsec combinators for robust, declarative parsing
- **Smart Filtering** - Automatically excludes code blocks marked with `<!-- livebook:{"force_markdown":true} -->`

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

