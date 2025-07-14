function Remove-VdcObject {
    <#
    .SYNOPSIS
    Remove TLSPDC objects

    .DESCRIPTION
    Remove a TLSPDC object and optionally perform a recursive removal.
    This process can be very destructive as it will remove anything you send it!!!
    Run this in parallel with PowerShell v7+ when you have a large number to process.

    .PARAMETER Path
    Full path to an existing object

    .PARAMETER Recursive
    Remove recursively, eg. everything within a policy folder

    .PARAMETER ThrottleLimit
    Limit the number of threads when running in parallel; the default is 100.
    Setting the value to 1 will disable multithreading.
    On PS v5 the ThreadJob module is required.  If not found, multithreading will be disabled.


    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.

    .INPUTS
    Path

    .OUTPUTS
    None

    .EXAMPLE
    Remove-VdcObject -Path '\VED\Policy\My empty folder'
    Remove an object

    .EXAMPLE
    Remove-VdcObject -Path '\VED\Policy\folder' -Recursive
    Remove an object and all objects contained

    .EXAMPLE
    Find-VdcObject -Class 'capi' | Remove-VdcObject
    Find 1 or more objects and remove them

    .EXAMPLE
    Remove-VdcObject -Path '\VED\Policy\folder' -Confirm:$false
    Remove an object without prompting for confirmation.  Be careful!

    .LINK
    https://venafi.github.io/VenafiPS/functions/Remove-VdcObject/

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Remove-VdcObject.ps1

    .LINK
    https://docs.venafi.com/Docs/currentSDK/TopNav/Content/SDK/WebSDK/r-SDK-POST-Config-delete.php

    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [Alias('Remove-TppObject')]

    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [String] $Path,

        [Parameter()]
        [switch] $Recursive,

        [Parameter()]
        [int32] $ThrottleLimit = 100,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {

        Test-VenafiSession $PSCmdlet.MyInvocation
        $allItems = [System.Collections.Generic.List[string]]::new()
    }

    process {
        if ( $PSCmdlet.ShouldProcess($Path, "Remove object") ) {
            $allItems.Add($Path)
        }
    }

    end {
        Invoke-VenafiParallel -InputObject $allItems -ScriptBlock {

            $params = @{

                Method  = 'Post'
                UriLeaf = 'config/Delete'
                Body    = @{
                    ObjectDN  = $PSItem
                    Recursive = [int] (($using:Recursive).IsPresent)
                }
            }

            $response = Invoke-VenafiRestMethod @params

            if ( $response.Result -ne 1 ) {
                Write-Error $response.Error
                return
            }
        } -ThrottleLimit $ThrottleLimit -ProgressTitle 'Removing objects'
    }
}

