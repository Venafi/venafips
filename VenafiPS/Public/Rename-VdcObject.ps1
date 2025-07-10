function Rename-VdcObject {
    <#
    .SYNOPSIS
    Rename and/or move an object

    .DESCRIPTION
    Rename and/or move an object

    .PARAMETER Path
    Full path to an existing object

    .PARAMETER NewPath
    New path, including name

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.

    .INPUTS
    none

    .OUTPUTS

    .EXAMPLE
    Rename-VdcObject -Path '\VED\Policy\My Devices\OldDeviceName' -NewPath '\ved\policy\my devices\NewDeviceName'
    Rename an object

    .EXAMPLE
    Rename-VdcObject -Path '\VED\Policy\My Devices\DeviceName' -NewPath '\ved\policy\new devices folder\DeviceName'
    Move an object

    .LINK
    https://venafi.github.io/VenafiPS/functions/Rename-VdcObject/

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Rename-VdcObject.ps1

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Config-renameobject.php

    #>

    [CmdletBinding()]
    [Alias('Rename-TppObject')]

    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if ( $_ | Test-TppDnPath ) {
                    $true
                } else {
                    throw "'$_' is not a valid DN path"
                }
            })]
        [Alias('SourceDN')]
        [String] $Path,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $NewPath,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    Test-VenafiSession $PSCmdlet.MyInvocation

    $params = @{

        Method     = 'Post'
        UriLeaf    = 'config/RenameObject'
        Body       = @{
            ObjectDN    = $Path
            NewObjectDN = $NewPath
        }
    }

    $response = Invoke-VenafiRestMethod @params

    if ( $response.Result -ne 1 ) {
        throw $response.Error
    }
}

