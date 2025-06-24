defmodule ZeroPath.MCP.Tools.ApprovePatch do
  @moduledoc """
  Approve a patch for a specific vulnerability issue.

  This tool approves the application of an available patch to fix a vulnerability.
  Only works for issues that have patchable status (not marked as unpatchable).

  ## Prerequisites
  1. Use search_vulnerabilities to find patchable issues
  2. Optionally use get_issue to review the patch details
  3. Use this tool to approve and apply the patch

  ## Usage
  - approve_patch("issue_abc123") - Approves the patch for this issue

  ## Common responses
  - Success: "Patch approved successfully"
  - Error 400: Issue doesn't exist or no patch available
  - Error 401: Authentication failed
  """

  use Hermes.Server.Component, type: :tool

  alias Hermes.Server.Response
  alias ZeroPath.MCP.{Client, Config}

  schema do
    field(:issue_id, :string,
      required: true,
      description:
        "The issue ID from search_vulnerabilities. Must be a patchable issue (check patch availability first)"
    )
  end

  @impl true
  def execute(%{issue_id: issue_id}, frame) do
    if !Config.zeropath_configured?() do
      {:reply, Response.error(Response.tool(), "ZeroPath API not configured"), frame}
    else
      org_id = Config.zeropath_org_id()

      case Client.approve_patch(issue_id, org_id) do
        {:ok, _response} ->
          {:reply, Response.text(Response.tool(), "Patch approved successfully"), frame}

        {:error, error} ->
          {:reply, Response.error(Response.tool(), format_error(error)), frame}
      end
    end
  end

  defp format_error(error) when is_binary(error) do
    cond do
      String.contains?(error, "401") ->
        "Error: Unauthorized - Invalid API credentials"

      String.contains?(error, "400") ->
        "Error: Bad Request - Invalid issue ID or missing required parameters"

      true ->
        "Error: #{error}"
    end
  end

  defp format_error(error) do
    "Error: #{inspect(error)}"
  end
end
