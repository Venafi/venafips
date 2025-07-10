function Get-VdcCredential {

    <#
    .SYNOPSIS
    Get credential details

    .DESCRIPTION
    Get credential details.
    Object returned will depend on the credential type.

    .PARAMETER Path
    The full path to the credential object

    .PARAMETER IncludeDetail
    Include metadata associated with the credential in addition to the credential itself

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.

    .INPUTS
    Path

    .OUTPUTS
    Password/UsernamePassword Credential - PSCredential
    Certificate Credential - X509Certificate2
    with IncludeDetail - PSCustomObject

    .EXAMPLE
    Get-VdcCredential -Path '\VED\Policy\MySecureCred'
    Get a credential

    .LINK
    https://venafi.github.io/VenafiPS/functions/Get-VdcCredential/

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Get-VdcCredential.ps1

    #>

    [CmdletBinding()]
    [Alias('Get-TppCredential')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'Generating cred from api call response data')]

    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if ( $_ | Test-TppDnPath ) {
                    $true
                }
                else {
                    throw "'$_' is not a valid DN path"
                }
            })]
        [String] $Path,

        [Parameter()]
        [switch] $IncludeDetail,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation

        $params = @{
            Method        = 'Post'
            UriLeaf       = 'Credentials/Retrieve'
            Body          = @{}
        }

    }

    process {

        $params.Body.CredentialPath = $Path
        $response = Invoke-VenafiRestMethod @params

        if ( -not $response ) {
            continue
        }

        switch ($response.Classname) {
            'Password Credential' {
                $pw = $response.Values | Where-Object { $_.Name -eq 'Password' } | Select-Object -ExpandProperty Value
                $cred = New-Object System.Management.Automation.PSCredential((Split-Path -Path $Path -Leaf), ($pw | ConvertTo-SecureString -AsPlainText -Force))
            }

            'Username Password Credential' {
                $un = $response.Values | Where-Object { $_.Name -eq 'Username' } | Select-Object -ExpandProperty Value
                $pw = $response.Values | Where-Object { $_.Name -eq 'Password' } | Select-Object -ExpandProperty Value
                $cred = New-Object System.Management.Automation.PSCredential($un, ($pw | ConvertTo-SecureString -AsPlainText -Force))
            }

            'Certificate Credential' {
                $cert = $response.Values | Where-Object { $_.Name -eq 'Certificate' } | Select-Object -ExpandProperty Value
                $pw = $response.Values | Where-Object { $_.Name -eq 'Password' } | Select-Object -ExpandProperty Value
                $cred = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new([system.convert]::FromBase64String($cert), $pw)
            }

            Default {
                throw "Credential type '$_' is not supported yet.  Submit an enhancement request."
            }
        }

        if ( $IncludeDetail ) {

            $return = $response | Select-Object -Property @{
                'n' = 'Type'
                'e' = { $_.Classname }
            }, *,
            @{
                'n' = 'Credential'
                'e' = { $cred }
            },
            @{
                'n' = 'Contact'
                'e' = { Get-VdcIdentity -Id $_.Contact.PrefixedUniversal }
            } -ExcludeProperty Classname, FriendlyName, Values, Result, Contact

            if ( $response.Classname -eq 'Certificate Credential' ) {
                $return | Add-Member @{
                    'CertificateLinkPath' = ($response.Values | Where-Object { $_.Name -eq 'Certificate DN' }).Value
                    'Password'        = if ($pw) { ConvertTo-SecureString -String $pw -AsPlainText -Force }
                }
            }

            $return
        }
        else {
            $cred
        }
    }
}

