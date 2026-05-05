function Set-VcUser {
    <#
    .SYNOPSIS
    Update an existing user

    .DESCRIPTION
    Update an existing user

    .PARAMETER User
    User id (guid/uuid) or username which is the email address

    .PARAMETER Disable
    Enable/disable the user account

    .PARAMETER LocalLoginDisable
    Enable/disable local login for the admin account

    .PARAMETER AccountType
    Update the account type, either WEB_UI or API

    .PARAMETER PassThru
    Return the newly updated user object

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.

    .INPUTS
    User

    .OUTPUTS
    PSCustomObject

    .EXAMPLE
    Set-TrustTeam -User 'greg.brownstein@cyberark.com' -Disable

    Disable a user account

    #>

    [CmdletBinding()]
    param (

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('userId')]
        [string] $User,

        [Parameter()]
        [switch] $LocalLoginDisable,

        [Parameter()]
        [switch] $Disable,

        [Parameter()]
        [ValidateSet('WEB_UI', 'API')]
        [string] $AccountType,

        [Parameter()]
        [switch] $PassThru,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient
    )

    begin {
    }

    process {

        $thisID = Get-TrustData -InputObject $User -Type 'User' -FailOnNotFound

        $params = @{
            Method = 'Put'
        }

        if ( $PSBoundParameters.ContainsKey('Disable') ) {
            $params.UriLeaf = "users/$thisID/disabled"
            $params.Body = @{ disabled = $Disable.IsPresent }
            $response = Invoke-TrustRestMethod @params
        }

        if ( $PSBoundParameters.ContainsKey('LocalLoginDisable') ) {
            $params.UriLeaf = "users/$thisID/locallogin"
            $params.Body = @{ localLoginDisabled = $LocalLoginDisable.IsPresent }
            $response = Invoke-TrustRestMethod @params
        }

        if ( $PSBoundParameters.ContainsKey('AccountType') ) {
            $params.UriLeaf = "users/$thisID/accounttype"
            $params.Body = @{ accounttype = $AccountType }
            $response = Invoke-TrustRestMethod @params
        }

        if ( $PassThru -and $response ) {
            $response | Select-Object -Property *, @{'n' = 'userId'; 'e' = { $_.id } } -ExcludeProperty id
        }
    }
}


