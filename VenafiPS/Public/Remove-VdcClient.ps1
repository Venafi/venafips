function Remove-VdcClient {
    <#
    .SYNOPSIS
        Remove registered client agents

    .DESCRIPTION
        Remove registered client agents.
        Provide an array of client IDs to remove a large list at once.

    .PARAMETER ClientId
        Unique id for one or more clients

    .PARAMETER RemoveAssociatedDevice
        For a registered Agent, delete the associated Device objects, and only certificates that belong to the associated device.
        Delete any related Discovery information. Preserve unrelated device, certificate, and Discovery information in other locations of the Policy tree and Secret Store.

    .PARAMETER VenafiSession
        Authentication for the function.
        The value defaults to the script session object $VenafiSession created by New-VenafiSession.
        A Certificate Manager, Self-Hosted token can also be provided.
        If providing a Certificate Manager, Self-Hosted token, an environment variable named VDC_SERVER must also be set.

    .INPUTS
        ClientId

    .OUTPUTS
        None

    .EXAMPLE
        Remove-VdcClient -ClientId 1234, 5678
        Remove clients

    .EXAMPLE
        Remove-VdcClient -ClientId 1234, 5678 -RemoveAssociatedDevice
        Remove clients and associated devices

    .LINK
        https://venafi.github.io/VenafiPS/functions/Remove-VdcClient/

    .LINK
        https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Remove-VdcClient.ps1

    .LINK
        https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-ClientDelete.php

    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [Alias('Remove-TppClient')]

    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [String[]] $ClientID,

        [Parameter()]
        [Alias('RemoveAssociatedDevices')]
        [switch] $RemoveAssociatedDevice,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation

        $params = @{

            Method        = 'Post'
            UriLeaf       = 'Client/Delete'
            Body          = @{}
        }
    }

    process {

        if ( $PSCmdlet.ShouldProcess('Remove {0} clients' -f $ClientID.Count) ) {
            # 5000 clients at a time is an api limitation
            for ($i = 0; $i -lt $ClientID.Count; $i += 5000) {

                $clientIds = $ClientID[$i..($i + 4999)] | ForEach-Object {
                    @{ 'ClientId' = $_ }
                }

                $params.Body.Clients = [array] $clientIds
                $params.Body.DeleteAssociatedDevices = $RemoveAssociatedDevice.IsPresent.ToString().ToLower()

                $response = Invoke-VenafiRestMethod @params

                if ( $response.Errors ) {
                    Write-Error ($response.Errors | ConvertTo-Json)
                }
            }
        }
    }
}

