defmodule NimbleLivebookMarkdownExtractor.MixProject do
  use Mix.Project

  def project do
    [
      app: :nimble_livebook_markdown_extractor,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: []
    ]
  end

  defp deps do
    [
      {:nimble_parsec, "~> 1.4"}
    ]
  end
end
