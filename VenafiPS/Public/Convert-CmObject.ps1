function Convert-CmObject {
    <#
    .SYNOPSIS
    Change the class/object type of an existing object

    .DESCRIPTION
    Change the class/object type of an existing object.
    Please note, changing the class does NOT change any attributes and must be done separately.
    Using -PassThru will allow you to pass the input to other functions including Set-CmAttribute; see the examples.

    .PARAMETER Path
    Path to the object

    .PARAMETER Class
    New class/type

    .PARAMETER PassThru
    Return a CmObject representing the newly converted object

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.

    .INPUTS
    Path

    .OUTPUTS
    pscustomobject, if -PassThru provided

    .EXAMPLE
    Convert-CmObject -Path '\ved\policy\' -Class 'X509 Device Certificate'

    Convert an object to a different type

    .EXAMPLE
    Convert-CmObject -Path '\ved\policy\device\app' -Class 'CAPI' -PassThru | Set-CmAttribute -Attribute @{'Driver Name'='appcapi'}

    Convert an object to a different type, return the updated object and update attributes

    .EXAMPLE
    Find-CmObject -Class Basic | Convert-CmObject -Class 'capi' -PassThru | Set-CmAttribute -Attribute @{'Driver Name'='appcapi'}

    Convert multiple objects to a different type, return the updated objects and update attributes

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Convert-CmObject.ps1

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Config-mutateobject.php

    #>

    [Alias('Convert-VdcObject')]
    [CmdletBinding(SupportsShouldProcess)]

    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if ( $_ | Test-CmDnPath ) {
                    $true
                }
                else {
                    throw "'$_' is not a valid path"
                }
            })]
        [String] $Path,

        [Parameter(Mandatory)]
        [String] $Class,

        [Parameter()]
        [switch] $PassThru,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient
    )

    begin {


        $params = @{
            Method        = 'Post'
            UriLeaf       = 'config/MutateObject'
            Body          = @{
                Class = $Class
            }
        }
    }

    process {

        $params.Body.ObjectDN = $Path

        if ( $PSCmdlet.ShouldProcess($Path, "Convert to type $Class") ) {

            $response = Invoke-TrustRestMethod @params

            if ( $response.Result -eq 1 ) {
                if ( $PassThru ) {
                    [CmObject]::new($Path)
                }
            }
            else {
                Write-Error $response.Error
            }
        }
    }
}

