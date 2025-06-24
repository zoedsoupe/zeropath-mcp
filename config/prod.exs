import Config

config :logger, :console,
  metadata: [:request_id],
  format: "$time $metadata[$level] $message\n"

config :zero_path_mcp, :rate_limit,
  limit: String.to_integer(System.get_env("RATE_LIMIT_REQUESTS", "100")),
  window_ms: String.to_integer(System.get_env("RATE_LIMIT_WINDOW_MS", "60000"))

config :logger, level: :info

config :hermes_mcp, :logging,
  client_events: :info,
  server_events: :info,
  transport_events: :warning,
  protocol_messages: :warning
