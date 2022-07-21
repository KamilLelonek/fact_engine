defmodule FactEngine.MixProject do
  use Mix.Project

  def project do
    [
      app: :fact_engine,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {FactEngine.Application, []}
    ]
  end

  defp deps do
    []
  end
end
