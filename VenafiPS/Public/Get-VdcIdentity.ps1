function Get-VdcIdentity {
    <#
    .SYNOPSIS
    Get user and group details

    .DESCRIPTION
    Returns user/group information for Certificate Manager, Self-Hosted
    This returns individual identity, group identity, or distribution groups from a local or non-local provider such as Active Directory.

    .PARAMETER ID
    Provide the guid or prefixed universal id.  To search, use Find-VdcIdentity.

    .PARAMETER IncludeAssociated
    Include all associated identity groups and folders.

    .PARAMETER IncludeMembers
    Include all individual members if the ID is a group.

    .PARAMETER Me
    Returns the identity of the authenticated/current user

    .PARAMETER All
    Return a complete list of local users.

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.

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
    Get-VdcIdentity -ID 'AD+myprov:asdfgadsf9g87df98g7d9f8g7'

    Get identity details from an id

    .EXAMPLE
    Get-VdcIdentity -ID 'AD+myprov:asdfgadsf9g87df98g7d9f8g7' -IncludeMembers

    Get identity details including members if the identity is a group

    .EXAMPLE
    Get-VdcIdentity -ID 'AD+myprov:asdfgadsf9g87df98g7d9f8g7' -IncludeAssociated

    Get identity details including associated groups/folders

    .EXAMPLE
    Get-VdcIdentity -Me

    Get identity details for authenticated/current user

    .EXAMPLE
    Get-VdcIdentity -All

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

    [CmdletBinding(DefaultParameterSetName = 'Id')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = "Parameter is used")]
    [Alias('Get-TppIdentity')]

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
        [psobject] $VenafiSession
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation
    }

    process {

        Switch ($PsCmdlet.ParameterSetName)	{
            'Id' {

                $params = @{
                    Method  = 'Post'
                    UriLeaf = 'Identity/Validate'
                    Body    = @{'ID' = @{ } }
                }

                if ( Test-VdcIdentityFormat -ID $ID -Format 'Universal' ) {
                    $params.Body.ID.PrefixedUniversal = $ID
                }
                elseif ( Test-VdcIdentityFormat -ID $ID -Format 'Name' ) {
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

                $response = Invoke-VenafiRestMethod @params | Select-Object -ExpandProperty ID

                if ( $IncludeAssociated ) {
                    $assocParams = $params.Clone()
                    $assocParams.UriLeaf = 'Identity/GetAssociatedEntries'
                    $associated = Invoke-VenafiRestMethod @assocParams
                    $response | Add-Member @{ 'Associated' = $null }
                    $response.Associated = $associated.Identities | ConvertTo-VdcIdentity
                }

                if ( $IncludeMembers ) {
                    $response | Add-Member @{ 'Members' = $null }
                    if ( $response.IsGroup ) {
                        $assocParams = $params.Clone()
                        $assocParams.UriLeaf = 'Identity/GetMembers'
                        $assocParams.Body.ResolveNested = "1"
                        $members = Invoke-VenafiRestMethod @assocParams
                        $response.Members = $members.Identities | ConvertTo-VdcIdentity
                    }
                }

                $idOut = $response
            }

            'Me' {
                $response = Invoke-VenafiRestMethod -UriLeaf 'Identity/Self'

                $idOut = $response.Identities | Select-Object -First 1
            }

            'All' {
                # no built-in api for this, get group objects and then get details
                Find-VdcObject -Path '\VED\Identity' -Class 'User', 'Group' | Get-VdcIdentity -IncludeAssociated:$IncludeAssociated.IsPresent -IncludeMembers:$IncludeMembers.IsPresent
            }
        }

        if ( $idOut ) {
            $idOut | ConvertTo-VdcIdentity
        }
    }
}

