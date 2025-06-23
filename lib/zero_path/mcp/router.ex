defmodule ZeroPath.MCP.Router do
  @moduledoc """
  Plug router for the Zeropath MCP server
  """

  use Plug.Router

  plug(:match)
  plug(:dispatch)

  forward("/sse",
    to: Hermes.Server.Transport.SSE.Plug,
    init_opts: [server: ZeroPath.MCP.Server, mode: :sse]
  )

  forward("/message",
    to: Hermes.Server.Transport.SSE.Plug,
    init_opts: [server: ZeroPath.MCP.Server, mode: :post]
  )

  get "/health" do
    send_resp(conn, 200, "OK")
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
