defmodule ZeroPath.MCP.Tools.ApprovePatch do
  @moduledoc "Approve a patch for a specific vulnerability issue"

  use Hermes.Server.Component, type: :tool

  alias Hermes.Server.Response
  alias ZeroPath.MCP.Client

  schema do
    field(:issue_id, :string,
      required: true,
      description: "The ID of the issue whose patch should be approved"
    )
  end

  @impl true
  def execute(%{issue_id: issue_id}, frame) do
    org_id = System.get_env("ZEROPATH_ORG_ID")

    if !org_id do
      {:reply, Response.error(Response.tool(), "ZEROPATH_ORG_ID environment variable not set"),
       frame}
    else
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
