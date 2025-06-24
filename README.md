# Zeropath MCP Server

A Model Context Protocol (MCP) server that provides AI assistants with tools to interact with the Zeropath vulnerability management API.

## Overview

This MCP server enables AI assistants to search, retrieve, and manage security vulnerabilities through the Zeropath platform. It provides three main tools:

- **Search Vulnerabilities** - Search for vulnerabilities with optional query filters
- **Get Issue** - Retrieve detailed information about a specific vulnerability
- **Approve Patch** - Approve patches for vulnerability remediation

## Prerequisites

- Elixir 1.17 or higher
- Erlang/OTP 27.3.2+
- Zeropath API credentials

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/zeropath-mcp.git
cd zeropath-mcp
```

2. Install dependencies:
```bash
mix deps.get
```

3. Set up environment variables:
```bash
export ZEROPATH_TOKEN_ID="your-token-id"
export ZEROPATH_TOKEN_SECRET="your-token-secret"
export ZEROPATH_ORG_ID="your-organization-id"
```

## Usage

### Running in Development

Start the server with:
```bash
mix run --no-halt
```

By default, the server runs in STDIO mode. For SSE transport:
```bash
TRANSPORT=sse HTTP_SERVER=true mix run --no-halt
```

The server will start on `http://localhost:4010` with endpoints at `/mcp/sse` and `/mcp/message`.

### Building a Release

To create a production-ready binary:

```bash
MIX_ENV=prod mix release
```

This will generate a self-contained release in `_build/prod/rel/zero_path_mcp/`.

To run the release:
```bash
_build/prod/rel/zero_path_mcp/bin/zero_path_mcp start
```

### Docker

Build and run with Docker:
```bash
docker build -t zeropath-mcp .
docker run -e TRANSPORT=sse -e ZEROPATH_TOKEN_ID=xxx -e ZEROPATH_TOKEN_SECRET=yyy -e ZEROPATH_ORG_ID=zzz -p 4010:4010 zeropath-mcp
```

### Configuration

The server can be configured through environment variables:

**Required:**
- `ZEROPATH_TOKEN_ID` - Your Zeropath API token ID
- `ZEROPATH_TOKEN_SECRET` - Your Zeropath API token secret
- `ZEROPATH_ORG_ID` - Your Zeropath organization ID

**Optional:**
- `TRANSPORT` - Transport type: `stdio` (default), `sse`, or `http`
- `HTTP_SERVER` - Set to enable HTTP server for SSE/HTTP transports
- `LOG_LEVEL` - Log level for production (`debug`, `info`, `warning`, `error`)
- `RATE_LIMIT_REQUESTS` - Max requests per minute (default: 100)
- `RATE_LIMIT_WINDOW_MS` - Rate limit window (default: 60000)

## Available Tools

### search_vulnerabilities

Search for vulnerabilities in your codebase.

**Parameters:**
- `search_query` (optional) - Filter vulnerabilities by search query

**Example:**
```json
{
  "tool": "search_vulnerabilities",
  "arguments": {
    "search_query": "SQL injection"
  }
}
```

### get_issue

Retrieve detailed information about a specific vulnerability, including patch details if available.

**Parameters:**
- `issue_id` (required) - The ID of the vulnerability issue

**Example:**
```json
{
  "tool": "get_issue",
  "arguments": {
    "issue_id": "vuln-123456"
  }
}
```

### approve_patch

Approve a patch for a specific vulnerability issue.

**Parameters:**
- `issue_id` (required) - The ID of the issue whose patch should be approved

**Example:**
```json
{
  "tool": "approve_patch",
  "arguments": {
    "issue_id": "vuln-123456"
  }
}
```

## MCP Client Configuration

To use this server with an MCP client, configure it with:

```json
{
  "mcpServers": {
    "zeropath": {
      "command": "path/to/zeropath_mcp",
      "args": ["start"],
      "env": {
        "ZEROPATH_TOKEN_ID": "your-token-id",
        "ZEROPATH_TOKEN_SECRET": "your-token-secret",
        "ZEROPATH_ORG_ID": "your-organization-id"
      }
    }
  }
}
```

## API Integration

This server integrates with the Zeropath API v1. It handles:

- Authentication via API tokens
- Error responses and status codes
- Pagination for search results
- Detailed vulnerability and patch information

## Development

### Running Tests

```bash
mix test
```

### Code Formatting

```bash
mix format
```
