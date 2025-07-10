function Test-VdcIdentity {
    <#
    .SYNOPSIS
    Test if an identity exists

    .DESCRIPTION
    Provided with a prefixed universal id, find out if an identity exists.

    .PARAMETER ID
    The id that represents the user or group.

    .PARAMETER ExistOnly
    Only return boolean instead of ID and Exists list.  Helpful when validating just 1 identity.

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.

    .INPUTS
    Identity

    .OUTPUTS
    PSCustomObject will be returned with properties 'ID', a System.String, and 'Exists', a System.Boolean.

    .EXAMPLE
    'local:78uhjny657890okjhhh', 'AD+mydomain.com:azsxdcfvgbhnjmlk09877654321' | Test-VdcIdentity

    Test multiple identities

    .EXAMPLE
    Test-VdcIdentity -Identity 'AD+mydomain.com:azsxdcfvgbhnjmlk09877654321' -ExistOnly

    Retrieve existence for only one identity, returns boolean

    .LINK
    https://venafi.github.io/VenafiPS/functions/Test-VdcIdentity/

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Test-VdcIdentity.ps1

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Identity-Validate.php

    #>

    [CmdletBinding()]
    [Alias('Test-TppIdentity')]

    param (

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateScript( {
                if ( $_ | Test-VdcIdentityFormat ) {
                    $true
                } else {
                    throw "'$_' is not a valid Prefixed Universal Id format.  See https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-IdentityInformation.php."
                }
            })]
        [Alias('PrefixedUniversal', 'Contact', 'IdentityId', 'FullName')]
        [string[]] $ID,

        [Parameter()]
        [Switch] $ExistOnly,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation

        $params = @{

            Method        = 'Post'
            UriLeaf       = 'Identity/Validate'
        }
    }

    process {

        foreach ( $thisID in $ID ) {

            $params.Body = @{
                'ID' = @{}
            }

            if ( Test-VdcIdentityFormat -ID $thisID -Format 'Universal' ) {
                $params.Body.ID.PrefixedUniversal = $thisId
            } else {
                $params.Body.ID.PrefixedName = $thisId
            }

            $response = Invoke-VenafiRestMethod @params

            if ( $ExistOnly ) {
                $null -ne $response.Id
            } else {
                [PSCustomObject] @{
                    Identity = $thisId
                    Exists   = ($null -ne $response.Id)
                }
            }
        }
    }
}


