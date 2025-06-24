import Config

if System.get_env("HTTP_SERVER") do
  config :zero_path_mcp, server: true
else
  config :zero_path_mcp, server: false
end

config :zero_path_mcp, :zeropath,
  token_id: System.fetch_env!("ZEROPATH_TOKEN_ID"),
  token_secret: System.fetch_env!("ZEROPATH_TOKEN_SECRET"),
  org_id: System.fetch_env!("ZEROPATH_ORG_ID"),
  base_url: System.get_env("ZEROPATH_API_URL", "https://zeropath.com/api/v1")

if config_env() == :prod do
  if log_level = System.get_env("LOG_LEVEL") do
    config :logger, level: String.to_existing_atom(log_level)
  end

  if System.get_env("TRANSPORT") == "stdio" do
    config :hermes_mcp, :log, false
  end
end
