defmodule ZeroPath.MCP.RateLimiterTable do
  @moduledoc false
  
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    :ets.new(:rate_limiter, [:public, :named_table, :set])
    {:ok, %{}}
  end
end