function Split-CertificateData {

    <#
    .SYNOPSIS
        Convert PEM data into its cert, key, and chain parts
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('CertificateData')]
        [String] $InputObject,

        [Parameter()]
        [switch] $NoHeaders
    )

    begin {
        $allCerts = [System.Collections.Generic.List[hashtable]]::new()
    }

    process {
        if ( $InputObject -match '-----BEGIN' ) {
            # we got base64 surrounded by headers and footers
            $pemLines = $InputObject.Split("`n")
        }
        else {
            # we got just base64 data
            $pemLines = [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($InputObject)).Split("`n")
        }

        $certPem = @()

        for ($i = 0; $i -lt $pemLines.Count; $i++) {
            if ($pemLines[$i].Contains('-----BEGIN')) {
                $iStart = if ( $NoHeaders ) { $i + 1 } else { $i }
                continue
            }
            if ($pemLines[$i].Contains('-----END')) {

                $iEnd = if ( $NoHeaders ) { $i - 1 } else { $i }
                $thisPemLines = $pemLines[$iStart..$iEnd]

                if ( $pemLines[$i].Contains('KEY-----')) {
                    $keyPem = ($thisPemLines -join "`n") -replace "`r"
                }
                else {
                    $certPem += ($thisPemLines -join "`n") -replace "`r"
                }
                continue
            }
        }

        $allCerts.Add(
            @{
                CertPem  = $certPem[0]
                KeyPem   = $keyPem
                ChainPem = $certPem[1..($certPem.Count - 1)]
            }
        )
    }

    end {
        $allCerts
    }
}
