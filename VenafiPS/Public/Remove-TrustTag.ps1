function Remove-TrustTag {
    <#
    .SYNOPSIS
    Remove a tag

    .DESCRIPTION
    Remove a tag from Certificate Manager, SaaS

    .PARAMETER ID
    Tag ID/name

    .PARAMETER ThrottleLimit
    Limit the number of threads when running in parallel; the default is 100.
    Setting the value to 1 will disable multithreading.
    On PS v5 the ThreadJob module is required.  If not found, multithreading will be disabled.

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.

    .INPUTS
    Name

    .EXAMPLE
    Remove-TrustTag -ID 'MyTag'
    Remove a tag

    .EXAMPLE
    Remove-TrustTag -ID 'MyTag' -Confirm:$false
    Remove a tag bypassing the confirmation prompt
    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [Alias('Remove-VcTag')]

    param (

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('tagId')]
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
        if ( $PSCmdlet.ShouldProcess($ID, "Delete Tag") ) {
            $allObjects.Add($ID)
        }
    }

    end {
        Invoke-TrustParallel -InputObject $allObjects -ScriptBlock {
            $null = Invoke-TrustRestMethod -Method 'Delete' -UriLeaf "tags/$PSItem"
        } -ThrottleLimit $ThrottleLimit -TrustClient $TrustClient
    }
}


