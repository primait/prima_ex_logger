defmodule TestApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :test_app,
      version: get_release_version(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {TestApp.Application, []},
      extra_applications: [:logger]
    ]
  end

  def get_release_version() do
    case System.get_env("DRONE_TAG") do
      "" -> default_release_version()
      nil -> default_release_version()
      drone_tag -> drone_tag
    end
  end

  def default_release_version(), do: "0.0.0-default"

  defp deps do
    [
      {:jason, "~> 1.0"},
      {:prima_ex_logger, path: "../../.."}
    ]
  end
end
