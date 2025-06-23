defmodule ZeroPath.MCP.Tools.SearchVulnerabilities do
  @moduledoc "Search for vulnerabilities using the Zeropath API"

  use Hermes.Server.Component, type: :tool

  alias Hermes.Server.Response
  alias ZeroPath.MCP.Client

  schema do
    field(:search_query, :string, description: "Search query to filter vulnerabilities")
  end

  @impl true
  def execute(params, frame) do
    org_id = System.get_env("ZEROPATH_ORG_ID")

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

    header =
      "Found #{total} vulnerability issues. #{patchable} are patchable, #{unpatchable} are unpatchable.\n\n"

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
    parts = [
      "Issue #{index}:",
      "ID: #{issue["id"]}",
      "Status: #{issue["status"] || "unknown"}"
    ]

    parts =
      parts
      |> maybe_add_field(issue, "type", "Type")
      |> maybe_add_patchable(issue)
      |> maybe_add_field(issue, "language", "Language")
      |> maybe_add_field(issue, "score", "Score")
      |> maybe_add_field(issue, "severity", "Severity")
      |> maybe_add_field(issue, "generatedTitle", "Title")
      |> maybe_add_field(issue, "generatedDescription", "Description")
      |> maybe_add_field(issue, "affectedFile", "Affected File")
      |> maybe_add_cwes(issue)
      |> maybe_add_field(issue, "validated", "Validation Status")
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

  defp maybe_add_patchable(parts, issue) do
    case issue["unpatchable"] do
      nil -> parts
      unpatchable -> parts ++ ["Patchable: #{!unpatchable}"]
    end
  end

  defp maybe_add_cwes(parts, %{"cwes" => cwes}) when is_list(cwes) and length(cwes) > 0 do
    parts ++ ["CWEs: #{Enum.join(cwes, ", ")}"]
  end

  defp maybe_add_cwes(parts, _), do: parts

  defp maybe_add_patch_info(parts, %{"vulnerabilityPatch" => patch, "unpatchable" => false}) do
    patch_parts = [
      "\n--- PATCH INFORMATION ---",
      "PATCH ID: #{patch["id"] || "N/A"}",
      "------------------------",
      "Has Patch: Yes"
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
end
