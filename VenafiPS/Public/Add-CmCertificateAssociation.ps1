function Add-CmCertificateAssociation {
    <#
    .SYNOPSIS
    Add certificate association

    .DESCRIPTION
    Associates one or more Application objects to an existing certificate.
    Optionally, you can push the certificate once the association is complete.

    .PARAMETER InputObject
    CmObject which represents a certificate

    .PARAMETER CertificatePath
    Path to the certificate.  Required if InputObject not provided.

    .PARAMETER ApplicationPath
    List of application object paths to associate

    .PARAMETER PushCertificate
    Push the certificate after associating it to the Application objects.
    This will only be successful if the certificate management type is Provisioning and is not disabled, in error, or a push is already in process.

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.

    .INPUTS
    Path

    .OUTPUTS
    None

    .EXAMPLE
    Add-CmCertificateAssociation -CertificatePath '\ved\policy\my cert' -ApplicationPath '\ved\policy\my capi'
    Add a single application object association

    .EXAMPLE
    Add-CmCertificateAssociation -Path '\ved\policy\my cert' -ApplicationPath '\ved\policy\my capi' -PushCertificate
    Add the association and push the certificate

    .LINK
    https://venafi.github.io/VenafiPS/functions/Add-CmCertificateAssociation/

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Add-CmCertificateAssociation.ps1

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/API_Reference/r-SDK-POST-Certificates-Associate.php

    .NOTES
    You must have:
    - Write permission to the Certificate object.
    - Write or Associate and Delete permission to Application objects that are associated with the certificate

    #>

    [Alias('Add-VdcCertificateAssociation')]
    [CmdletBinding(SupportsShouldProcess)]

    param (

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if ( $_ | Test-CmDnPath ) {
                    $true
                } else {
                    throw "'$_' is not a valid DN path"
                }
            })]
        [Alias('DN', 'CertificateDN', 'Path')]
        [String] $CertificatePath,

        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if ( $_ | Test-CmDnPath ) {
                    $true
                } else {
                    throw "'$_' is not a valid DN path"
                }
            })]
        [String[]] $ApplicationPath,

        [Parameter()]
        [Alias('ProvisionCertificate')]
        [switch] $PushCertificate,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient
    )

    begin {

        $params = @{
            Method     = 'Post'
            UriLeaf    = 'Certificates/Associate'
            Body       = @{
                CertificateDN = ''
                ApplicationDN = ''
            }
        }

        if ( $PSBoundParameters.ContainsKey('PushCertificate') ) {
            $params.Body.Add('PushToNew', 'true')
        }
    }

    process {

        $params.Body.CertificateDN = $CertificatePath
        $params.Body.ApplicationDN = @($ApplicationPath)

        if ( $PSCmdlet.ShouldProcess($CertificatePath, 'Add association') ) {
            $null = Invoke-TrustRestMethod @params
        }
    }
}


