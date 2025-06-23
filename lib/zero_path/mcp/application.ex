defmodule ZeroPath.MCP.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Hermes.Server.Registry,
      {ZeroPath.MCP.Server, transport: {:sse, base_url: "/", post_path: "/message", start: true}},
      {Bandit, plug: ZeroPath.MCP.Router}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ZeroPath.MCP.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
