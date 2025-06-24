defmodule ZeroPath.MCP.Tools.SearchVulnerabilities do
  @moduledoc """
  Search for security vulnerabilities in your codebase using the ZeroPath API.

  This tool searches the ZeroPath vulnerability database and returns:
  - Issue IDs (required for get_issue and approve_patch tools)
  - Vulnerability details (type, severity, affected files, CWEs)
  - Patch availability status and patch IDs
  - Triage status and validation information

  ## Search Examples
  - "sql injection" - Find SQL injection vulnerabilities
  - "high severity" - Find high severity issues
  - "xss" - Find cross-site scripting vulnerabilities
  - "unpatchable" - Find issues without available patches
  - Leave empty to retrieve all vulnerabilities

  ## Workflow
  1. Use this tool first to search and get issue IDs
  2. Use get_issue(issue_id) for detailed information
  3. Use approve_patch(issue_id) to approve available patches

  Returns paginated results with issue IDs prominently displayed for use with other tools.
  """

  use Hermes.Server.Component, type: :tool

  alias Hermes.Server.Response
  alias ZeroPath.MCP.{Client, Config}

  schema do
    field(:search_query, :string,
      description:
        "Optional search query to filter vulnerabilities. Examples: 'sql injection', 'high severity', 'xss', or leave empty for all issues"
    )
  end

  @impl true
  def execute(params, frame) do
    org_id = Config.zeropath_org_id()

    payload =
      %{}
      |> maybe_add_search_query(params)
      |> maybe_add_org_id(org_id)

    case Client.search_vulnerabilities(payload) do
      {:ok, response} ->
        formatted = format_vulnerabilities(response)
        {:reply, Response.text(Response.tool(), formatted), frame}

      {:error, error} ->
        {:reply, Response.error(Response.tool(), error), frame}
    end
  end

  defp maybe_add_search_query(payload, %{search_query: query}) when is_binary(query) do
    Map.put(payload, :searchQuery, query)
  end

  defp maybe_add_search_query(payload, _), do: payload

  defp maybe_add_org_id(payload, org_id) when is_binary(org_id) do
    Map.put(payload, :organizationId, org_id)
  end

  defp maybe_add_org_id(payload, _), do: payload

  defp format_vulnerabilities(%{"error" => error}) when not is_nil(error) do
    "Error: #{error}"
  end

  defp format_vulnerabilities(%{"issues" => issues} = response) do
    total = length(issues)
    patchable = Enum.count(issues, &(!&1["unpatchable"]))
    unpatchable = Enum.count(issues, & &1["unpatchable"])

    header = """
    ====== VULNERABILITY SEARCH RESULTS ======
    Total Issues: #{total}
    Patchable: #{patchable}
    Unpatchable: #{unpatchable}
    ==========================================

    """

    issues_text =
      issues
      |> Enum.with_index(1)
      |> Enum.map(&format_issue/1)
      |> Enum.join("\n")

    pagination = format_pagination(response)

    header <> issues_text <> pagination
  end

  defp format_vulnerabilities(_) do
    "No vulnerability issues found in the response."
  end

  defp format_issue({issue, index}) do
    severity_indicator = format_severity_indicator(issue["severity"])
    patch_status = if issue["unpatchable"], do: "[UNPATCHABLE]", else: "[PATCHABLE]"

    parts = [
      "---------- Issue ##{index} #{patch_status} ----------",
      ">>> ISSUE ID: #{issue["id"]} <<<",
      "#{severity_indicator} Severity: #{issue["severity"] || "unknown"}",
      "Status: #{issue["status"] || "unknown"}"
    ]

    parts =
      parts
      |> maybe_add_field(issue, "type", "Type")
      |> maybe_add_field(issue, "language", "Language")
      |> maybe_add_field(issue, "score", "Score")
      |> maybe_add_field(issue, "generatedTitle", "Title")
      |> maybe_add_field(issue, "generatedDescription", "Description")
      |> maybe_add_field(issue, "affectedFile", "Affected File")
      |> maybe_add_cwes(issue)
      |> maybe_add_field(issue, "validated", "Validation")
      |> maybe_add_field(issue, "triagePhase", "Triage Phase")
      |> maybe_add_patch_info(issue)

    Enum.join(parts, "\n") <> "\n"
  end

  defp maybe_add_field(parts, issue, key, label) do
    case issue[key] do
      nil -> parts
      value -> parts ++ ["#{label}: #{value}"]
    end
  end

  defp maybe_add_cwes(parts, %{"cwes" => cwes}) when is_list(cwes) and length(cwes) > 0 do
    parts ++ ["CWEs: #{Enum.join(cwes, ", ")}"]
  end

  defp maybe_add_cwes(parts, _), do: parts

  defp maybe_add_patch_info(parts, %{"vulnerabilityPatch" => patch, "unpatchable" => false}) do
    patch_parts = [
      "",
      "[PATCH AVAILABLE]",
      "  - PATCH ID: #{patch["id"] || "N/A"}",
      "  - To apply: approve_patch(\"#{patch["issueId"]}\")"
    ]

    patch_parts =
      case patch["pullRequestStatus"] do
        nil -> patch_parts
        status -> patch_parts ++ ["Patch Status: #{status}"]
      end

    parts ++ patch_parts
  end

  defp maybe_add_patch_info(parts, _), do: parts

  defp format_pagination(%{"currentPage" => page, "pageSize" => size}) do
    "\nPagination Info:\nCurrent Page: #{page}\nPage Size: #{size}\n"
  end

  defp format_pagination(%{"currentPage" => page}) do
    "\nPagination Info:\nCurrent Page: #{page}\n"
  end

  defp format_pagination(%{"pageSize" => size}) do
    "\nPagination Info:\nPage Size: #{size}\n"
  end

  defp format_pagination(_), do: ""

  defp format_severity_indicator(severity) when is_binary(severity) do
    case String.downcase(severity) do
      "critical" -> "[CRITICAL]"
      "high" -> "[HIGH]"
      "medium" -> "[MEDIUM]"
      "low" -> "[LOW]"
      _ -> "[UNKNOWN]"
    end
  end
  
  defp format_severity_indicator(severity) when is_number(severity) do
    cond do
      severity >= 9.0 -> "[CRITICAL]"
      severity >= 7.0 -> "[HIGH]"
      severity >= 4.0 -> "[MEDIUM]"
      severity >= 0.1 -> "[LOW]"
      true -> "[UNKNOWN]"
    end
  end
  
  defp format_severity_indicator(_), do: "[UNKNOWN]"
end
