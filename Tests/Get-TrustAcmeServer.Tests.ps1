BeforeAll {
    . $PSScriptRoot/ModuleCommonTrust.ps1

    function New-AcmeNode {
        param ([string] $Name, [bool] $Deactivated = $false)
        [pscustomobject]@{
            id              = [guid]::NewGuid().ToString()
            workspaceId     = $null
            name            = $Name
            createdOn       = '2026-10-20T13:02:03Z'
            lastModifiedOn  = '2026-10-20T13:02:03Z'
            directoryURL    = 'https://api.venafi.cloud/v1/acme/x/directory'
            deactivated     = $Deactivated
            application     = [pscustomobject]@{ id = 'app1'; name = 'My app' }
            issuingTemplate = [pscustomobject]@{ id = 't1'; name = 'My template' }
            certificateTags = @([pscustomobject]@{ name = 'demo' })
            eabKID          = 'kid'
            aggregates      = [pscustomobject]@{ totalAccounts = 4; totalOrders = 20; totalCertificatesIssued = 0 }
        }
    }
}

Describe 'Get-TrustAcmeServer' -Tags 'Unit' {

    BeforeEach {
        Mock -CommandName 'Invoke-TrustGraphQL' -ModuleName $ModuleName -MockWith {
            [pscustomobject]@{
                searchACMEServers = [pscustomobject]@{
                    pageInfo = [pscustomobject]@{ endCursor = 'c1'; hasNextPage = $false }
                    nodes    = @(New-AcmeNode -Name 'GM ACME')
                }
            }
        }
    }

    It 'Should get all servers across pages' {
        $script:afterSent = [System.Collections.Generic.List[object]]::new()
        Mock -CommandName 'Invoke-TrustGraphQL' -ModuleName $ModuleName -MockWith {
            # the variables are reused between pages, so record what was sent at the time
            $script:afterSent.Add($Variables.after)
            $more = -not $Variables.after
            [pscustomobject]@{
                searchACMEServers = [pscustomobject]@{
                    pageInfo = [pscustomobject]@{ endCursor = 'c1'; hasNextPage = $more }
                    nodes    = @(New-AcmeNode -Name ($(if ($more) { 'first' } else { 'second' })))
                }
            }
        }

        $result = Get-TrustAcmeServer -All

        $result.name | Should -Be @('first', 'second')
        Should -Invoke -CommandName 'Invoke-TrustGraphQL' -ModuleName $ModuleName -Times 2 -Exactly -ParameterFilter { -not $Variables.filter }
        $script:afterSent | Should -Be @($null, 'c1')
    }

    It 'Should return the server details' {
        $result = Get-TrustAcmeServer -All

        $result.name | Should -Be 'GM ACME'
        $result.deactivated | Should -BeFalse
        $result.application.name | Should -Be 'My app'
        $result.issuingTemplate.name | Should -Be 'My template'
        $result.certificateTags | Should -Be @('demo')
        $result.totalAccounts | Should -Be 4
        $result.totalOrders | Should -Be 20
        $result.acmeServerId | Should -Not -BeNullOrEmpty
    }

    It 'Should order by name and request 100 per page' {
        Get-TrustAcmeServer -All

        Should -Invoke -CommandName 'Invoke-TrustGraphQL' -ModuleName $ModuleName -Times 1 -ParameterFilter {
            $Variables.first -eq 100 -and $Variables.orderBy.field -eq 'NAME' -and $Variables.orderBy.direction -eq 'ASC'
        }
    }

    It 'Should not request any secret, only the EAB key id' {
        Get-TrustAcmeServer -All

        Should -Invoke -CommandName 'Invoke-TrustGraphQL' -ModuleName $ModuleName -Times 1 -ParameterFilter { $Query -match 'eabKID' -and $Query -notmatch '(?i)hmac|secret|credential|password' }
    }

    It 'Should filter by id when a guid is provided' {
        $id = '11111111-2222-3333-4444-555555555555'
        Get-TrustAcmeServer -AcmeServer $id

        Should -Invoke -CommandName 'Invoke-TrustGraphQL' -ModuleName $ModuleName -Times 1 -ParameterFilter { $Variables.filter.and.id.eq -eq $id -and -not $Variables.filter.and.name }
    }

    It 'Should filter by name when a name is provided' {
        Get-TrustAcmeServer -AcmeServer 'gm acme'

        Should -Invoke -CommandName 'Invoke-TrustGraphQL' -ModuleName $ModuleName -Times 1 -ParameterFilter { $Variables.filter.and.name.eq -eq 'gm acme' -and -not $Variables.filter.and.id }
    }

    It 'Should filter on deactivated <_>' -ForEach $true, $false {
        $value = $_
        Get-TrustAcmeServer -All -Deactivated $value

        Should -Invoke -CommandName 'Invoke-TrustGraphQL' -ModuleName $ModuleName -Times 1 -ParameterFilter { $Variables.filter.and.deactivated.eq -eq $value }
    }
}
