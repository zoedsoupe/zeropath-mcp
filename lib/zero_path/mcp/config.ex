defmodule ZeroPath.MCP.Config do
  @moduledoc """
  Centralized configuration access for the ZeroPath MCP server.

  All environment variables and application configuration should be
  accessed through this module rather than directly.
  """

  @doc """
  Get the transport type (stdio or sse).
  """
  def transport_type do
    Application.get_env(:zero_path_mcp, :transport)[:type]
  end

  @doc """
  Get ZeroPath API credentials and configuration.
  """
  def zeropath_token_id do
    Application.get_env(:zero_path_mcp, :zeropath)[:token_id]
  end

  def zeropath_token_secret do
    Application.get_env(:zero_path_mcp, :zeropath)[:token_secret]
  end

  def zeropath_org_id do
    Application.get_env(:zero_path_mcp, :zeropath)[:org_id]
  end

  def zeropath_base_url do
    Application.get_env(:zero_path_mcp, :zeropath)[:base_url]
  end

  @doc """
  Get all ZeroPath configuration as a map.
  """
  def zeropath_config do
    Application.get_env(:zero_path_mcp, :zeropath)
  end

  @doc """
  Check if all required ZeroPath credentials are configured.
  """
  def zeropath_configured? do
    config = zeropath_config()

    config[:token_id] != nil and
      config[:token_secret] != nil and
      config[:org_id] != nil
  end

  @doc """
  Check if HTTP server should be started (for SSE/HTTP transports).
  """
  def http_server? do
    Application.get_env(:zero_path_mcp, :server, true)
  end
end
