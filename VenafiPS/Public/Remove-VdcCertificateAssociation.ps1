function Remove-VdcCertificateAssociation {
    <#
    .SYNOPSIS
    Remove certificate associations

    .DESCRIPTION
    Dissociates one or more Application objects from an existing certificate.
    Optionally, you can remove the application objects and corresponding orphaned device objects that no longer have any applications

    .PARAMETER Path
    Path to the certificate

    .PARAMETER ApplicationPath
    List of application object paths to dissociate

    .PARAMETER OrphanCleanup
    Delete the Application object after dissociating it. Only delete the corresponding Device DN when it has no child objects.
    Otherwise retain the Device path and its children.

    .PARAMETER All
    Remove all associated application objects

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, Self-Hosted token can also provided.
    If providing a Certificate Manager, Self-Hosted token, an environment variable named VDC_SERVER must also be set.

    .INPUTS
    Path

    .OUTPUTS
    None

    .EXAMPLE
    Remove-VdcCertificateAssociation -Path '\ved\policy\my cert' -ApplicationPath '\ved\policy\my capi'
    Remove a single application object association

    .EXAMPLE
    Remove-VdcCertificateAssociation -Path '\ved\policy\my cert' -ApplicationPath '\ved\policy\my capi' -OrphanCleanup
    Disassociate and delete the application object

    .EXAMPLE
    Remove-VdcCertificateAssociation -Path '\ved\policy\my cert' -RemoveAll
    Remove all certificate associations

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Certificates-Dissociate.php

    .NOTES
    You must have:
    - Write permission to the Certificate object.
    - Write or Associate permission to Application objects that are associated with the certificate
    - Delete permission to Application and device objects when specifying -OrphanCleanup

    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High', DefaultParameterSetName = 'RemoveOne')]
    param (

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if ( $_ | Test-TppDnPath ) {
                    $true
                }
                else {
                    throw "'$_' is not a valid path"
                }
            })]
        [Alias('DN', 'CertificateDN')]
        [String] $Path,

        [Parameter(Mandatory, ParameterSetName = 'RemoveOne')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if ( $_ | Test-TppDnPath ) {
                    $true
                }
                else {
                    throw "'$_' is not a valid application path"
                }
            })]
        [String[]] $ApplicationPath,

        [Parameter()]
        [switch] $OrphanCleanup,

        [Parameter(Mandatory, ParameterSetName = 'RemoveAll')]
        [switch] $All,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation

        $params = @{
            Method  = 'Post'
            UriLeaf = 'Certificates/Dissociate'
            Body    = @{ }
        }
    }

    process {

        $shouldProcessAction = "Remove associations"

        if ( -not ($Path | Test-TppObject -ExistOnly) ) {
            Write-Error ("Certificate path {0} does not exist" -f $Path)
            Continue
        }

        $params.Body = @{
            'CertificateDN' = $Path
        }

        if ( $OrphanCleanup ) {
            $params.Body.DeleteOrphans = $true
            $shouldProcessAction += ' AND ORPHANS'
        }

        if ( $PSBoundParameters.ContainsKey('ApplicationPath') ) {
            $params.Body.ApplicationDN = @($ApplicationPath)
        }
        else {
            $associatedApps = $Path | Get-VdcAttribute -Attribute "Consumers" | Select-Object -ExpandProperty Consumers

            if ( $associatedApps ) {
                $params.Body.ApplicationDN = @($associatedApps)
            }
            else {
                # no associations to process, no need to continue
                Write-Warning "No associations for path '$Path'"
                Return
            }
        }

        try {
            if ( $PSCmdlet.ShouldProcess($Path, $shouldProcessAction) ) {
                $null = Invoke-VenafiRestMethod @params
            }
        }
        catch {
            $myError = $_.ToString() | ConvertFrom-Json
            Write-Error ('Error removing associations from certificate {0}: {1}' -f $Path, $myError.Error)
        }
    }
}


