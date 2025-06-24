defmodule ZeroPath.MCP.Tools.GetIssue do
  @moduledoc """
  Get detailed information about a specific vulnerability issue.

  This tool retrieves comprehensive details about a vulnerability including:
  - Complete vulnerability description and impact
  - Affected code segments and file locations
  - Available patches with code diffs
  - Severity scores and CWE classifications
  - Triage status and validation information

  ## Usage
  First use search_vulnerabilities to find issues and get their IDs, then:
  - get_issue("issue_abc123") - Get full details for this issue

  ## Response includes
  - Issue metadata (ID, status, severity, type)
  - Affected code with line numbers
  - Patch information with git-style diffs (if available)
  - References and additional context
  """

  use Hermes.Server.Component, type: :tool

  alias Hermes.Server.Response
  alias ZeroPath.MCP.{Client, Config}

  schema do
    field(:issue_id, :string,
      required: true,
      description: "The issue ID obtained from search_vulnerabilities tool (e.g., 'issue_abc123')"
    )
  end

  @impl true
  def execute(%{issue_id: issue_id}, frame) do
    if !Config.zeropath_configured?() do
      {:reply, Response.error(Response.tool(), "ZeroPath API not configured"), frame}
    else
      org_id = Config.zeropath_org_id()

      case Client.get_issue(issue_id, org_id) do
        {:ok, response} ->
          formatted = format_issue_response(response)
          {:reply, Response.text(Response.tool(), formatted), frame}

        {:error, error} ->
          error_message = if is_binary(error), do: error, else: inspect(error)
          {:reply, Response.error(Response.tool(), error_message), frame}
      end
    end
  end

  defp format_issue_response(%{"error" => error}) when not is_nil(error) do
    "Error: #{error}"
  end

  defp format_issue_response(issue) when is_map(issue) do
    if !issue["id"] do
      "Error: Invalid issue data received - missing ID"
    else
      format_issue_details(issue)
    end
  end

  defp format_issue_response(_) do
    "Error: Empty issue data"
  end

  defp format_issue_details(issue) do
    patch = issue["patch"] || issue["vulnerabilityPatch"]

    parts = [
      "Issue Details:",
      "ID: #{issue["id"] || "N/A"}",
      "Status: #{issue["status"] || "N/A"}",
      "Title: #{issue["generatedTitle"] || "N/A"}",
      "Description: #{issue["generatedDescription"] || "N/A"}",
      "Language: #{issue["language"] || "N/A"}",
      "Vulnerability Class: #{issue["vulnClass"] || "N/A"}"
    ]

    parts = parts |> maybe_add_cwes(issue)

    parts =
      parts ++
        [
          "Severity: #{issue["severity"] || "N/A"}",
          "Affected File: #{issue["affectedFile"] || "N/A"}"
        ]

    parts = parts |> maybe_add_location(issue)

    parts =
      parts ++
        [
          "Validation Status: #{issue["validated"] || "N/A"}",
          "Unpatchable: #{issue["unpatchable"] || false}",
          "Triage Phase: #{issue["triagePhase"] || "N/A"}"
        ]

    parts = parts |> maybe_add_code_segment(issue)
    parts = parts |> maybe_add_patch_info(issue, patch)

    Enum.join(parts, "\n")
  end

  defp maybe_add_cwes(parts, %{"cwes" => cwes}) when is_list(cwes) and length(cwes) > 0 do
    parts ++ ["CWEs: #{Enum.join(cwes, ", ")}"]
  end

  defp maybe_add_cwes(parts, _), do: parts

  defp maybe_add_location(parts, %{"startLine" => start_line, "endLine" => end_line}) do
    parts ++ ["Location: Lines #{start_line} to #{end_line}"]
  end

  defp maybe_add_location(parts, _), do: parts

  defp maybe_add_code_segment(parts, %{"sastCodeSegment" => segment}) when is_binary(segment) do
    parts ++ ["\nVulnerable Code Segment:\n```\n#{segment}\n```"]
  end

  defp maybe_add_code_segment(parts, _), do: parts

  defp maybe_add_patch_info(parts, %{"unpatchable" => true}, _), do: parts

  defp maybe_add_patch_info(parts, _, patch) when is_map(patch) do
    patch_parts = [
      "\n========== PATCH INFORMATION ==========",
      "PR Link: #{patch["prLink"] || "N/A"}",
      "PR Title: #{patch["prTitle"] || "N/A"}",
      "PR Description: #{patch["prDescription"] || "N/A"}",
      "PR Status: #{patch["pullRequestStatus"] || "N/A"}",
      "Validation Status: #{patch["validated"] || "N/A"}",
      "Created At: #{patch["createdAt"] || "N/A"}",
      "Updated At: #{patch["updatedAt"] || "N/A"}"
    ]

    patch_parts = patch_parts |> maybe_add_git_diff(patch)

    parts ++ patch_parts
  end

  defp maybe_add_patch_info(parts, _, _), do: parts

  defp maybe_add_git_diff(parts, %{"gitDiff" => diff, "id" => patch_id}) when is_binary(diff) do
    parts ++
      [
        "\n========== PATCH ID & GIT DIFF ==========",
        "PATCH ID: #{patch_id}",
        "========================================",
        "Git Diff:\n```diff\n#{diff}\n```"
      ]
  end

  defp maybe_add_git_diff(parts, %{"gitDiff" => diff}) when is_binary(diff) do
    parts ++
      [
        "\n========== GIT DIFF ==========",
        "Git Diff:\n```diff\n#{diff}\n```"
      ]
  end

  defp maybe_add_git_diff(parts, _), do: parts
end
