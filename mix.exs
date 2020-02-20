defmodule PrimaExLogger.MixProject do
  use Mix.Project

  def project do
    [
      app: :prima_ex_logger,
      version: "0.1.0",
      source_url: "https://github.com/primait/prima_ex_logger",
      elixir: "~> 1.7",
      deps: deps(),
      aliases: aliases(),
      dialyzer: [
        ignore_warnings: ".dialyzerignore",
        plt_ignore_apps: [:timex]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :timex]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.1", only: [:test]},
      {:poison, "~> 3.1", only: [:test]},
      {:credo, "~> 1.2", only: [:test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.7", only: [:test], runtime: false},
      {:timex, "~> 3.5"}
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
end
