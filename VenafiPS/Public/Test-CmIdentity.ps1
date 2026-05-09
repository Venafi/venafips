function Test-CmIdentity {
    <#
    .SYNOPSIS
    Test if an identity exists

    .DESCRIPTION
    Provided with a prefixed universal id, find out if an identity exists.

    .PARAMETER ID
    The id that represents the user or group.

    .PARAMETER ExistOnly
    Only return boolean instead of ID and Exists list.  Helpful when validating just 1 identity.

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.

    .INPUTS
    Identity

    .OUTPUTS
    PSCustomObject will be returned with properties 'ID', a System.String, and 'Exists', a System.Boolean.

    .EXAMPLE
    'local:78uhjny657890okjhhh', 'AD+mydomain.com:azsxdcfvgbhnjmlk09877654321' | Test-CmIdentity

    Test multiple identities

    .EXAMPLE
    Test-CmIdentity -Identity 'AD+mydomain.com:azsxdcfvgbhnjmlk09877654321' -ExistOnly

    Retrieve existence for only one identity, returns boolean

    .LINK
    https://venafi.github.io/VenafiPS/functions/Test-CmIdentity/

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Test-CmIdentity.ps1

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Identity-Validate.php

    #>

    [Alias('Test-VdcIdentity')]
    [CmdletBinding()]

    param (

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateScript( {
                if ( $_ | Test-CmIdentityFormat ) {
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
        [TrustClient] $TrustClient
    )

    begin {

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

            if ( Test-CmIdentityFormat -ID $thisID -Format 'Universal' ) {
                $params.Body.ID.PrefixedUniversal = $thisId
            } else {
                $params.Body.ID.PrefixedName = $thisId
            }

            $response = Invoke-TrustRestMethod @params

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


