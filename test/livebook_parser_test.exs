defmodule NimbleLivebookMarkdownExtractorTest do
  use ExUnit.Case
  doctest NimbleLivebookMarkdownExtractor

  describe "extract_code_cells/1" do
    test "extracts real code cells from sample.md.livemd" do
      content = File.read!("sample.md.livemd")

      {:ok, code_cells} = NimbleLivebookMarkdownExtractor.extract_code_cells(content)

      # Should have 4 real code cells (not the force_markdown one)
      assert length(code_cells) == 4

      # Check the content of each cell
      assert Enum.at(code_cells, 0) =~ "Mix.install"
      assert Enum.at(code_cells, 1) =~ "a = 5"
      assert Enum.at(code_cells, 2) =~ "Req.get!"
      assert Enum.at(code_cells, 3) =~ ~s(c = "This is a real code cell")

      # Should NOT contain the force_markdown cell
      refute Enum.any?(code_cells, &(&1 =~ "b = 3"))
    end

    test "extracts code cells from simple example" do
      content = """
      # Title

      ```elixir
      a = 1
      ```

      Some text

      <!-- livebook:{"force_markdown":true} -->

      ```elixir
      b = 2
      ```

      More text

      ```elixir
      c = 3
      ```
      """

      {:ok, code_cells} = NimbleLivebookMarkdownExtractor.extract_code_cells(content)

      assert length(code_cells) == 2
      assert Enum.at(code_cells, 0) =~ "a = 1"
      assert Enum.at(code_cells, 1) =~ "c = 3"
      refute Enum.any?(code_cells, &(&1 =~ "b = 2"))
    end

    test "handles multiple force_markdown blocks" do
      content = """
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

      {:ok, code_cells} = NimbleLivebookMarkdownExtractor.extract_code_cells(content)

      assert length(code_cells) == 3
      assert Enum.at(code_cells, 0) =~ "real1 = 1"
      assert Enum.at(code_cells, 1) =~ "real2 = 3"
      assert Enum.at(code_cells, 2) =~ "real3 = 5"
    end

    test "handles code blocks with complex content" do
      content = """
      ```elixir
      defmodule MyModule do
        def hello do
          IO.puts("Hello, World!")
        end
      end

      MyModule.hello()
      ```

      <!-- livebook:{"force_markdown":true} -->

      ```elixir
      # This should not be extracted
      IO.puts("Fake")
      ```
      """

      {:ok, code_cells} = NimbleLivebookMarkdownExtractor.extract_code_cells(content)

      assert length(code_cells) == 1
      assert hd(code_cells) =~ "defmodule MyModule"
      assert hd(code_cells) =~ "MyModule.hello()"
    end

    test "handles empty document" do
      content = """
      # Just a title

      Some text
      """

      {:ok, code_cells} = NimbleLivebookMarkdownExtractor.extract_code_cells(content)

      assert code_cells == []
    end
  end

  describe "extract_all_code_cells/1" do
    test "extracts all code cells with metadata" do
      content = """
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

      {:ok, code_cells} = NimbleLivebookMarkdownExtractor.extract_all_code_cells(content)

      assert length(code_cells) == 3
      assert {"a = 1\n", false} in code_cells
      assert {"b = 2\n", true} in code_cells
      assert {"c = 3\n", false} in code_cells
    end

    test "handles all real code cells" do
      content = """
      ```elixir
      x = 1
      ```

      ```elixir
      y = 2
      ```
      """

      {:ok, code_cells} = NimbleLivebookMarkdownExtractor.extract_all_code_cells(content)

      assert length(code_cells) == 2
      assert Enum.all?(code_cells, fn {_, is_markdown} -> is_markdown == false end)
    end
  end

  describe "extract_executable_code/1" do
    test "returns a single string like the original parser" do
      content = """
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

      result = NimbleLivebookMarkdownExtractor.extract_executable_code(content)

      assert result == "a = 1\n\nc = 3"
    end

    test "joins multiple code cells with blank lines" do
      content = """
      ```elixir
      first = 1
      ```

      ```elixir
      second = 2
      ```

      ```elixir
      third = 3
      ```
      """

      result = NimbleLivebookMarkdownExtractor.extract_executable_code(content)

      assert result == "first = 1\n\nsecond = 2\n\nthird = 3"
    end

    test "preserves blank lines within code cells" do
      content = """
      ```elixir
      # Comment

      a = 1
      ```

      ```elixir
      b = 2
      ```
      """

      result = NimbleLivebookMarkdownExtractor.extract_executable_code(content)

      assert result == "# Comment\n\na = 1\n\nb = 2"
    end

    test "handles empty document" do
      content = """
      # Just text

      No code here
      """

      result = NimbleLivebookMarkdownExtractor.extract_executable_code(content)

      assert result == ""
    end
  end
end
