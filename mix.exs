defmodule Classifiers.Mixfile do
  use Mix.Project

  def project do
    [
      app: :fsm,
      version: "0.0.1",
      elixir: ">= 1.0.0",
      deps: deps,
      package: [
        contributors: ["Beat Richartz"],
        licenses: ["MIT"],
        links: %{"Github": "https://github.com/elixir-cortex/classifiers"}
      ],
      description: "Implementations of classifier algorithms"
    ]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:csv, "~> 0.2.0"}]
  end
end
