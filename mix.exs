defmodule PrimaExLogger.MixProject do
  use Mix.Project

  @source_url "https://github.com/primait/prima_ex_logger"
  @version "0.6.0"

  def project do
    [
      app: :prima_ex_logger,
      version: @version,
      source_url: @source_url,
      elixir: "~> 1.12",
      deps: deps(),
      aliases: aliases(),
      description: description(),
      package: package(),
      dialyzer: [
        ignore_warnings: ".dialyzerignore"
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:decimal, "~> 2.0", only: [:test]},
      {:jason, "~> 1.2", only: [:test]},
      {:poison, "~> 6.0", only: [:test]},
      {:credo, "~> 1.2", only: [:test], runtime: false},
      {:dialyxir, "~> 1.4.0", only: [:test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: [:test, :dev], runtime: false}
    ]
  end

  defp aliases do
    [
      check: [
        "format --check-formatted mix.exs \"lib/**/*.{ex,exs}\" \"test/**/*.{ex,exs}\" \"config/**/*.{ex,exs}\"",
        "credo -a --strict",
        "dialyzer"
      ],
      "format.all": [
        "format mix.exs \"lib/**/*.{ex,exs}\" \"test/**/*.{ex,exs}\" \"config/**/*.{ex,exs}\""
      ]
    ]
  end

  def package do
    [
      name: "prima_ex_logger",
      maintainers: ["Michelangelo Morrillo"],
      licenses: ["MIT"],
      links: %{"Github" => @source_url}
    ]
  end

  def description do
    "custom JSON Logger backend"
  end
end
