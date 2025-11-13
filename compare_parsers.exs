#!/usr/bin/env elixir

# Comparison script to validate that both implementations produce the same results

Mix.install([
  {:nimble_parsec, "~> 1.4"}
])

# Setup paths
old_parser_path = "/home/chgeuer/src/llm_code_analysis"
new_parser_path = "/home/chgeuer/github/chgeuer/nimble_markdown_parser"

# Load the modules
Code.require_file(Path.join([old_parser_path, "lib", "code_analysis", "livebook", "extractor.ex"]))
Code.require_file(Path.join([new_parser_path, "lib", "livebook_parser.ex"]))

IO.puts("=== Comparing Old and New LiveBook Parsers ===\n")

# Test cases
test_cases = [
  {
    "Simple case with force_markdown",
    """
    # Title

    ```elixir
    a = 1
    ```

    <!-- livebook:{"force_markdown":true} -->

    ```elixir
    b = 2
    ```

    ```elixir
    c = 3
    ```
    """
  },
  {
    "Multiple force_markdown blocks",
    """
    ```elixir
    real1 = 1
    ```

    <!-- livebook:{"force_markdown":true} -->

    ```elixir
    fake1 = 2
    ```

    ```elixir
    real2 = 3
    ```

    <!-- livebook:{"force_markdown":true} -->

    ```elixir
    fake2 = 4
    ```

    ```elixir
    real3 = 5
    ```
    """
  },
  {
    "Complex code with Mix.install",
    """
    ```elixir
    Mix.install([
      {:req, "~> 0.5.16"}
    ])
    ```

    ```elixir
    # Real code
    a = 5
    ```

    <!-- livebook:{"force_markdown":true} -->

    ```elixir
    b = 3
    ```

    ```elixir
    c = "final"
    ```
    """
  },
  {
    "Sample file from repository",
    File.read!(Path.join(new_parser_path, "sample.md.livemd"))
  }
]

# Run comparison
all_passed = Enum.all?(test_cases, fn {name, content} ->
  IO.puts("Testing: #{name}")

  # Old parser output
  old_result = CodeAnalysis.Livebook.Extractor.extract_executable_code(content)

  # New parser output (using the compatible API)
  new_result = NimbleLivebookMarkdownExtractor.extract_executable_code(content)

  IO.puts("  Old parser length: #{String.length(old_result)}")
  IO.puts("  New parser length: #{String.length(new_result)}")

  # Direct string comparison
  if old_result == new_result do
    IO.puts("  ✓ PASSED: Both parsers produced identical results")
    IO.puts("")
    true
  else
    IO.puts("  ❌ MISMATCH: Content differs!")
    IO.puts("\n  Old result:")
    IO.puts("    #{inspect(old_result)}")
    IO.puts("\n  New result:")
    IO.puts("    #{inspect(new_result)}")
    IO.puts("")
    false
  end
end)

IO.puts("\n=== Summary ===")
if all_passed do
  IO.puts("✓ All tests passed! Both implementations produce identical results.")
  System.halt(0)
else
  IO.puts("❌ Some tests failed. The implementations differ.")
  System.halt(1)
end
