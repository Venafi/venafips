function Remove-VcConnector {
    <#
    .SYNOPSIS
    Remove a connector

    .DESCRIPTION
    Remove a connector from Certificate Manager, SaaS

    .PARAMETER ID
    Connector ID, this is the guid/uuid

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, SaaS key can also provided.

    .INPUTS
    ID

    .EXAMPLE
    Remove-VcConnector -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2'
    Remove a connector

    .EXAMPLE
    Remove-VcConnector -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -Confirm:$false
    Remove a connector bypassing the confirmation prompt
    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]

    param (

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('connectorId')]
        [ValidateScript(
            {
                if ( -not (Test-IsGuid -InputObject $_ ) ) {
                    throw "$_ is not a valid connector id format"
                }
                $true
            }
        )]
        [string] $ID,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation
    }

    process {
        if ( $PSCmdlet.ShouldProcess($ID, "Delete connector") ) {
            $null = Invoke-VenafiRestMethod -Method 'Delete' -UriLeaf "plugins/$ID"
        }
    }
}


