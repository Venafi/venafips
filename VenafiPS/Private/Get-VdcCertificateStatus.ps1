# PowerShell implementation of X509StatusHelper.GetStatus() logic

function Get-VdcCertificateStatus {
    <#
    .SYNOPSIS
    Calculate the Status field for a certificate, similar to what's shown on the Certificate Summary tab.

    .DESCRIPTION
    This function replicates the logic from X509StatusHelper.GetStatus() to determine the certificate status.
    It checks InError, Status attribute, workflow tickets, revocation status, disabled state,
    consumer errors, and certificate expiration.

    .PARAMETER Certificate
    A certificate object from Get-VdcCertificate

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.

    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$Certificate,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession = (Get-VenafiSession)

    )

    process {
        # Initialize status
        $statusSummary = 'Ok'  # Ok, Warning, Error
        $statusText = ''

        $attribs = Get-VdcAttribute -Path $Certificate.DN -Attribute 'Disabled', 'Ticket DN' -VenafiSession $VenafiSession
        $certAttributes = @{
            'In Error'  = $Certificate.ProcessingDetails.InError
            'Status'    = $Certificate.ProcessingDetails.Status
            'Disabled'  = $attribs.Disabled -eq 1
            'Ticket DN' = $attribs.'Ticket DN'
        }

        # Check InError attribute
        $inError = $certAttributes.'In Error'
        if ($inError) {
            $statusSummary = 'Error'
        }

        # Check Status attribute
        $statusAttr = $certAttributes.'Status'
        if ($statusAttr) {
            $statusText = $statusAttr
            if (-not $inError) {
                $statusSummary = 'Warning'
            }
        }
        else {
            if (-not $inError) {
                $statusText = 'OK'
                $statusSummary = 'Ok'
            }
        }

        # Check for pending workflow (Ticket DN)
        $ticketDN = $certAttributes.'Ticket DN'
        if ($ticketDN) {
            $statusSummary = 'Warning'
            $statusText = 'Pending workflow resolution'
        }

        # Check revocation status (simplified - full implementation would query SecretStore)
        # This is a simplified check based on available certificate data
        $stage = $certAttributes.'Stage'
        if (-not $stage -and -not $ticketDN) {
            # Could add revocation checking here if RevocationState data is available
            # In the C# code, this queries CertificateSecretStore for:
            # - RevocationStatus.Confirmed
            # - RevocationStatus.Complete
            # - RevocationStatus.DiscoveredRevoked
            # - RevocationStatus.Failed
            # - RevocationStatus.Pending
        }

        # Check Disabled attribute
        # $disabled = $certAttributes.'Disabled'
        if ($certAttributes.'Disabled') {
            if ($statusText) {
                $statusText += ' (Processing disabled)'
            }
            else {
                $statusText = 'Processing disabled'
            }
            $statusSummary = 'Warning'
        }

        # Check consumer (application) errors
        if ($statusSummary -eq 'Ok' -and $Certificate.Consumers) {
            $consumerErrors = 0
            $consumerWarnings = 0
            $consumerDisabled = 0
            $consumerOk = 0

            $allAttribs = $Certificate.Consumers | Get-VdcAttribute -Attribute @('In Error', 'Status', 'Disabled') -VenafiSession $VenafiSession
            foreach ($consumerAttrs in $allAttribs) {
                try {

                    if ($consumerAttrs.'Disabled' -eq 1) {
                        $consumerDisabled++
                        $statusSummary = 'Warning'
                        continue
                    }

                    if ($consumerAttrs.'In Error' -eq 1) {
                        $consumerErrors++
                        $statusSummary = 'Error'
                    }
                    elseif ($consumerAttrs.'Status') {
                        $consumerWarnings++
                        $statusSummary = 'Warning'
                    }
                    else {
                        $consumerOk++
                    }
                }
                catch {
                    # Consumer may not be accessible
                    Write-Verbose "Could not read consumer: $consumerPath"
                }
            }

            if ($statusSummary -ne 'Ok') {
                $statusText = "Certificate Ok; Application errors: $consumerErrors, caution: $consumerWarnings, disabled: $consumerDisabled, Ok: $consumerOk"
            }
        }

        # Check certificate expiration
        if ($statusSummary -eq 'Ok' -and $Certificate.CertificateDetails.ValidTo) {
            $validTo = [DateTime]$Certificate.CertificateDetails.ValidTo
            if ($validTo -lt (Get-Date)) {
                $statusSummary = 'Error'
                $statusText = 'Certificate expired'
            }
        }

        # Return results
        @{
            Status     = $statusSummary
            StatusText = $statusText
        }
    }
}
