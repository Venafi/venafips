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

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A TLSPC key can also provided.

    .INPUTS
    User

    .OUTPUTS
    PSCustomObject

    .EXAMPLE
    Set-VcTeam -User 'greg.brownstein@cyberark.com' -Disable

    Disable a user account

    #>

    [CmdletBinding()]

    param (

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('userId', 'ID')]
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
        [Alias('Key')]
        [psobject] $VenafiSession
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation
    }

    process {

        $thisID = Get-VcData -InputObject $User -Type 'User' -FailOnNotFound

        $params = @{
            Method = 'Put'
        }

        if ( $PSBoundParameters.ContainsKey('Disable') ) {
            $params.UriLeaf = "users/$thisID/disabled"
            $params.Body = @{ disabled = $Disable.IsPresent }
            $response = Invoke-VenafiRestMethod @params
        }

        if ( $PSBoundParameters.ContainsKey('LocalLoginDisable') ) {
            $params.UriLeaf = "users/$thisID/locallogin"
            $params.Body = @{ localLoginDisabled = $LocalLoginDisable.IsPresent }
            $response = Invoke-VenafiRestMethod @params
        }

        if ( $PSBoundParameters.ContainsKey('AccountType') ) {
            $params.UriLeaf = "users/$thisID/accounttype"
            $params.Body = @{ accounttype = $AccountType }
            $response = Invoke-VenafiRestMethod @params
        }

        if ( $PassThru -and $response ) {
            $response | Select-Object -Property *, @{'n' = 'userId'; 'e' = { $_.id } } -ExcludeProperty id
        }
    }
}


