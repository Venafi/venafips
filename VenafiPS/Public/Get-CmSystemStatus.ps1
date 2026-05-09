function Get-CmSystemStatus {
    <#
    .SYNOPSIS
    Get the Certificate Manager, Self-Hosted system status

    .DESCRIPTION
    Returns service module statuses for Trust Protection Platform, Log Server, and Trust Protection Platform services that run on Microsoft Internet Information Services (IIS)

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.

    .INPUTS
    none

    .OUTPUTS
    PSCustomObject

    .EXAMPLE
    Get-CmSystemStatus
    Get the status

    .LINK
    https://venafi.github.io/VenafiPS/functions/Get-CmSystemStatus/

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Get-CmSystemStatus.ps1

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-GET-SystemStatus.php

    #>
    [Alias('Get-VdcSystemStatus')]
    [CmdletBinding()]

    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient
    )

    Write-Warning "Possible bug with Venafi Certificate Manager, Self-Hosted API causing this to fail"


    $params = @{

        Method     = 'Get'
        UriLeaf    = 'SystemStatus/'
    }

    try {
        Invoke-TrustRestMethod @params
    }
    catch {
        Throw ("Getting the system status failed with the following error: {0}.  Ensure you have read rights to the engine root." -f $_)
    }
}

