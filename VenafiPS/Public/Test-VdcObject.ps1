function Test-VdcObject {
    <#
    .SYNOPSIS
    Test if an object exists

    .DESCRIPTION
    Provided with either a DN path or GUID, find out if an object exists.

    .PARAMETER Path
    DN path to object.  Provide either this or Guid.  This is the default if both are provided.

    .PARAMETER Guid
    Guid which represents a unqiue object.  Provide either this or Path.

    .PARAMETER ExistOnly
    Only return boolean instead of Object and Exists list.  Helpful when validating just 1 object.

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.

    .INPUTS
    Path or Guid.

    .OUTPUTS
    PSCustomObject will be returned with properties 'Object', a System.String, and 'Exists', a System.Boolean.

    .EXAMPLE
    $multDNs | Test-VdcObject
    Object                    Exists
    --------                  -----
    \VED\Policy\My folder1    True
    \VED\Policy\My folder2    False

    Test for existence by Path

    .EXAMPLE
    Test-VdcObject -Path '\VED\Policy\My folder' -ExistOnly

    Retrieve existence for only one object

    .LINK
    https://venafi.github.io/VenafiPS/functions/Test-VdcObject/

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Test-VdcObject.ps1

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Config-isvalid.php

    #>

    [CmdletBinding(DefaultParameterSetName = 'DN')]

    param (
        [Parameter(Mandatory, ParameterSetName = 'DN', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if ( $_ | Test-TppDnPath ) {
                    $true
                } else {
                    throw "'$_' is not a valid DN path"
                }
            })]
        [Alias('DN')]
        [string[]] $Path,

        [Parameter(Mandatory, ParameterSetName = 'GUID', ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Guid[]] $Guid,

        [Parameter()]
        [Switch] $ExistOnly,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient
    )

    begin {

        $params = @{

            Method     = 'Post'
            UriLeaf    = 'config/IsValid'
            Body       = @{}
        }
    }

    process {

        Switch ($PsCmdlet.ParameterSetName)	{
            'DN' {
                $paramSetValue = $Path
            }

            'GUID' {
                $paramSetValue = $Guid
            }
        }

        foreach ( $thisValue in $paramSetValue ) {

            Switch ($PsCmdlet.ParameterSetName)	{
                'DN' {
                    $params.Body = @{
                        'ObjectDN' = $thisValue
                    }
                }

                'GUID' {
                    $params.Body = @{
                        'ObjectGUID' = "{$thisValue}"
                    }
                }
            }

            $response = Invoke-TrustRestMethod @params

            if ( $ExistOnly ) {
                $response.Result -eq 1
            } else {
                [PSCustomObject] @{
                    Object = $thisValue
                    Exists = ($response.Result -eq 1)
                }
            }
        }
    }
}


