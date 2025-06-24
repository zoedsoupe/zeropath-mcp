defmodule ZeroPath.MCP.Plugs.RateLimiter do
  @moduledoc """
  Rate limiter plug for MCP endpoints.
  """

  import Plug.Conn
  require Logger

  @behaviour Plug

  @default_limit 100
  @default_window_ms 60_000

  def init(opts) do
    limit = Keyword.get(opts, :limit, @default_limit)
    window_ms = Keyword.get(opts, :window_ms, @default_window_ms)
    table_name = Keyword.get(opts, :table_name, :rate_limiter)

    %{
      limit: limit,
      window_ms: window_ms,
      table: table_name
    }
  end

  def call(conn, %{limit: limit, window_ms: window_ms, table: table} = _opts) do
    ip = get_ip(conn)
    now = System.system_time(:millisecond)

    case check_rate_limit(table, ip, now, limit, window_ms) do
      :ok ->
        conn

      {:error, :rate_limited} ->
        Logger.warning("Rate limit exceeded for IP: #{ip}")

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          429,
          Jason.encode!(%{
            error: "Too many requests",
            message: "Rate limit exceeded. Please try again later."
          })
        )
        |> halt()
    end
  end

  defp get_ip(conn) do
    forwarded_for = get_req_header(conn, "x-forwarded-for")
    real_ip = get_req_header(conn, "x-real-ip")

    ip =
      cond do
        forwarded_for != [] ->
          forwarded_for
          |> List.first()
          |> String.split(",")
          |> List.first()
          |> String.trim()

        real_ip != [] ->
          List.first(real_ip)

        true ->
          conn.remote_ip
          |> :inet.ntoa()
          |> to_string()
      end

    ip
  end

  defp check_rate_limit(table, ip, now, limit, window_ms) do
    window_start = now - window_ms

    case :ets.lookup(table, ip) do
      [] ->
        :ets.insert(table, {ip, [now]})
        :ok

      [{^ip, timestamps}] ->
        recent_timestamps = Enum.filter(timestamps, &(&1 > window_start))

        if length(recent_timestamps) >= limit do
          {:error, :rate_limited}
        else
          :ets.insert(table, {ip, [now | recent_timestamps]})
          :ok
        end
    end
  end
end
