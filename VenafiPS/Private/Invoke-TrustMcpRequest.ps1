function Invoke-TrustMcpRequest {
    <#
    .SYNOPSIS
    Process a single MCP JSON-RPC message

    .DESCRIPTION
    Handle one Model Context Protocol message and return the JSON-RPC response as a hashtable.
    Nothing is returned for notifications.
    Kept separate from the stdio loop in Start-TrustMcpServer so it can be tested directly.

    .PARAMETER Message
    JSON-RPC message, already converted from json

    .PARAMETER Tool
    Tool definitions from Get-TrustMcpTool

    .PARAMETER TrustClient
    Session used by the tool handlers

    .PARAMETER Reconnect
    Scriptblock which is passed TrustClient and updates it in place with a new session.
    Called once, and the tool retried, when a tool call fails with 401 Unauthorized.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [psobject] $Message,

        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [hashtable[]] $Tool,

        [Parameter(Mandatory)]
        [TrustClient] $TrustClient,

        [Parameter()]
        [AllowNull()]
        [scriptblock] $Reconnect
    )

    # newest first, used when the client asks for a version we don't know
    $supportedProtocolVersions = '2025-11-25', '2025-06-18', '2025-03-26', '2024-11-05'

    $isNotification = -not ($Message.PSObject.Properties.Name -contains 'id')

    $newError = {
        param([int] $Code, [string] $ErrorMessage)
        [ordered]@{
            jsonrpc = '2.0'
            id      = $Message.id
            error   = [ordered]@{ code = $Code; message = $ErrorMessage }
        }
    }

    $newResult = {
        param($Result)
        [ordered]@{
            jsonrpc = '2.0'
            id      = $Message.id
            result  = $Result
        }
    }

    switch ($Message.method) {

        'initialize' {
            $requested = $Message.params.protocolVersion
            $version = if ( $requested -in $supportedProtocolVersions ) { $requested } else { $supportedProtocolVersions[0] }

            return (& $newResult ([ordered]@{
                        protocolVersion = $version
                        capabilities    = @{ tools = @{ listChanged = $false } }
                        serverInfo      = [ordered]@{ name = 'VenafiPS'; version = "$script:ModuleVersion" }
                        instructions    = ('Connected to {0} ({1}).  Tools are read-only.  Start with whoami, then certificate_expiry_summary or find_certificates.' -f $TrustClient.Platform, $TrustClient.Server)
                    }))
        }

        'ping' {
            return (& $newResult @{})
        }

        'tools/list' {
            $list = @(
                foreach ( $thisTool in $Tool ) {
                    [ordered]@{
                        name        = $thisTool.name
                        description = $thisTool.description
                        inputSchema = $thisTool.inputSchema
                        annotations = @{ readOnlyHint = $true; openWorldHint = $false }
                    }
                }
            )
            return (& $newResult @{ tools = $list })
        }

        'tools/call' {
            $name = $Message.params.name
            $thisTool = $Tool | Where-Object { $_.name -eq $name } | Select-Object -First 1

            if ( -not $thisTool ) {
                return (& $newError -32602 "Unknown tool: $name")
            }

            $arguments = if ( $Message.params.arguments ) { $Message.params.arguments } else { [pscustomobject]@{} }

            $reconnected = $false
            while ( $true ) {
                try {
                    # treat any error as a failed tool call
                    $ErrorActionPreference = 'Stop'
                    # only keep output and errors, other streams would corrupt stdio
                    $output = & $thisTool.handler $arguments $TrustClient 3>$null 4>$null 5>$null 6>$null
                    $safe = ConvertTo-TrustMcpSafeObject -InputObject $output
                    $text = ConvertTo-Json -InputObject $safe -Depth 20 -Compress
                    $isError = $false
                    break
                }
                catch {
                    $text = $_.Exception.Message
                    $isError = $true

                    $isUnauthorized = $_.Exception.Response.StatusCode -eq [System.Net.HttpStatusCode]::Unauthorized -or $text -match '\b401\b'
                    if ( -not $Reconnect -or $reconnected -or -not $isUnauthorized ) { break }

                    # retry once with a new session
                    $reconnected = $true
                    try {
                        & $Reconnect $TrustClient
                    }
                    catch {
                        $text = '{0}.  Connecting again also failed: {1}' -f $text.TrimEnd('.'), $_.Exception.Message
                        break
                    }
                }
            }

            return (& $newResult ([ordered]@{
                        content = @(@{ type = 'text'; text = "$text" })
                        isError = $isError
                    }))
        }

        default {
            if ( $isNotification ) {
                # notifications/initialized, notifications/cancelled, etc. require no response
                return
            }
            return (& $newError -32601 "Method not found: $($Message.method)")
        }
    }
}
