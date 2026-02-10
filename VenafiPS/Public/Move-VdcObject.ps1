function Move-VdcObject {
    <#
    .SYNOPSIS
    Move an object of any type

    .DESCRIPTION
    Move an object of any type from one policy to another.
    A rename can be done at the same time as the move by providing a full target path including the new object name.

    .PARAMETER SourcePath
    Full path to an existing object in Certificate Manager, Self-Hosted

    .PARAMETER TargetPath
    New path.  This can either be an existing policy and the existing object name will be kept or a full path including a new object name.

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.

    .INPUTS
    SourcePath (Path)

    .OUTPUTS
    n/a

    .EXAMPLE
    Move-VdcObject -SourceDN '\VED\Policy\My Folder\mycert.company.com' -TargetDN '\VED\Policy\New Folder\mycert.company.com'
    Move object to a new Policy folder

    .EXAMPLE
    Find-VdcCertificate -Path '\ved\policy\certs' | Move-VdcObject -TargetDN '\VED\Policy\New Folder'
    Move all objects found in 1 folder to another

    .LINK
    https://venafi.github.io/VenafiPS/functions/Move-VdcObject/

    .LINK
    https://venafi.github.io/VenafiPS/functions/Test-VdcObject/

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Move-VdcObject.ps1

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Config-renameobject.php

    #>

    [CmdletBinding(SupportsShouldProcess)]
    [Alias('Move-TppObject')]

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
        [Alias('SourceDN', 'Path')]
        [String] $SourcePath,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if ( $_ | Test-TppDnPath ) {
                    $true
                }
                else {
                    throw "'$_' is not a valid DN path"
                }
            })]
        [Alias('TargetDN')]
        [String] $TargetPath,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation

        # determine if target is a policy or other object
        # if policy, we'll need to append the object name in the process block when moving
        try {
            $targetObject = Get-VdcObject -Path $TargetPath -ErrorAction SilentlyContinue
        }
        catch {
            # expected if target is a new object name and not policy
        }
        $targetIsPolicy = ($targetObject.TypeName -eq 'Policy')
    }

    process {

        $params = @{
            Method        = 'Post'
            UriLeaf       = 'config/RenameObject'
            Body          = @{
                ObjectDN    = $SourcePath
                NewObjectDN = $TargetPath
            }
        }

        # if target is a policy, append the object name from source
        if ( $targetIsPolicy ) {
            # get object name, issue 129
            $childPath = $SourcePath.Split('\')[-1]
            $params.Body.NewObjectDN = '{0}\{1}' -f $targetObject.Path, $childPath
        }

        if ( $PSCmdlet.ShouldProcess($SourcePath, ('Move to {0}' -f $params.Body.NewObjectDN)) ) {
            $response = Invoke-VenafiRestMethod @params

            if ( $response.Result -ne 1 ) {
                Write-Error $response.Error
            }
        }
    }
}

