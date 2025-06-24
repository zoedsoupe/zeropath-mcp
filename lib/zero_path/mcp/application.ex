defmodule ZeroPath.MCP.Application do
  @moduledoc false

  use Application

  alias ZeroPath.MCP.Config

  @impl true
  def start(_type, _args) do
    transport = Config.transport_type()

    base_children = [
      Hermes.Server.Registry,
      ZeroPath.MCP.RateLimiterTable
    ]
    
    children = base_children ++ transport_children(transport)

    opts = [strategy: :one_for_one, name: ZeroPath.MCP.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp transport_children("stdio") do
    [
      {ZeroPath.MCP.Server, transport: :stdio}
    ]
  end

  defp transport_children("sse") do
    start? = Config.http_server?()

    [
      {ZeroPath.MCP.Server,
       transport: {:sse, base_url: "/mcp", post_path: "/mcp/message", start: start?}},
      {Bandit, plug: ZeroPath.MCP.Router}
    ]
  end

  defp transport_children("http") do
    start? = Config.http_server?()

    [
      {ZeroPath.MCP.Server, transport: {:streamable_http, start: start?}},
      {Bandit, plug: ZeroPath.MCP.Router}
    ]
  end
end
