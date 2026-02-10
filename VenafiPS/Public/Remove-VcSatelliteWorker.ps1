function Remove-VcSatelliteWorker {
    <#
    .SYNOPSIS
    Remove a vsatellite worker

    .DESCRIPTION
    Remove a vsatellite worker from Certificate Manager, SaaS

    .PARAMETER ID
    Worker ID

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, SaaS key can also provided.

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
        [psobject] $VenafiSession
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation
    }

    process {
        if ( $PSCmdlet.ShouldProcess($ID, "Delete VSatellite Worker") ) {
            $null = Invoke-VenafiRestMethod -Method 'Delete' -UriLeaf "edgeworkers/$ID"
        }
    }

    end {
    }
}

