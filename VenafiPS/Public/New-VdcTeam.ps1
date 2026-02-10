function New-VdcTeam {
    <#
    .SYNOPSIS
    Create a new team

    .DESCRIPTION
    Create a new Certificate Manager, Self-Hosted team

    .PARAMETER Name
    Team name

    .PARAMETER Owner
    1 or more owners for the team
    Provide the identity ID property from Find-VdcIdentity or Get-VdcIdentity.

    .PARAMETER Member
    1 or more members for the team
    Provide the identity ID property from Find-VdcIdentity or Get-VdcIdentity.

    .PARAMETER Policy
    1 or more policy folder paths this team manages.

    .PARAMETER Product
    1 or more product names, 'TLS', 'SSH', and/or 'Code Signing'.

    .PARAMETER Description
    Team description or purpose.

    .PARAMETER PassThru
    Send back details on the newly created team

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, Self-Hosted token key can also provided.
    If providing a Certificate Manager, Self-Hosted token, an environment variable named VDC_SERVER must also be set.

    .EXAMPLE
    New-VdcTeam -Name 'My New Team' -Member 'local:{803f332e-7576-4696-a5a2-8ac6be6b14e6}' -Owner 'local:{803f332e-7576-4696-a5a2-8ac6be6b14e7}' -Product 'TLS'

    Create a new team

    .EXAMPLE
    New-VdcTeam -Name 'My New Team' -Member 'local:{803f332e-7576-4696-a5a2-8ac6be6b14e6}' -Owner 'local:{803f332e-7576-4696-a5a2-8ac6be6b14e7}' -Product 'TLS' -Policy '\ved\policy\myfolder'

    Create a new team and assign it to a policy

    .EXAMPLE
    New-VdcTeam -Name 'My New Team' -Member 'local:{803f332e-7576-4696-a5a2-8ac6be6b14e6}' -Owner 'local:{803f332e-7576-4696-a5a2-8ac6be6b14e7}' -Product 'TLS' -Description 'One amazing team'

    Create a new team with optional description

    .EXAMPLE
    New-VdcTeam -Name 'My New Team' -Member 'local:{803f332e-7576-4696-a5a2-8ac6be6b14e6}' -Owner 'local:{803f332e-7576-4696-a5a2-8ac6be6b14e7}' -Product 'TLS' -PassThru

    Name     : My New Team
    ID       : local:{a6053090-e309-49d9-98a7-28cbe7896c27}
    Path     : \VED\Identity\My New Team
    FullName : local:My New Team
    IsGroup  : True
    Members  : @{Name=sample-user; ID=local:{6baad36c-7cac-48c8-8e54-000cc22ad88f};
               Path=\VED\Identity\sample-user; FullName=local:sample-user; IsGroup=False}
    Owners   : @{Name=sample-owner; ID=local:{d1a76bc7-d3a6-431b-9bea-d2d8780ecd86};
               Path=\VED\Identity\sample-owner; FullName=local:sample-owner; IsGroup=False}

    Create a new team returning the new team

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Teams.php
    #>

    [CmdletBinding()]

    param (

        [Parameter(Mandatory)]
        [string] $Name,

        [Parameter(Mandatory)]
        [string[]] $Owner,

        [Parameter(Mandatory)]
        [string[]] $Member,

        [Parameter()]
        [ValidateScript( {
                if ( $_ | Test-TppDnPath ) {
                    $true
                }
                else {
                    throw "'$_' is not a valid policy path"
                }
            })]
        [string[]] $Policy,

        [Parameter(Mandatory)]
        [ValidateSet('TLS', 'SSH', 'Code Signing')]
        [string[]] $Product,

        [Parameter()]
        [string] $Description,

        [Parameter()]
        [switch] $PassThru,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation
    }

    process {

        $params = @{
            Method  = 'Post'
            UriLeaf = 'Teams/'
        }

        $members = foreach ($thisMember in $Member) {
            if ( $thisMember.StartsWith('local') ) {
                $memberIdentity = Get-VdcIdentity -ID $thisMember
                @{
                    'PrefixedName'      = $memberIdentity.FullName
                    'PrefixedUniversal' = $memberIdentity.ID
                }
            }
            else {
                @{'PrefixedUniversal' = $thisMember }
            }
        }
        $owners = foreach ($thisOwner in $Owner) {
            if ( $thisOwner.StartsWith('local') ) {
                $ownerIdentity = Get-VdcIdentity -ID $thisOwner
                @{
                    'PrefixedName'      = $ownerIdentity.FullName
                    'PrefixedUniversal' = $ownerIdentity.ID
                }
            }
            else {
                @{'PrefixedUniversal' = $thisOwner }
            }
        }

        $params.Body = @{
            'Name'     = @{'PrefixedName' = "local:$Name" }
            'Members'  = @($members)
            'Owners'   = @($owners)
            'Products' = @($Product)
        }

        if ( $Policy ) {
            $params.Body.Add('Assets', @($Policy))
        }

        if ( $Description ) {
            $params.Body.Add('Description', $Description)
        }

        $response = Invoke-VenafiRestMethod @params | Select-Object -ExpandProperty ID

        if ( $PassThru ) {
            $response | Get-VdcTeam
        }
    }
}


