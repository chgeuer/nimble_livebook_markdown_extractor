# Comparison: Old vs New LiveBook Parser

## Summary

Both the original regex-based parser (`CodeAnalysis.Livebook.Extractor`) and the new NimbleParsec-based parser (`LivebookParser`) produce **identical results** for the core functionality of extracting executable Elixir code from LiveBook markdown files.

## Validation

Run `elixir compare_parsers.exs` to verify that both implementations produce identical output across multiple test cases.

✅ **All tests pass** - Both parsers produce byte-for-byte identical results.

## API Comparison

### Original Parser (`CodeAnalysis.Livebook.Extractor`)

**Location:** `/home/chgeuer/src/llm_code_analysis/lib/code_analysis/livebook/extractor.ex`

**Main Function:**
```elixir
@spec extract_executable_code(String.t()) :: String.t()
def extract_executable_code(content)
```

Returns a single string with all executable code cells joined by blank lines.

**Additional Features:**
- `extract_aliases/1` - Extract alias declarations from AST
- `extract_calls/1` - Extract module function calls from AST
- `resolve_alias/2` - Resolve short names to full module names

**Implementation:** State machine using `Enum.reduce/3` with regex pattern matching

### New Parser (`LivebookParser`)

**Location:** `/home/chgeuer/github/chgeuer/nimble_markdown_parser/lib/livebook_parser.ex`

**Main Functions:**

1. **Compatible API:**
```elixir
@spec extract_executable_code(String.t()) :: String.t()
def extract_executable_code(content)
```
Returns a single string (identical to original parser).

2. **List-based API:**
```elixir
@spec extract_code_cells(String.t()) :: {:ok, [String.t()]} | {:error, String.t()}
def extract_code_cells(content)
```
Returns individual code cells as a list.

3. **Metadata API:**
```elixir
@spec extract_all_code_cells(String.t()) :: {:ok, [{String.t(), boolean()}]} | {:error, String.t()}
def extract_all_code_cells(content)
```
Returns all code cells with `force_markdown` status.

**Implementation:** NimbleParsec combinators for robust parsing

## Key Differences

### Parsing Approach

| Aspect | Original Parser | New Parser |
|--------|----------------|------------|
| Method | Regex + State Machine | NimbleParsec Combinators |
| Robustness | Good for standard cases | More resilient to edge cases |
| Performance | Fast for simple docs | Optimized by NimbleParsec |
| Maintainability | Simple but manual | Declarative and composable |

### Return Types

**Original:**
- Always returns a string (even if empty on error)

**New:**
- `extract_executable_code/1` - String (compatible)
- `extract_code_cells/1` - `{:ok, [String.t()]} | {:error, reason}`
- `extract_all_code_cells/1` - `{:ok, [{String.t(), boolean()}]} | {:error, reason}`

### Error Handling

**Original:**
- Returns empty string on any issue
- No explicit error reporting

**New:**
- Returns `{:ok, result}` or `{:error, reason}` tuples
- `extract_executable_code/1` returns empty string for compatibility

## Advantages of New Parser

1. **Explicit Error Handling** - Clear success/failure indication
2. **Structured Output** - Can get individual cells instead of joined string
3. **Metadata Support** - Can distinguish real code from examples
4. **Composable** - NimbleParsec combinators are easy to extend
5. **Type Safety** - Clear specs with proper return types
6. **Full Compatibility** - Drop-in replacement via `extract_executable_code/1`

## Migration Guide

### Drop-in Replacement

Replace:
```elixir
result = CodeAnalysis.Livebook.Extractor.extract_executable_code(content)
```

With:
```elixir
result = LivebookParser.extract_executable_code(content)
```

No other changes needed - output is identical.

### Using New Features

If you want to process cells individually:
```elixir
{:ok, cells} = LivebookParser.extract_code_cells(content)

Enum.each(cells, fn cell ->
  # Process each cell separately
  analyze_cell(cell)
end)
```

If you need to distinguish real code from examples:
```elixir
{:ok, all_cells} = LivebookParser.extract_all_code_cells(content)

Enum.each(all_cells, fn {code, is_markdown_example} ->
  if is_markdown_example do
    IO.puts("Example: #{code}")
  else
    IO.puts("Real code: #{code}")
    execute_code(code)
  end
end)
```

## Test Coverage

### Original Parser
- Located in doctest examples within the module
- Tests basic functionality

### New Parser
- 16 comprehensive tests in `test/livebook_parser_test.exs`
- Tests all three extraction functions
- Includes edge cases (empty docs, multiple markers, complex code)
- Validates against `sample.md.livemd`

## Conclusion

The new NimbleParsec-based parser provides **100% compatible** functionality with the original parser while offering:
- Better error handling
- More flexible APIs
- Robust parsing implementation
- Comprehensive test coverage

It's a drop-in replacement that also enables new use cases through its additional APIs.
