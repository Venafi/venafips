function Remove-VcCertificate {
    <#
    .SYNOPSIS
    Remove a certificate

    .DESCRIPTION
    Remove a certificate

    .PARAMETER ID
    Certificate ID of a certificate that has been retired

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, SaaS key can also provided.

    .INPUTS
    ID

    .EXAMPLE
    Remove-VcCertificate -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2'

    Remove a certificate

    .EXAMPLE
    Find-VcCertificate | Remove-VcCertificate

    Remove multiple certificates based on a search

    .EXAMPLE
    Remove-VcCertificate -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -Confirm:$false

    Remove a certificate bypassing the confirmation prompt

    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]

    param (

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('certificateId')]
        [string] $ID,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation
        $allObjects = [System.Collections.Generic.List[object]]::new()
    }

    process {
        $allObjects.Add($ID)
    }

    end {
        # this function is just a placeholder for a standard named function
        # all the logic is in Invoke-VcCertificateAction
        $allObjects | Invoke-VcCertificateAction -Delete -Confirm:$ConfirmPreference
    }
}


