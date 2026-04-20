function Remove-VcMachine {
    <#
    .SYNOPSIS
    Remove a machine

    .DESCRIPTION
    Remove a machine from Certificate Manager, SaaS

    .PARAMETER ID
    Machine ID, this is the guid/uuid

    .PARAMETER ThrottleLimit
    Limit the number of threads when running in parallel; the default is 100.
    Setting the value to 1 will disable multithreading.
    On PS v5 the ThreadJob module is required.  If not found, multithreading will be disabled.

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.

    .INPUTS
    ID

    .EXAMPLE
    Remove-VcMachine -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2'
    Remove a machine

    .EXAMPLE
    Remove-VcMachine -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -Confirm:$false
    Remove a machine bypassing the confirmation prompt
    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]

    param (

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('machineId')]
        [string] $ID,

        [Parameter()]
        [int32] $ThrottleLimit = 100,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient = (Get-TrustClient)
    )

    begin {
        $allObjects = [System.Collections.Generic.List[object]]::new()
    }

    process {
        if ( $PSCmdlet.ShouldProcess($ID, "Delete machine") ) {
            $allObjects.Add($ID)
        }
    }

    end {
        Invoke-TrustParallel -InputObject $allObjects -ScriptBlock {
            $null = Invoke-TrustRestMethod -Method 'Delete' -UriLeaf "machines/$PSItem"
        } -ThrottleLimit $ThrottleLimit -TrustClient $TrustClient
    }
}


