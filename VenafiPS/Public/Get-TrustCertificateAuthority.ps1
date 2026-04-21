function Get-TrustCertificateAuthority {
    <#
    .SYNOPSIS
    Get certificate authority info

    .DESCRIPTION
    Get info on certificate authorities.
    Retrieve info on 1 or all.

    .PARAMETER CertificateAuthority
    Certificate authority name or guid.

    .PARAMETER All
    Get all certificate authorities

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.

    .INPUTS
    CertificateAuthority

    .OUTPUTS
    PSCustomObject

    .EXAMPLE
    Get-TrustCertificateAuthority -CertificateAuthority 'MyCA'

    Get info for a certificate authority by name

    .EXAMPLE
    Get-TrustCertificateAuthority -CertificateAuthority 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2'

    Get info for a certificate authority by id

    .EXAMPLE
    Get-TrustCertificateAuthority -All

    Get info for all certificate authorities
    #>

    [CmdletBinding(DefaultParameterSetName = 'ID')]
    [Alias('Get-VcCertificateAuthority')]

    param (

        [Parameter(Mandatory, ParameterSetName = 'ID', ValueFromPipelineByPropertyName, Position = 0)]
        [Alias('certificateAuthorityId')]
        [string] $CertificateAuthority,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch] $All,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient
    )

    process {

        $caTypeParams = @{
            UriLeaf = 'certificateauthorities'
            Body    = @{
                issuanceCertificateType   = 'ALL'
                includeSystemGenerated    = $true
                includeVSatPluginRequired = $true
            }
        }
        $caTypes = Invoke-TrustRestMethod @caTypeParams

        $allCA = foreach ($caType in $caTypes.certificateAuthorities.certificateAuthority) {
            $thisCAs = Invoke-TrustRestMethod -UriLeaf ('certificateauthorities/{0}/accounts' -f $caType) -Body @{'includeOptionsDetails' = $true }

            foreach ($thisCA in $thisCAs.accounts) {

                $thisCA.account | Select-Object *,
                @{'n' = 'productOptions'; 'e' = { $thisCA.productOptions } },
                @{'n' = 'importOptions'; 'e' = { $thisCA.importOptions } }
            }
        }

        $out = if ( $PSCmdlet.ParameterSetName -eq 'All' ) {
            $allCA
        }
        else {
            $allCA | Where-Object { $CertificateAuthority -in $_.id, $_.key }
        }

        $out | Select-Object @{
            'n' = 'certificateAuthorityId'
            'e' = { $_.id }
        },
        @{
            'n' = 'name'
            'e' = { $_.key }
        },
        @{
            'n' = 'type'
            'e' = { $_.certificateAuthority }
        },
        * -ExcludeProperty id, key, certificateAuthority, accountDetails
    }
}

