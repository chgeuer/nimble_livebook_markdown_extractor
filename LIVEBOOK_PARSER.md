# LiveBook Parser

A NimbleParsec-based parser for LiveBook markdown files that can extract real Elixir code cells while filtering out markdown example code cells.

## Overview

LiveBook files (`.livemd`) are markdown files that contain executable Elixir code cells. Sometimes, these files also include example code blocks that should not be executed. These are marked with a special comment:

```markdown
<!-- livebook:{"force_markdown":true} -->
```

This parser can distinguish between real code cells and markdown examples, extracting only the executable code.

## Features

- **Reliable parsing** using NimbleParsec for robust markdown processing
- **Smart filtering** of code cells marked with `force_markdown:true`
- **Three extraction modes**:
  - `extract_code_cells/1` - Returns a list of real, executable code cells
  - `extract_all_code_cells/1` - Returns all code cells with metadata indicating which are markdown examples
  - `extract_executable_code/1` - Returns a single joined string (compatible with the original regex-based parser)

## Installation

Add `nimble_parsec` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:nimble_parsec, "~> 1.4"}
  ]
end
```

## Usage

### Extract as Single String (Compatible API)

For compatibility with the original regex-based parser:

```elixir
content = File.read!("notebook.livemd")

result = LivebookParser.extract_executable_code(content)

# Returns a single string with code cells joined by blank lines
IO.puts(result)
```

### Extract Only Real Code Cells

```elixir
content = File.read!("notebook.livemd")

{:ok, code_cells} = LivebookParser.extract_code_cells(content)

# Returns a list of code strings, excluding force_markdown cells
Enum.each(code_cells, fn code ->
  IO.puts("Code cell:")
  IO.puts(code)
end)
```

### Extract All Code Cells with Metadata

```elixir
content = File.read!("notebook.livemd")

{:ok, code_cells} = LivebookParser.extract_all_code_cells(content)

# Returns a list of {code, is_markdown_example} tuples
Enum.each(code_cells, fn {code, is_markdown} ->
  type = if is_markdown, do: "Example", else: "Real"
  IO.puts("#{type} code cell:")
  IO.puts(code)
end)
```

## Example

Given this LiveBook content:

```markdown
# My Notebook

```elixir
a = 1
```

This is just an example:

<!-- livebook:{"force_markdown":true} -->

```elixir
b = 2  # This won't be extracted
```

Real code:

```elixir
c = 3
```
```

The parser will extract:

```elixir
{:ok, ["a = 1\n", "c = 3\n"]}
```

## Running the Demo

Try the included demo script:

```bash
elixir demo.exs
```

This will parse the `sample.md.livemd` file and show both extraction modes in action.

## Running Tests

```bash
mix test
```

## How It Works

The parser uses NimbleParsec combinators to:

1. Scan through the markdown document character by character
2. Detect `<!-- livebook:{"force_markdown":true} -->` markers
3. Parse Elixir code fence blocks (` ```elixir ... ``` `)
4. Associate markers with their following code blocks
5. Filter out code blocks that have the force_markdown marker

The parser handles:
- Multiple code blocks in sequence
- Mixed real code and example code
- Complex multi-line code cells
- Edge cases like empty documents or no code blocks

## License

Same as the parent project.
