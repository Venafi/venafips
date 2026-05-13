function Find-CmClient {
    <#
    .SYNOPSIS
    Get information about registered Server Agents or Agentless clients

    .DESCRIPTION
    Get information about registered Server Agent or Agentless clients.

    .PARAMETER ClientType
    The client type.
    Allowed values include VenafiAgent, AgentJuniorMachine, AgentJuniorUser, Portal, Agentless, PreEnrollment, iOS, Android

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.

    .INPUTS
    None

    .OUTPUTS
    PSCustomObject

    .EXAMPLE
    Find-CmClient
    Find all clients

    .EXAMPLE
    Find-CmClient -ClientType Portal
    Find clients with the specific type

    .LINK
    https://venafi.github.io/VenafiPS/functions/Find-CmClient/

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Find-CmClient.ps1

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-GET-ClientDetails.php

    #>

    [Alias('Find-VdcClient')]
    [CmdletBinding()]

    param (
        [Parameter()]
        [ValidateSet('VenafiAgent', 'AgentJuniorMachine', 'AgentJuniorUser', 'Portal', 'Agentless', 'PreEnrollment', 'iOS', 'Android')]
        [String] $ClientType,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient
    )

    begin {

        $params = @{

            Method        = 'Get'
            UriLeaf       = 'Client/Details/'
            Body          = @{ }
        }

        if ( $ClientType ) {
            $params.Body.ClientType = $ClientType
        }

        # if no filters provided, get all
        if ( $params.Body.Count -eq 0 ) {
            $params.Body.LastSeenOnLess = (Get-Date) | ConvertTo-UtcIso8601
        }
    }

    process {
        Invoke-TrustRestMethod @params
    }
}

