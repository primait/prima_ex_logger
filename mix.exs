defmodule PrimaExLogger.MixProject do
  use Mix.Project

  def project do
    [
      app: :prima_ex_logger,
      version: "0.1.0",
      source_url: "https://github.com/primait/prima_ex_logger",
      elixir: "~> 1.7",
      deps: deps()
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
      {:timex, "~> 3.5"}
    ]
  end
end
