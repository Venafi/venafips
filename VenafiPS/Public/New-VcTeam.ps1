function New-VcTeam {
    <#
    .SYNOPSIS
    Create a new team

    .DESCRIPTION
    Create a new Certificate Manager, SaaS team

    .PARAMETER Name
    Team name

    .PARAMETER Owner
    1 or more owners for the team.
    Provide the unique guid obtained from Get-VcIdentity.

    .PARAMETER Member
    1 or more members for the team.
    Provide the unique guid obtained from Get-VcIdentity.

    .PARAMETER Role
    Team role, either 'System Admin', 'PKI Admin', 'Resource Owner' or 'Guest'

    .PARAMETER UserMatchingRule
    If SSO is enabled, build your team membership rules to organize your users into teams automatically.
    If more than 1 rule is configured, they must all be met for a user to meet the criteria.
    Each rule should be of the format @('claim name', 'operator', 'value')
    where operator can be equals, not_equals, contains, not_contains, starts_with, or ends_with.

    .PARAMETER PassThru
    Send back details on the newly created team

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, SaaS key can also provided.

    .EXAMPLE
    New-VenafiTeam -Name 'My New Team' -Member 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -Owner @('ca7ff555-88d2-4bfc-9efa-2630ac44c1f3', 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f4') -Role 'System Admin'

    Create a new team

    .EXAMPLE
    New-VenafiTeam -Name 'My New Team' -Member 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -Owner @('ca7ff555-88d2-4bfc-9efa-2630ac44c1f3', 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f4') -Role 'System Admin' -UserMatchingRule @('MyClaim', 'CONTAINS', 'Group')

    Create a new team with user matching rule

    .EXAMPLE
    New-VenafiTeam -Name 'My New Team' -Member 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -Owner @('ca7ff555-88d2-4bfc-9efa-2630ac44c1f3', 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f4') -Role 'System Admin' -PassThru

    id                : a7d60730-a967-11ec-8832-4d051bf6d0b4
    name              : My New Team
    systemRoles       : {SYSTEM_ADMIN}
    productRoles      :
    role              : SYSTEM_ADMIN
    members           : {443de910-a6cc-11ec-ad22-018e33741844}
    owners            : {0a2adae0-b22b-11ea-91f3-ebd6dea5452e}
    companyId         : 0bc771e1-7abe-4339-9fcd-93fffe9cba7f
    userMatchingRules : {}
    modificationDate  : 3/21/2022 6:38:40 PM

    Create a new team returning the new team

    .LINK
    https://api.venafi.cloud/webjars/swagger-ui/index.html#/Teams/create_1

    .LINK
    https://docs.venafi.cloud/vcs-platform/creating-new-teams/
    #>

    [CmdletBinding()]

    param (

        [Parameter(Mandatory)]
        [string] $Name,

        [Parameter(Mandatory)]
        [string[]] $Owner,

        [Parameter(Mandatory)]
        [string[]] $Member,

        [Parameter(Mandatory)]
        [ValidateSet('System Admin', 'PKI Admin', 'Resource Owner', 'Guest')]
        [string] $Role,

        [Parameter()]
        [System.Collections.Generic.List[array]] $UserMatchingRule,

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
            UriLeaf = 'teams'
        }

        $rules = foreach ($rule in $UserMatchingRule) {

            if ( $rule.Count -ne 3 ) {
                throw 'Each rule must contain a claim name, operator, and value'
            }

            if ( $rule[1].ToUpper() -notin 'EQUALS', 'NOT_EQUALS', 'CONTAINS', 'NOT_CONTAINS', 'STARTS_WITH', 'ENDS_WITH') {
                throw 'Valid values for operator are EQUALS, NOT_EQUALS, CONTAINS, NOT_CONTAINS, STARTS_WITH, ENDS_WITH'
            }

            @{
                'claimName' = $rule[0]
                'operator'  = $rule[1].ToUpper()
                'value'     = $rule[2]
            }
        }

        $params.Body = @{
            'name'              = $Name
            'role'              = $Role.Replace(' ', '_').ToUpper()
            'members'           = @($Member)
            'owners'            = @($Owner)
            'userMatchingRules' = @($rules)
        }

        $response = Invoke-VenafiRestMethod @params

        if ( $PassThru ) {
            $response | Get-VcTeam
        }
    }
}


