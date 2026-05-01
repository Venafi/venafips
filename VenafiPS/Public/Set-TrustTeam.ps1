function Set-TrustTeam {
    <#
    .SYNOPSIS
    Update an existing team

    .DESCRIPTION
    Update name, role, and/or user matching rules for existing teams.

    .PARAMETER Team
    Team ID or name

    .PARAMETER Name
    Provide a new name for the team if you wish to change it.

    .PARAMETER Role
    Provide a new role for the team if you wish to change it.
    Accepted values are 'System Admin', 'PKI Admin', 'Resource Owner', or 'Guest'

    .PARAMETER UserMatchingRule
    Rule(s) for user membership which matches SSO claim data.
    Each rule has 3 parts, ClaimName, Operator, and ClaimValue, in the form of a hashtable.
    A list/array of hashtables is supported.
    For a singlepart claim, the operator can be 'equals', 'does not equal', 'starts with', or 'ends with'.
    For a multivalue claim where ClaimValue will be an array, the operator can be 'contains' or 'does not contain'.
    ClaimName and ClaimValue are case sensitive.
    When providing user AD groups or other groups they are most commonly provided as multivalue claims.
    This parameter will overwrite existing rules by default.  To append use -NoOverwrite.

    .PARAMETER NoOverwrite
    Append to existing user matching rules as opposed to overwriting

    .PARAMETER PassThru
    Return the newly updated team object

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.

    .INPUTS
    ID

    .OUTPUTS
    PSCustomObject

    .EXAMPLE
    Set-TrustTeam -ID 'MyTeam' -Name 'ThisTeamIsBetter'

    Rename an existing team

    .EXAMPLE
    Set-TrustTeam -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -Role 'PKI Admin'

    Change the role for an existing team

    .EXAMPLE
    Set-TrustTeam -ID 'MyTeam' -UserMatchingRule @{'ClaimName'='MyClaim';'Operator'='equals';'ClaimValue'='matchme'}

    Replace a teams user matching rules

    .EXAMPLE
    Set-TrustTeam -ID 'MyTeam' -UserMatchingRule @{'ClaimName'='MyClaim';'Operator'='equals';'ClaimValue'='matchme'} -NoOverwrite

    Update a teams user matching rules, appending instead of overwriting

    .EXAMPLE
    Set-TrustTeam -ID 'MyTeam' -Name 'ThisTeamIsBetter' -PassThru

    Rename an existing team and return the updated team object

    .EXAMPLE
    Get-TrustTeam -All | Where-Object {$_.name -like '*shouldnt be sysadmin*'} | Set-TrustTeam -NewRole 'PKI Admin'

    Update many teams
    #>

    [CmdletBinding(DefaultParameterSetName = 'NoOverwrite')]
    [Alias('Set-VcTeam')]

    param (

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('teamId')]
        [string] $Team,

        [Parameter()]
        [string] $Name,

        [Parameter()]
        [ValidateSet('System Admin', 'PKI Admin', 'Resource Owner', 'Guest')]
        [string] $Role,

        [Parameter()]
        [Parameter(Mandatory, ParameterSetName = 'Overwrite')]
        [ValidateScript({
                foreach ($rule in $_) {
                    if ( $rule.Keys -contains 'ClaimName' -and $rule.Keys -contains 'Operator' -and $rule.Keys -contains 'ClaimValue' ) {
                        if ( $rule.Operator.Replace(' ', '_').ToUpper() -notin 'EQUALS', 'NOT_EQUALS', 'CONTAINS', 'NOT_CONTAINS', 'STARTS_WITH', 'ENDS_WITH') {
                            throw 'Operator must be one of the following: Equals, Not Equals, Contains, Not Contains, Starts With, or Ends With'
                        }
                        $true
                    }
                    else {
                        throw "UserMatchingRule is an array of hashtables where each hashtable must contain keys 'ClaimName', 'Operator', and 'ClaimValue'."
                    }
                }
            })]
        [hashtable[]] $UserMatchingRule,

        [Parameter(Mandatory, ParameterSetName = 'Overwrite')]
        [switch] $NoOverwrite,

        [Parameter()]
        [switch] $PassThru,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient
    )

    begin {

        $params = @{
            Method        = 'Patch'
            Body          = @{}
        }

        if ( $Name ) {
            $params.Body.name = $Name
        }

        if ( $Role ) {
            $params.Body.role = $Role.Replace(' ', '_').ToUpper()
        }

        if ( $UserMatchingRule ) {
            [array]$params.Body.userMatchingRules = foreach ($rule in $UserMatchingRule) {
                @{
                    claimName = $rule.ClaimName
                    operator  = $rule.Operator.Replace(' ', '_').ToUpper()
                    value     = $rule.ClaimValue
                }
            }
        }
    }

    process {

        $thisID = Get-TrustData -InputObject $Team -Type 'Team' -Object -FailOnNotFound

        if ( $NoOverwrite -and $thisID.userMatchingRules ) {
            $params.Body.userMatchingRules += $thisID.userMatchingRules
        }

        $params.UriLeaf = "teams/$($thisID.teamId)"

        $response = Invoke-TrustRestMethod @params

        if ( $PassThru ) {
            $response | ConvertTo-TrustTeam
        }
    }
}


