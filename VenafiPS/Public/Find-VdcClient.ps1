function Find-VdcClient {
    <#
    .SYNOPSIS
    Get information about registered Server Agents or Agentless clients

    .DESCRIPTION
    Get information about registered Server Agent or Agentless clients.

    .PARAMETER ClientType
    The client type.
    Allowed values include VenafiAgent, AgentJuniorMachine, AgentJuniorUser, Portal, Agentless, PreEnrollment, iOS, Android

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.

    .INPUTS
    None

    .OUTPUTS
    PSCustomObject

    .EXAMPLE
    Find-VdcClient
    Find all clients

    .EXAMPLE
    Find-VdcClient -ClientType Portal
    Find clients with the specific type

    .LINK
    https://venafi.github.io/VenafiPS/functions/Find-VdcClient/

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Find-VdcClient.ps1

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-GET-ClientDetails.php

    #>

    [CmdletBinding()]
    [Alias('Find-TppClient')]

    param (
        [Parameter()]
        [ValidateSet('VenafiAgent', 'AgentJuniorMachine', 'AgentJuniorUser', 'Portal', 'Agentless', 'PreEnrollment', 'iOS', 'Android')]
        [String] $ClientType,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation

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
        Invoke-VenafiRestMethod @params
    }
}

