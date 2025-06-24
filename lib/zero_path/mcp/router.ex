defmodule ZeroPath.MCP.Router do
  @moduledoc """
  Plug router for the Zeropath MCP server
  """

  use Plug.Router

  alias ZeroPath.MCP.Config
  alias ZeroPath.MCP.Plugs.RateLimiter

  @rate_limit Application.compile_env(:zero_path_mcp, :rate_limit, limit: 100, window_ms: 60_000)

  plug(RateLimiter, @rate_limit)

  plug(:match)
  plug(:dispatch)

  if Config.transport_type() == "sse" do
    forward("/mcp/sse",
      to: Hermes.Server.Transport.SSE.Plug,
      init_opts: [server: ZeroPath.MCP.Server, mode: :sse]
    )

    forward("/mcp/message",
      to: Hermes.Server.Transport.SSE.Plug,
      init_opts: [server: ZeroPath.MCP.Server, mode: :post]
    )
  end

  if Config.transport_type() == "http" do
    forward("/mcp",
      to: Hermes.Server.Transport.StreamableHTTP.Plug,
      init_opts: [server: ZeroPath.MCP.Server]
    )
  end

  get "/health" do
    send_resp(conn, 200, "OK")
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
