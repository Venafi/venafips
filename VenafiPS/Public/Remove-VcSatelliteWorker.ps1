function Remove-VcSatelliteWorker {
    <#
    .SYNOPSIS
    Remove a vsatellite worker

    .DESCRIPTION
    Remove a vsatellite worker from Certificate Manager, SaaS

    .PARAMETER ID
    Worker ID

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.

    .INPUTS
    ID

    .EXAMPLE
    Remove-VcSatelliteWorker -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2'

    Remove a worker

    .EXAMPLE
    Remove-VcSatelliteWorker -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -Confirm:$false

    Remove a worker bypassing the confirmation prompt

    .EXAMPLE
    Get-VcSatelliteWorker -VSatellite 'My vsat1' | Remove-VcSatelliteWorker

    Remove all workers associated with a specific vsatellite
    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]

    param (

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('vsatelliteWorkerId')]
        [guid] $ID,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient
    )

    begin {
    }

    process {
        if ( $PSCmdlet.ShouldProcess($ID, "Delete VSatellite Worker") ) {
            $null = Invoke-TrustRestMethod -Method 'Delete' -UriLeaf "edgeworkers/$ID"
        }
    }

    end {
    }
}

