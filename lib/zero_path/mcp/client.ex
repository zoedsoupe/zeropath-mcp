defmodule ZeroPath.MCP.Client do
  @moduledoc """
  HTTP client for Zeropath API requests
  """

  alias ZeroPath.MCP.Config

  def search_vulnerabilities(params \\ %{}) do
    make_request("/issues/search", params)
  end

  def get_issue(issue_id, org_id) do
    make_request("/issues/get", %{issueId: issue_id, organizationId: org_id})
  end

  def approve_patch(issue_id, org_id) do
    make_request("/issues/approve-patch", %{issueId: issue_id, organizationId: org_id})
  end

  defp make_request(path, body) do
    if !Config.zeropath_configured?() do
      {:error, "Zeropath API credentials not configured"}
    else
      token_id = Config.zeropath_token_id()
      token_secret = Config.zeropath_token_secret()

      headers = [
        {"X-ZeroPath-API-Token-Id", token_id},
        {"X-ZeroPath-API-Token-Secret", token_secret},
        {"Content-Type", "application/json"}
      ]

      url = Config.zeropath_base_url() <> path

      case Req.post(url, json: body, headers: headers) do
        {:ok, %{status: 200, body: body}} ->
          {:ok, body}

        {:ok, %{status: status, body: body}} ->
          {:error, "API returned status code #{status}: #{inspect(body)}"}

        {:error, reason} ->
          {:error, inspect(reason)}
      end
    end
  end
end
