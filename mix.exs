defmodule Classifiers.Mixfile do
  use Mix.Project

  def project do
    [
      app: :fsm,
      version: "0.0.1",
      elixir: "~> 1.0.0 or ~> 1.1-dev",
      deps: deps,
      package: package, 
      description: "Implementations of classifier algorithms"
    ]
  end

  def package do
    [
      contributors: ["Beat Richartz"],
      licenses: ["MIT"],
      links: %{"Github": "https://github.com/elixir-cortex/classifiers"}
    ]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:csv, "~> 1.0.0", only: :test},
      {:ex_doc, "~> 0.7.1", only: :docs},
      {:inch_ex, only: :docs},
      {:earmark, only: :docs}
    ]
  end

  defp docs do
    {ref, 0} = System.cmd("git", ["rev-parse", "--verify", "--quiet", "HEAD"])

    [
        source_ref: ref,
        main: "overview"
    ]
  end
end
