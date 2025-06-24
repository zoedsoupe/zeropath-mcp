defmodule ZeroPath.MCP.MixProject do
  use Mix.Project

  def project do
    [
      app: :zero_path_mcp,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ZeroPath.MCP.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:hermes_mcp, "~> 0.10"},
      {:req, "~> 0.5"},
      {:bandit, "~> 1.0"},
      {:jason, "~> 1.4"}
    ]
  end

  defp releases do
    [
      zero_path_mcp: [
        include_executables_for: [:unix],
        steps: [:assemble, :tar]
      ]
    ]
  end
end
