# MCP Server

`Start-TrustMcpServer` lets AI assistants such as Claude Code, Claude Desktop, VS Code, and Cursor answer questions about your certificate inventory using the [Model Context Protocol (MCP)](https://modelcontextprotocol.io), eg. *which certificates expire this month* or *why did this certificate fail to renew*.  Self-Hosted, SaaS, and NGTS are supported.

- **Read-only.**  Tools only read data; nothing is created, changed, or deleted.
- **Secrets are kept out.**  Tools never retrieve private keys or credentials, and fields holding passwords, tokens, and keys are redacted.  See [Data protection](#data-protection) for what is and isn't sent.
- **Your permissions apply.**  The assistant can only see what the account it signs in with can see.

> **⚠️ Warning:**  Tool results, eg. certificate names, SANs, and policy paths, are sent to the AI model used by your MCP client.  Check this is allowed by your organization's policies before connecting a production environment.

> **Preview:**  The MCP server is in preview.  Tool names and output may change in future releases.

## Setup

### 1. Install VenafiPS

Use Windows PowerShell 5.1 or PowerShell 7, which is recommended and required on macOS and Linux.

```powershell
Install-Module VenafiPS -Scope CurrentUser
```

### 2. Create a launcher script

Save this as `start-mcp.ps1`, eg. in `~/.venafips`, and change the `New-TrustClient` line to match how you connect.

#### Self-Hosted

```powershell
$ErrorActionPreference = 'Stop'
Import-Module VenafiPS

Start-TrustMcpServer -Connect {
    $password = ConvertTo-SecureString $env:CM_PASSWORD -AsPlainText -Force
    $params = @{
        Server     = 'cm.company.com'
        ClientId   = 'VenafiPS-MCP'
        Scope      = @{ certificate = $null; configuration = $null }
        Credential = [pscredential]::new($env:CM_USERNAME, $password)
    }
    New-TrustClient @params
}
```

This gets an OAuth token for the `VenafiPS-MCP` API integration with read-only scopes, and refreshes it for as long as the server runs.  To use Windows integrated authentication instead, leave out `Credential`.  See [Production checklist](#production-checklist) for other options.

#### SaaS

```powershell
$ErrorActionPreference = 'Stop'
Import-Module VenafiPS

Start-TrustMcpServer -Connect { New-TrustClient -CmsKey $env:CMS_KEY }
```

Add `-CmsRegion`, eg. `-CmsRegion eu`, if you are not in the US region.

#### NGTS

```powershell
$ErrorActionPreference = 'Stop'
Import-Module VenafiPS

Start-TrustMcpServer -Connect {
    $secret = ConvertTo-SecureString $env:NGTS_CLIENT_SECRET -AsPlainText -Force
    New-TrustClient -NgtsCredential ([pscredential]::new($env:NGTS_CLIENT_ID, $secret))
}
```

`-Connect` accepts any [New-TrustClient](functions/New-TrustClient.md) options as long as they don't prompt for input, since the server runs in the background.

### 3. Add it to your MCP client

#### Claude Code

```shell
claude mcp add venafips --scope user -- pwsh -NoProfile -NonInteractive -File ~/.venafips/start-mcp.ps1
```

To pass environment variables, add them before `--`, eg. `-e CM_USERNAME=<username> -e CM_PASSWORD=<password>` for Self-Hosted or `-e CMS_KEY=<your key>` for SaaS.

#### Other clients

Most clients use JSON like this; check your client's documentation for the file location.  Use the full path to the script.

```json
{
  "mcpServers": {
    "venafips": {
      "command": "pwsh",
      "args": ["-NoProfile", "-NonInteractive", "-File", "/Users/me/.venafips/start-mcp.ps1"],
      "env": { "CMS_KEY": "<your key>" }
    }
  }
}
```

Use `powershell.exe` instead of `pwsh` for Windows PowerShell 5.1.  `-NoProfile` keeps your profile from interfering with the server and `-NonInteractive` makes it fail rather than hang if anything prompts.

### 4. Try it

Ask your assistant *"What VenafiPS server am I connected to?"*.  It should use the `whoami` tool and reply with your platform and server.  If not, see [Troubleshooting](#troubleshooting).

## Data protection

Every tool result is sent to the AI model used by your MCP client.  The server limits what it receives as follows.

### What the server does

- **Read-only tools.**  Every tool only reads data and is marked read-only to the client.  Nothing can be created, changed, or deleted.
- **No calls which return secrets.**  No tool retrieves a private key, a credential, or a vault object.  `get_certificate_chain` builds the chain from certificate details and the CA certificates published at each certificate's Authority Information Access url, rather than retrieving the certificate from Certificate Manager.
- **Secret fields are redacted.**  Before a result is returned, any field whose name contains password, passphrase, secret, private key, API key, token, PKCS #12, PFX, credential, connection details, or pairing code is replaced with `[redacted]`, at any depth.  Names which only describe a secret, eg. `tokenType`, `apiKeyId`, or `OAuth Token Scope`, are kept.  Credential and secure string values are always redacted.
- **Fields are removed per tool.**  Machine connection details, VSatellite encryption keys, and connector manifests are not returned.  Permissions are returned as a list of names, eg. `privateKeyRead`, rather than the underlying fields.
- **Error details are limited.**  A failed API call returns only its status, eg. `404 (Not Found)`, not the response.  On Self-Hosted, a `403` is replaced by the token scope the function needs.  Tokens are sent in headers, so they never appear in error text.
- **Other output is discarded.**  Verbose, debug, warning, and information output, which can include full API requests and responses, is never sent to the client.
- **Results are size limited.**  Strings over 2,000 characters, lists over 200 items, and objects nested more than 8 levels are truncated.  Most tools also return 25 results by default, up to 200.
- **Your permissions and scopes apply.**  The server can only see what the account it signs in with can see, so the account's permissions are how you limit it to specific policy folders, applications, or teams.  See [Tools](#tools) for the Self-Hosted scope each tool needs.

### What the AI model receives

Certificate metadata such as names, common names, SANs, serial numbers, thumbprints, validity, and key details; issuer and subject DNs; hostnames and IP addresses of machines and installations; policy folder paths and attribute values; user and group names, email addresses, and directory DNs; and event and activity log entries, with Self-Hosted event data decoded.  Treat this as you would an inventory export.

### Limitations

- **Redaction is by field name.**  A secret stored in a general purpose field isn't recognized, eg. an Adaptable application or CA `Text Field`, `Option`, or `Driver Arguments` value, a custom field, or a value in event data.  `get_attributes` returns these fields as they are.  Don't store secrets in them; use a credential object.
- **Some error text is returned as it is**: a `403` from SaaS or NGTS includes the API's message, and errors raised by VenafiPS or the tools themselves, eg. an invalid attribute name or an AIA url which couldn't be downloaded, are returned as written.
- **There is no masking or folder limit in the server.**  Use the account's permissions to limit what it can see.
- **The server doesn't keep an audit log** of tool calls or of what was returned.  Your MCP client may log them.

## Production checklist

- **Use a dedicated account with read-only access.**
    - Self-Hosted: create an API integration, eg. `VenafiPS-MCP`, which allows only the **Certificate** and **Configuration** scopes with no privilege restrictions, and give the account View and Read permission on just the policy folders it needs.  Add the **Security** scope, also with no privilege restrictions, only if you want `get_permissions`; it lets the account read the permissions of objects it can see.
    - SaaS and NGTS: use a service account, or a dedicated user's API key, with the least privileged role that can see the certificates you want to query.
- **Sign in without prompts, with a method that refreshes.**  The server runs as long as your MCP client.
    - Self-Hosted: a username and password (`-Server -ClientId -Scope -Credential`), Windows integrated (the same without `-Credential`), a client certificate (`-Certificate`), or a refresh token stored in a vault (`-VaultRefreshTokenName`) all keep working.  Avoid `-AccessToken`, which stops when the token expires, and `-RefreshToken` from a file or variable, which only works once.
    - SaaS: API key.  NGTS: service account.
- **Keep secrets out of client configuration.**  Environment variables in a client's configuration are stored in plain text.  Prefer a method with no secret, eg. Windows integrated, or read the secret in the launcher from a [SecretManagement](index.md#tokenkey-secret-storage) vault, eg. `-VaultCmsKeyName`, or from your secret manager.
- **Pin the version.**  Use `Import-Module VenafiPS -RequiredVersion x.y.z` so updates don't change behavior until you've tested them.  Start a new client session after upgrading.
- **Know how to revoke access.**  Revoke the integration's grant (`Revoke-CmGrant`), API key, or service account.

## Tools

| Tool | Self-Hosted | SaaS / NGTS | Self-Hosted scope | Description |
|---|:-:|:-:|---|---|
| `whoami` | ✓ | ✓ | `configuration` | Platform, server, and token expiration of the current connection |
| `find_certificates` | ✓ | ✓ | `certificate` | Search certificates, eg. by name, CN, SAN, issuer, expiration, or error state.  On Self-Hosted also by management type, key, signature algorithm, wildcard, or self-signed |
| `get_certificate` | ✓ | ✓ | `certificate` | Full details for a single certificate, and on Self-Hosted its previous versions |
| `certificate_expiry_summary` | ✓ | ✓ | `certificate` | Counts of certificates expired or expiring in 7, 30, and 90 days |
| `certificate_inventory_summary` | ✓ |  | `certificate` | Counts by folder, issuer, key, expiry, class, management type, and lifetime, readiness for shorter maximum validity (CA/B Forum SC-081), and crypto posture, in one call |
| `find_certificates_by_ca` | ✓ | ✓ | `certificate` | Certificates issued by, or chaining to, a CA, eg. when a CA is distrusted |
| `search_logs` | ✓ | ✓ | `any` | Event or activity log, most recent first.  On Self-Hosted, event data is decoded and can be searched, and event ids are matched by the server across the whole time range |
| `get_identity` | ✓ | ✓ | `configuration` | Resolve users, groups, and teams, eg. contacts and owners |
| `browse_policy_tree` | ✓ |  | `configuration` | List folders and objects in the policy tree |
| `get_attributes` | ✓ |  | `configuration` | Object and policy attributes, including which folders use a CA template |
| `list_ca_templates` | ✓ |  | `configuration` | CA templates and Adaptable CA driver scripts |
| `find_workflow_tickets` | ✓ |  | `certificate` | Pending approvals and their approvers |
| `get_certificate_consumers` | ✓ |  | `configuration` | Where a certificate is installed |
| `get_certificate_chain` | ✓ |  | `certificate` | A certificate and its intermediate and root CAs, downloaded from the certificates' AIA urls |
| `find_objects_by_attribute` | ✓ |  | `configuration` | Objects with an attribute value set on them, eg. apps using a PowerShell script |
| `list_class_attributes` | ✓ |  | `any` | Attribute names and custom fields for a class |
| `get_system_status` | ✓ |  | `configuration` | Service status and processing engine folder assignments |
| `get_permissions` | ✓ |  | `security` | Who has which permissions on an object |
| `find_machines` |  | ✓ |  | Machines where certificates are provisioned, without connection details |
| `list_applications` |  | ✓ |  | Applications and their renewal configuration |
| `find_certificate_requests` |  | ✓ |  | Certificate requests, eg. failed or pending approval |
| `list_vsatellites` |  | ✓ |  | VSatellite and worker status |
| `list_connectors` |  | ✓ |  | Connectors and whether they are global or custom |
| `find_machine_identities` |  | ✓ |  | Where a certificate is installed, eg. a virtual server or site, or what a machine hosts |
| `list_certificate_authorities` |  | ✓ |  | Certificate authority accounts and their product options |
| `list_issuing_templates` |  | ✓ |  | Issuing templates, their CA, and the keys, subjects, and SANs they allow |

Self-Hosted scopes come from the functions each tool calls, and are also in each tool's description so your assistant can explain a scope error.  `any` works with any scope.  The read-only **Certificate** and **Configuration** scopes cover every tool except `get_permissions`, which needs **Security**.

`get_certificate_chain`, and `find_certificates_by_ca` on Self-Hosted, download each issuing CA certificate from the Authority Information Access (AIA) url in the certificate below it, so the computer running the MCP server needs to reach those urls, eg. your internal PKI or `cacerts.digicert.com`.  If it can't, the tools return what they could follow with a warning.

## Troubleshooting

Errors are written to stderr, which your MCP client shows in its logs, eg. `claude --debug`.  To see them directly, run the launcher yourself with a request piped in; it should print one line of JSON and a `VenafiPS MCP server started` message:

```powershell
'{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18"}}' | pwsh -NoProfile -NonInteractive -File ~/.venafips/start-mcp.ps1
```

| Problem | Fix |
|---|---|
| Server won't start | Run the command above to see the error.  Check VenafiPS is installed for the same user that runs the client. |
| Hangs on startup | Something is prompting, eg. `Get-Credential` or a vault password.  Provide every value non-interactively. |
| `401 (Unauthorized)` | The token or key was revoked or expired.  A Self-Hosted refresh token may have already been used; sign in again. |
| `cannot be automatically refreshed` | The sign-in method can't refresh, eg. `-AccessToken`.  Restart the server or use a method that refreshes. |
| Protocol or JSON errors | Something wrote to the console.  Use `-NoProfile` and sign in inside `-Connect`. |
| Tool descriptions are out of date after upgrading | Start a new client session. |
