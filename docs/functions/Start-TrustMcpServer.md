# Start-TrustMcpServer

## SYNOPSIS
Start a Model Context Protocol (MCP) server

## SYNTAX

```
Start-TrustMcpServer [[-Connect] <ScriptBlock>] [[-TrustClient] <TrustClient>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Start an MCP server over stdio so AI assistants such as Claude can query your certificate inventory.
Certificate Manager Self-Hosted, Certificate Manager SaaS, and NGTS are supported; the tools offered match the platform of the session.
All tools are read-only and secrets, private keys, and connection details are never returned.

This function is intended to be launched by an MCP client, not run interactively.
See https://venafi.github.io/venafips/mcp/ for production setup including a least privileged account, credential storage, and client configuration.
It reads JSON-RPC messages from stdin and writes responses to stdout until stdin is closed.
Diagnostic messages are written to stderr.

## EXAMPLES

### EXAMPLE 1
```
Start-TrustMcpServer -Connect { New-TrustClient -Server cm.company.com -ClientId VenafiPS-MCP -Scope @{ certificate = $null; configuration = $null } }
```

Start a server for Certificate Manager Self-Hosted using Windows integrated authentication with read only scopes

### EXAMPLE 2
```
Start-TrustMcpServer -Connect { New-TrustClient -VaultRefreshTokenName 'venafips-mcp' }
```

Start a server for Certificate Manager Self-Hosted using a refresh token stored in the VenafiPS SecretManagement vault.
The new refresh token is saved back to the vault each time the access token is refreshed.

### EXAMPLE 3
```
Start-TrustMcpServer -Connect { New-TrustClient -CmsKey $env:CMS_KEY }
```

Start a server for Certificate Manager SaaS using an API key from an environment variable set by the MCP client

### EXAMPLE 4
```
Start-TrustMcpServer -Connect { New-TrustClient -NgtsCredential (Get-Secret -Vault VenafiPS -Name 'venafips-mcp') }
```

Start a server for NGTS using a service account credential from a SecretManagement vault

### EXAMPLE 5
```
claude mcp add venafips-cm --scope user -- pwsh -NoLogo -NoProfile -NonInteractive -File ~/.venafips/start-mcp.ps1
```

Register a server with Claude Code.
start-mcp.ps1 imports a pinned version of VenafiPS and calls Start-TrustMcpServer -Connect as in the examples above.
A launcher script avoids quoting differences between MCP clients and operating systems and keeps settings in one place.

### EXAMPLE 6
```
{
    "mcpServers": {
        "venafips-cm": {
            "type": "stdio",
            "command": "pwsh",
            "args": ["-NoLogo", "-NoProfile", "-NonInteractive", "-File", "/Users/me/.venafips/start-mcp.ps1"]
        }
    }
}
```

Register a server with an MCP client which uses JSON configuration, eg.
Claude Desktop or a .mcp.json file

## PARAMETERS

### -Connect
Scriptblock which creates the session, eg.
{ New-TrustClient -CmsKey $env:CMS_KEY }.
Any New-TrustClient authentication method can be used as long as it does not prompt for input.
Methods which can refresh their access token keep working for long sessions; others stop when the token expires.
If a tool call is rejected with 401 Unauthorized, eg.
the token was revoked, Connect is run again and the call retried once.
Use this instead of calling New-TrustClient before Start-TrustMcpServer.
Any warnings or other messages it writes are sent to stderr; when launched with pwsh -Command they would otherwise be written to stdout and break the client.

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TrustClient
Authentication for the function.
The value defaults to the script session object $TrustClient created by New-TrustClient.

```yaml
Type: TrustClient
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
## OUTPUTS

### None
## NOTES

## RELATED LINKS

[https://venafi.github.io/venafips/mcp/](https://venafi.github.io/venafips/mcp/)

[https://modelcontextprotocol.io](https://modelcontextprotocol.io)

