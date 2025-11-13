defmodule NimbleLivebookMarkdownExtractor do
  @moduledoc """
  A NimbleParsec-based parser to extract Elixir code from LiveBook markdown files.

  This parser can extract real Elixir code cells from LiveBook files while
  filtering out markdown example code cells marked with `force_markdown`.
  """

  import NimbleParsec

  # Whitespace and newline
  newline = ascii_char([?\n])

  # Optional whitespace and newline
  optional_whitespace = ascii_string([?\s, ?\t, ?\n], min: 0)

  # Parse the force_markdown marker comment
  force_markdown_marker =
    ignore(string("<!--"))
    |> ignore(optional_whitespace)
    |> ignore(string("livebook:"))
    |> ignore(optional_whitespace)
    |> ignore(string("{\"force_markdown\":true}"))
    |> ignore(optional_whitespace)
    |> ignore(string("-->"))
    |> ignore(optional_whitespace)
    |> replace(:force_markdown)

  # Parse code fence opening
  code_fence_open =
    string("```elixir")
    |> ignore(optional(ascii_string([not: ?\n], min: 0)))
    |> ignore(newline)

  # Parse code fence closing
  code_fence_close =
    string("```")

  # Parse any content until we hit the closing fence
  # We need to be careful not to consume the closing fence
  code_content =
    repeat(
      lookahead_not(code_fence_close)
      |> choice([
        newline |> replace("\n"),
        utf8_string([], 1)
      ])
    )
    |> reduce({List, :to_string, []})

  # Parse a complete code block with optional force_markdown marker
  code_block =
    optional(force_markdown_marker |> tag(:marker))
    |> ignore(optional_whitespace)
    |> ignore(code_fence_open)
    |> concat(code_content |> unwrap_and_tag(:code))
    |> ignore(code_fence_close)
    |> tag(:code_block)

  # Parse any non-code-block content (to advance through the document)
  # Must consume at least one character to avoid infinite loops
  non_code_content =
    lookahead_not(choice([
      force_markdown_marker,
      code_fence_open
    ]))
    |> utf8_char([])
    |> ignore()

  # Main parser: parse through the entire document
  defparsec(
    :parse_document,
    repeat(
      choice([
        code_block,
        non_code_content
      ])
    )
    |> eos()
  )

  @doc """
  Extracts all real Elixir code cells from a LiveBook markdown file.

  Returns a list of code cell contents, excluding cells marked with
  `force_markdown:true`.

  ## Examples

      iex> content = \"\"\"
      ...> ```elixir
      ...> a = 1
      ...> ```
      ...>
      ...> <!-- livebook:{"force_markdown":true} -->
      ...>
      ...> ```elixir
      ...> b = 2
      ...> ```
      ...> \"\"\"
      iex> NimbleLivebookMarkdownExtractor.extract_code_cells(content)
      {:ok, ["a = 1\\n"]}
  """
  def extract_code_cells(input) when is_binary(input) do
    case parse_document(input) do
      {:ok, parsed, "", _, _, _} ->
        code_cells =
          parsed
          |> Enum.filter(&match?({:code_block, _}, &1))
          |> Enum.reject(&has_force_markdown?/1)
          |> Enum.map(&extract_code/1)

        {:ok, code_cells}

      {:ok, _, rest, _, _, _} ->
        {:error, "Parsing incomplete, remaining: #{inspect(rest)}"}

      {:error, reason, _rest, _, _, _} ->
        {:error, reason}
    end
  end

  # Check if a code block has the force_markdown marker
  defp has_force_markdown?({:code_block, elements}) do
    Enum.any?(elements, fn
      {:marker, [:force_markdown]} -> true
      _ -> false
    end)
  end

  # Extract the code content from a code block
  defp extract_code({:code_block, elements}) do
    elements
    |> Enum.find_value(fn
      {:code, code} -> code
      _ -> nil
    end)
  end

  @doc """
  Extracts all code cells with metadata indicating whether they are marked as force_markdown.

  Returns a list of tuples `{code_content, is_force_markdown}`.

  ## Examples

      iex> content = \"\"\"
      ...> ```elixir
      ...> a = 1
      ...> ```
      ...>
      ...> <!-- livebook:{"force_markdown":true} -->
      ...>
      ...> ```elixir
      ...> b = 2
      ...> ```
      ...> \"\"\"
      iex> NimbleLivebookMarkdownExtractor.extract_all_code_cells(content)
      {:ok, [{"a = 1\\n", false}, {"b = 2\\n", true}]}
  """
  def extract_all_code_cells(input) when is_binary(input) do
    case parse_document(input) do
      {:ok, parsed, "", _, _, _} ->
        code_cells =
          parsed
          |> Enum.filter(&match?({:code_block, _}, &1))
          |> Enum.map(fn block ->
            {extract_code(block), has_force_markdown?(block)}
          end)

        {:ok, code_cells}

      {:ok, _, rest, _, _, _} ->
        {:error, "Parsing incomplete, remaining: #{inspect(rest)}"}

      {:error, reason, _rest, _, _, _} ->
        {:error, reason}
    end
  end

  @doc """
  Extracts executable code from a LiveBook file as a single string.

  This function provides API compatibility with the original regex-based parser.
  It joins all real code cells with blank lines between them.

  ## Examples

      iex> content = \"\"\"
      ...> ```elixir
      ...> a = 1
      ...> ```
      ...>
      ...> <!-- livebook:{"force_markdown":true} -->
      ...>
      ...> ```elixir
      ...> b = 2
      ...> ```
      ...>
      ...> ```elixir
      ...> c = 3
      ...> ```
      ...> \"\"\"
      iex> NimbleLivebookMarkdownExtractor.extract_executable_code(content)
      "a = 1\\n\\nc = 3"
  """
  def extract_executable_code(input) when is_binary(input) do
    case extract_code_cells(input) do
      {:ok, code_cells} ->
        code_cells
        |> Enum.map(&String.trim_trailing/1)
        |> Enum.join("\n\n")
        |> String.trim()

      {:error, _reason} ->
        ""
    end
  end
end
