function Find-VdcIdentity {
    <#
    .SYNOPSIS
    Search for identity details

    .DESCRIPTION
    Returns information about individual identity, group identity, or distribution groups from a local or non-local provider such as Active Directory.
    You can specify individual identity types to search for or all

    .PARAMETER Name
    The individual identity, group identity, or distribution group name to search for

    .PARAMETER First
    First how many items are returned, the default is 500, but is limited by the provider.

    .PARAMETER IncludeUsers
    Include user identity type in search

    .PARAMETER IncludeSecurityGroups
    Include security group identity type in search

    .PARAMETER IncludeDistributionGroups
    Include distribution group identity type in search

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.

    .INPUTS
    Name

    .OUTPUTS
    PSCustomObject with the following properties:
        Name
        ID
        Path

    .EXAMPLE
    Find-VdcIdentity -Name 'greg' -IncludeUsers
    Find only user identities with the name greg

    .EXAMPLE
    'greg', 'brownstein' | Find-VdcIdentity
    Find all identity types with the name greg and brownstein

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Identity-Browse.php
    #>

    [CmdletBinding()]

    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [String[]] $Name,

        [Parameter()]
        [Alias('Limit')]
        [int] $First = 500,

        [Parameter(ParameterSetName = 'Find')]
        [Switch] $IncludeUsers,

        [Parameter(ParameterSetName = 'Find')]
        [Switch] $IncludeSecurityGroups,

        [Parameter(ParameterSetName = 'Find')]
        [Switch] $IncludeDistributionGroups,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient
    )

    begin {

        $identityType = 0
        # determine settings to use
        if ( $PSBoundParameters.ContainsKey('IncludeUsers') ) {
            $identityType += [VdcIdentityType]::User
        }
        if ( $PSBoundParameters.ContainsKey('IncludeSecurityGroups') ) {
            $identityType += [VdcIdentityType]::SecurityGroups
        }
        if ( $PSBoundParameters.ContainsKey('IncludeDistributionGroups') ) {
            $identityType += [VdcIdentityType]::DistributionGroups
        }

        # if no types to include were provided, include all
        if ( $identityType -eq 0 ) {
            $identityType = [VdcIdentityType]::User + [VdcIdentityType]::SecurityGroups + [VdcIdentityType]::DistributionGroups
        }

        $params = @{
            Method  = 'Post'
            UriLeaf = 'Identity/Browse'
            Body    = @{
                Filter       = 'placeholder'
                Limit        = $First
                IdentityType = $identityType
            }
        }
    }

    process {

        $response = $Name.ForEach{
            $params.Body.Filter = $_
            Invoke-TrustRestMethod @params
        }

        $ids = $response.Identities

        if ( $ids ) {
            $ids | ConvertTo-VdcIdentity
        }
    }
}


