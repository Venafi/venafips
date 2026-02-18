function Get-VdcIdentityAttribute {
    <#
    .SYNOPSIS
    Get attribute values for Certificate Manager, Self-Hosted identity objects

    .DESCRIPTION
    Get attribute values for Certificate Manager, Self-Hosted identity objects.

    .PARAMETER ID
    The id that represents the user or group.  Use Find-VdcIdentity to get the id.

    .PARAMETER Attribute
    Retrieve identity attribute values for the users and groups.
    Common user attributes include Group Membership, Name, Internet Email Address, Given Name, and Surname.

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.

    .INPUTS
    ID

    .OUTPUTS
    PSCustomObject with the properties Identity and Attribute

    .EXAMPLE
    Get-VdcIdentityAttribute -IdentityId 'AD+blah:{1234567890olikujyhtgrfedwsqa}'

    Get basic attributes

    .EXAMPLE
    Get-VdcIdentityAttribute -IdentityId 'AD+blah:{1234567890olikujyhtgrfedwsqa}' -Attribute 'Surname'

    Get specific attribute for user

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Identity-Validate.php

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Identity-Readattribute.php

    #>

    [CmdletBinding()]
    [Alias('Get-TppIdentityAttribute')]

    param (

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('PrefixedUniversalId', 'Contact', 'IdentityId')]
        [string[]] $ID,

        [Parameter()]
        [string[]] $Attribute,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation

        $params = @{
            Method     = 'Post'
            UriLeaf    = 'Identity/Validate'
            Body       = @{
                'ID' = @{
                    PrefixedUniversal = 'placeholder'
                }
            }
        }

        if ( $PSBoundParameters.ContainsKey('Attribute') ) {
            $params.UriLeaf = 'Identity/ReadAttribute'
            $params.Body.Add('AttributeName', 'placeholder')
        }

    }

    process {

        foreach ( $thisId in $ID ) {

            $params.Body.ID.PrefixedUniversal = $thisId

            if ( $PSBoundParameters.ContainsKey('Attribute') ) {

                $attribHash = @{ }
                foreach ( $thisAttribute in $Attribute ) {

                    $params.Body.AttributeName = $thisAttribute

                    $response = Invoke-VenafiRestMethod @params
                    if ( $response.Attributes ) {
                        $attribHash.$thisAttribute = $response.Attributes[0]
                    }
                }

                $attribsOut = [PSCustomObject] $attribHash

            } else {
                $response = Invoke-VenafiRestMethod @params
                $attribsOut = $response.Id
            }

            [PSCustomObject] @{
                ID         = $thisId
                Attributes = $attribsOut
            }
        }
    }
}


