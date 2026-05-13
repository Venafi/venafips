function Get-CmIdentity {
    <#
    .SYNOPSIS
    Get user and group details

    .DESCRIPTION
    Returns user/group information for Certificate Manager, Self-Hosted
    This returns individual identity, group identity, or distribution groups from a local or non-local provider such as Active Directory.

    .PARAMETER ID
    Provide the guid or prefixed universal id.  To search, use Find-CmIdentity.

    .PARAMETER IncludeAssociated
    Include all associated identity groups and folders.

    .PARAMETER IncludeMembers
    Include all individual members if the ID is a group.

    .PARAMETER Me
    Returns the identity of the authenticated/current user

    .PARAMETER All
    Return a complete list of local users.

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.

    .INPUTS
    ID

    .OUTPUTS
    PSCustomObject
        Name
        ID
        Path
        FullName
        Associated (if -IncludeAssociated provided)
        Members (if -IncludeMembers provided)

    .EXAMPLE
    Get-CmIdentity -ID 'AD+myprov:asdfgadsf9g87df98g7d9f8g7'

    Get identity details from an id

    .EXAMPLE
    Get-CmIdentity -ID 'AD+myprov:asdfgadsf9g87df98g7d9f8g7' -IncludeMembers

    Get identity details including members if the identity is a group

    .EXAMPLE
    Get-CmIdentity -ID 'AD+myprov:asdfgadsf9g87df98g7d9f8g7' -IncludeAssociated

    Get identity details including associated groups/folders

    .EXAMPLE
    Get-CmIdentity -Me

    Get identity details for authenticated/current user

    .EXAMPLE
    Get-CmIdentity -All

    Get all user and group info

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Identity-Validate.php

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-GET-Identity-Self.php

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Identity-GetAssociatedEntries.php

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Identity-GetMembers.php
    #>

    [Alias('Get-VdcIdentity')]
    [CmdletBinding(DefaultParameterSetName = 'Id')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = "Parameter is used")]

    param (
        [Parameter(Mandatory, ParameterSetName = 'Id', ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('Guid', 'FullName')]
        [String] $ID,

        [Parameter(Mandatory, ParameterSetName = 'Me')]
        [Switch] $Me,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [Switch] $All,

        [Parameter(ParameterSetName = 'Id')]
        [Parameter(ParameterSetName = 'All')]
        [Switch] $IncludeAssociated,

        [Parameter(ParameterSetName = 'Id')]
        [Parameter(ParameterSetName = 'All')]
        [Switch] $IncludeMembers,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient
    )

    begin {
    }

    process {

        Switch ($PsCmdlet.ParameterSetName)	{
            'Id' {

                $params = @{
                    Method  = 'Post'
                    UriLeaf = 'Identity/Validate'
                    Body    = @{'ID' = @{ } }
                }

                if ( Test-CmIdentityFormat -ID $ID -Format 'Universal' ) {
                    $params.Body.ID.PrefixedUniversal = $ID
                }
                elseif ( Test-CmIdentityFormat -ID $ID -Format 'Name' ) {
                    $params.Body.ID.PrefixedName = $ID
                }
                elseif ( [guid]::TryParse($ID, $([ref][guid]::Empty)) ) {
                    $guid = [guid] $ID
                    $params.Body.ID.PrefixedUniversal = 'local:{{{0}}}' -f $guid.ToString()
                }
                else {
                    Write-Error "'$ID' is not a valid identity"
                    return
                }

                $response = Invoke-TrustRestMethod @params | Select-Object -ExpandProperty ID

                if ( $IncludeAssociated ) {
                    $assocParams = $params.Clone()
                    $assocParams.UriLeaf = 'Identity/GetAssociatedEntries'
                    $associated = Invoke-TrustRestMethod @assocParams
                    $response | Add-Member @{ 'Associated' = $null }
                    $response.Associated = $associated.Identities | ConvertTo-CmIdentity
                }

                if ( $IncludeMembers ) {
                    $response | Add-Member @{ 'Members' = $null }
                    if ( $response.IsGroup ) {
                        $assocParams = $params.Clone()
                        $assocParams.UriLeaf = 'Identity/GetMembers'
                        $assocParams.Body.ResolveNested = "1"
                        $members = Invoke-TrustRestMethod @assocParams
                        $response.Members = $members.Identities | ConvertTo-CmIdentity
                    }
                }

                $idOut = $response
            }

            'Me' {
                $response = Invoke-TrustRestMethod -UriLeaf 'Identity/Self'

                $idOut = $response.Identities | Select-Object -First 1
            }

            'All' {
                # no built-in api for this, get group objects and then get details
                Find-CmObject -Path '\VED\Identity' -Class 'User', 'Group' | Get-CmIdentity -IncludeAssociated:$IncludeAssociated.IsPresent -IncludeMembers:$IncludeMembers.IsPresent
            }
        }

        if ( $idOut ) {
            $idOut | ConvertTo-CmIdentity
        }
    }
}

