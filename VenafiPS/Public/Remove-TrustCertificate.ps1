function Remove-TrustCertificate {
    <#
    .SYNOPSIS
    Remove a certificate

    .DESCRIPTION
    Remove a certificate

    .PARAMETER ID
    Certificate ID of a certificate that has been retired

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.

    .INPUTS
    ID

    .EXAMPLE
    Remove-TrustCertificate -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2'

    Remove a certificate

    .EXAMPLE
    Find-TrustCertificate | Remove-TrustCertificate

    Remove multiple certificates based on a search

    .EXAMPLE
    Remove-TrustCertificate -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -Confirm:$false

    Remove a certificate bypassing the confirmation prompt

    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [Alias('Remove-VcCertificate')]

    param (

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('certificateId')]
        [string] $ID,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient
    )

    begin {
        $allObjects = [System.Collections.Generic.List[object]]::new()
    }

    process {
        $allObjects.Add($ID)
    }

    end {
        # this function is just a placeholder for a standard named function
        # all the logic is in Invoke-TrustCertificateAction
        $allObjects | Invoke-TrustCertificateAction -Delete -Confirm:$ConfirmPreference
    }
}


