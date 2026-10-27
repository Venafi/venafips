function Start-TrustMcpServer {
    <#
    .SYNOPSIS
    Start a Model Context Protocol (MCP) server

    .DESCRIPTION
    Start an MCP server over stdio so AI assistants such as Claude can query your certificate inventory.
    Certificate Manager Self-Hosted, Certificate Manager SaaS, and NGTS are supported; the tools offered match the platform of the session.
    All tools are read-only and secrets, private keys, and connection details are never returned.

    This function is intended to be launched by an MCP client, not run interactively.
    See https://venafi.github.io/venafips/mcp/ for production setup including a least privileged account, credential storage, and client configuration.
    It reads JSON-RPC messages from stdin and writes responses to stdout until stdin is closed.
    Diagnostic messages are written to stderr.

    .PARAMETER Connect
    Scriptblock which creates the session, eg. { New-TrustClient -CmsKey $env:CMS_KEY }.
    Any New-TrustClient authentication method can be used as long as it does not prompt for input.
    Methods which can refresh their access token keep working for long sessions; others stop when the token expires.
    If a tool call is rejected with 401 Unauthorized, eg. the token was revoked, Connect is run again and the call retried once.
    Use this instead of calling New-TrustClient before Start-TrustMcpServer.
    Any warnings or other messages it writes are sent to stderr; when launched with pwsh -Command they would otherwise be written to stdout and break the client.

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.

    .INPUTS
    None

    .OUTPUTS
    None

    .EXAMPLE
    Start-TrustMcpServer -Connect { New-TrustClient -Server cm.company.com -ClientId VenafiPS-MCP -Scope @{ certificate = $null; configuration = $null } }

    Start a server for Certificate Manager Self-Hosted using Windows integrated authentication with read only scopes

    .EXAMPLE
    Start-TrustMcpServer -Connect { New-TrustClient -VaultRefreshTokenName 'venafips-mcp' }

    Start a server for Certificate Manager Self-Hosted using a refresh token stored in the VenafiPS SecretManagement vault.
    The new refresh token is saved back to the vault each time the access token is refreshed.

    .EXAMPLE
    Start-TrustMcpServer -Connect { New-TrustClient -CmsKey $env:CMS_KEY }

    Start a server for Certificate Manager SaaS using an API key from an environment variable set by the MCP client

    .EXAMPLE
    Start-TrustMcpServer -Connect { New-TrustClient -NgtsCredential (Get-Secret -Vault VenafiPS -Name 'venafips-mcp') }

    Start a server for NGTS using a service account credential from a SecretManagement vault

    .EXAMPLE
    claude mcp add venafips-cm --scope user -- pwsh -NoLogo -NoProfile -NonInteractive -File ~/.venafips/start-mcp.ps1

    Register a server with Claude Code.
    start-mcp.ps1 imports a pinned version of VenafiPS and calls Start-TrustMcpServer -Connect as in the examples above.
    A launcher script avoids quoting differences between MCP clients and operating systems and keeps settings in one place.

    .EXAMPLE
    {
        "mcpServers": {
            "venafips-cm": {
                "type": "stdio",
                "command": "pwsh",
                "args": ["-NoLogo", "-NoProfile", "-NonInteractive", "-File", "/Users/me/.venafips/start-mcp.ps1"]
            }
        }
    }

    Register a server with an MCP client which uses JSON configuration, eg. Claude Desktop or a .mcp.json file

    .LINK
    https://venafi.github.io/venafips/mcp/

    .LINK
    https://modelcontextprotocol.io
    #>

    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Starts a read-only server, no state is changed')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'TrustClient', Justification = 'Retrieved from the call stack by Get-TrustClient')]
    param (
        [Parameter()]
        [scriptblock] $Connect,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient
    )

    $stderr = [Console]::Error

    if ( $Connect ) {
        $null = Invoke-TrustMcpConnect -Connect $Connect
    }

    $client = Get-TrustClient

    $reconnect = $null
    if ( $Connect ) {
        # the token can be revoked before it expires, eg. another process used the same single use refresh token.
        # connect again and update the existing session in place so the tools and later requests use it.
        $reconnect = {
            param([TrustClient] $Session)
            $stderr.WriteLine('Access token was rejected, connecting again')
            if ( -not (Invoke-TrustMcpConnect -Connect $Connect -Session $Session) ) {
                throw 'Connect did not create a session'
            }
        }
    }

    # anything other than protocol messages on stdout breaks the client
    $ProgressPreference = 'SilentlyContinue'
    $InformationPreference = 'SilentlyContinue'

    $utf8 = [System.Text.UTF8Encoding]::new($false)
    $stdin = [System.IO.StreamReader]::new([Console]::OpenStandardInput(), $utf8)
    $stdout = [System.IO.StreamWriter]::new([Console]::OpenStandardOutput(), $utf8)
    $stdout.AutoFlush = $true

    $tools = @(Get-TrustMcpTool -Platform $client.Platform)
    $stderr.WriteLine(('VenafiPS MCP server started for {0} ({1}) with {2} tools' -f $client.Platform, $client.Server, $tools.Count))

    try {
        while ( $null -ne ($line = $stdin.ReadLine()) ) {

            if ( -not $line.Trim() ) { continue }

            try {
                $message = $line | ConvertFrom-Json -ErrorAction Stop
            }
            catch {
                $response = [ordered]@{
                    jsonrpc = '2.0'
                    id      = $null
                    error   = [ordered]@{ code = -32700; message = 'Parse error' }
                }
                $stdout.WriteLine((ConvertTo-Json -InputObject $response -Depth 5 -Compress))
                continue
            }

            try {
                $response = Invoke-TrustMcpRequest -Message $message -Tool $tools -TrustClient $client -Reconnect $reconnect
            }
            catch {
                $stderr.WriteLine("Error processing $($message.method): $_")
                # notifications never get a response, even on error
                if ( -not ($message.PSObject.Properties.Name -contains 'id') ) { continue }
                $response = [ordered]@{
                    jsonrpc = '2.0'
                    id      = $message.id
                    error   = [ordered]@{ code = -32603; message = "$_" }
                }
            }

            if ( $response ) {
                $stdout.WriteLine((ConvertTo-Json -InputObject $response -Depth 30 -Compress))
            }
        }
    }
    finally {
        $stderr.WriteLine('VenafiPS MCP server stopped')
        $stdout.Dispose()
        $stdin.Dispose()
    }
}
