import Config

# Development logging configuration
config :logger, :console,
  metadata: [:request_id],
  format: "[$level] $message\n"

config :logger, level: :debug

# Hermes MCP logging for development - verbose
config :hermes_mcp, :logging,
  client_events: :debug,
  server_events: :debug,
  transport_events: :debug,
  protocol_messages: :debug
