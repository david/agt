defmodule Agt.MixProject do
  use Mix.Project

  def project do
    [
      app: :agt,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Agt.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:req, "~> 0.4.0"},
      {:jason, "~> 1.4"},
      {:earmark_parser, "~> 1.4"}
    ]
  end
end
