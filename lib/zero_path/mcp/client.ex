defmodule ZeroPath.MCP.Client do
  @moduledoc """
  HTTP client for Zeropath API requests
  """

  @base_url "https://zeropath.com/api/v1"

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
    token_id = System.get_env("ZEROPATH_TOKEN_ID")
    token_secret = System.get_env("ZEROPATH_TOKEN_SECRET")

    if !token_id || !token_secret do
      {:error, "Zeropath API credentials not found in environment variables"}
    else
      headers = [
        {"X-ZeroPath-API-Token-Id", token_id},
        {"X-ZeroPath-API-Token-Secret", token_secret},
        {"Content-Type", "application/json"}
      ]

      case Req.post(@base_url <> path, json: body, headers: headers) do
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
