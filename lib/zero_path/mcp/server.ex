defmodule ZeroPath.MCP.Server do
  @moduledoc false

  use Hermes.Server, name: "zeropath", version: "0.1.0", capabilities: [:tools]

  # Register the tools
  component(ZeroPath.MCP.Tools.SearchVulnerabilities)
  component(ZeroPath.MCP.Tools.GetIssue)
  component(ZeroPath.MCP.Tools.ApprovePatch)

  def start_link(opts) do
    validate_environment!()
    Hermes.Server.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok, frame), do: {:ok, frame}

  defp validate_environment! do
    missing_vars = []

    missing_vars =
      if System.get_env("ZEROPATH_TOKEN_ID"),
        do: missing_vars,
        else: ["ZEROPATH_TOKEN_ID" | missing_vars]

    missing_vars =
      if System.get_env("ZEROPATH_TOKEN_SECRET"),
        do: missing_vars,
        else: ["ZEROPATH_TOKEN_SECRET" | missing_vars]

    missing_vars =
      if System.get_env("ZEROPATH_ORG_ID"),
        do: missing_vars,
        else: ["ZEROPATH_ORG_ID" | missing_vars]

    if missing_vars != [] do
      raise "Missing required environment variables: #{Enum.join(missing_vars, ", ")}"
    end
  end
end
