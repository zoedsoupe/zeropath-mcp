import Config

config :zero_path_mcp, :transport, type: System.get_env("TRANSPORT", "stdio")

import_config "#{config_env()}.exs"
