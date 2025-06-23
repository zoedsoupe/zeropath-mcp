defmodule ZeroPath.MCP.MixProject do
  use Mix.Project

  def project do
    [
      app: :zeropath_mcp,
      version: "0.1.0",
      elixir: "~> 1.19-rc",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:bandit, "~> 1.0"}
    ]
  end
end
