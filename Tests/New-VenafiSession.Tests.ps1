BeforeAll {
    . $PSScriptRoot/ModuleCommon.ps1

    function New-TestCredential {
        param(
            [Parameter(Mandatory)]
            [string] $UserName,

            [Parameter(Mandatory)]
            [string] $Password
        )

        New-Object System.Management.Automation.PSCredential(
            $UserName,
            ($Password | ConvertTo-SecureString -AsPlainText -Force)
        )
    }
}

Describe 'New-VenafiSession Auth Model' -Tags 'Unit' {

    BeforeEach {
        Mock -CommandName 'Invoke-VenafiRestMethod' -ModuleName $ModuleName -MockWith { @{} }
    }

    Context 'Certificate Manager, SaaS key session' {
        It 'Should populate Auth as ApiKey' {
            $apiKey = New-TestCredential -UserName 'VcKey' -Password '9655b66c-8e5e-4b2b-b43e-edfa33b70e5f'

            $sess = New-VenafiSession -VcKey $apiKey -PassThru

            $sess.GetType().Name | Should -Be 'VenafiSession'
            $sess.Platform | Should -Be 'VC'
            $sess.Auth.Type | Should -Be 'ApiKey'
            $sess.Auth.ApiKey | Should -Not -BeNullOrEmpty
            $sess.Auth.AccessToken | Should -BeNullOrEmpty
        }
    }

    Context 'Certificate Manager, SaaS access token session' {
        It 'Should populate Auth as BearerToken' {
            $access = New-TestCredential -UserName 'AccessToken' -Password 'dummy-token'

            $sess = New-VenafiSession -VcAccessToken $access -PassThru

            $sess.Platform | Should -Be 'VC'
            $sess.Auth.Type | Should -Be 'BearerToken'
            $sess.Auth.AccessToken | Should -Not -BeNullOrEmpty
            $sess.Auth.Expires | Should -BeGreaterThan (Get-Date).ToUniversalTime()
        }
    }

    Context 'Certificate Manager, Self-Hosted token session' {
        BeforeEach {
            Mock -CommandName 'New-VdcToken' -ModuleName $ModuleName -MockWith {
                [pscustomobject]@{
                    Server         = 'https://venafi.example.com'
                    AccessToken    = (New-TestCredential -UserName 'AccessToken' -Password 'vdc-token')
                    RefreshToken   = (New-TestCredential -UserName 'RefreshToken' -Password 'vdc-refresh')
                    Scope          = @{ certificate = 'manage' }
                    Identity       = 'admin'
                    TokenType      = 'Bearer'
                    ClientId       = 'VenafiPS-MyApp'
                    Expires        = [DateTime]::UtcNow.AddMinutes(30)
                    RefreshExpires = [DateTime]::UtcNow.AddHours(1)
                }
            }
            Mock -CommandName 'Get-VdcCustomField' -ModuleName $ModuleName -MockWith { [pscustomobject]@{ Items = @() } }
        }

        It 'Should store OAuth material in Auth for VDC token sessions' {
            $cred = New-TestCredential -UserName 'admin' -Password 'secret'
            $scope = @{ certificate = 'manage' }

            $sess = New-VenafiSession -Server 'venafi.example.com' -Credential $cred -ClientId 'VenafiPS-MyApp' -Scope $scope -PassThru

            $sess.Platform | Should -Be 'VDC'
            $sess.Auth.Type | Should -Be 'OAuth'
            $sess.Auth.AccessToken | Should -Not -BeNullOrEmpty
            $sess.Auth.RefreshToken | Should -Not -BeNullOrEmpty
            $sess.Auth.ClientId | Should -Be 'VenafiPS-MyApp'
            $sess.Auth.AuthServer | Should -Be 'https://venafi.example.com'
        }
    }
}

Describe 'VenafiSession Refresh Logic' -Tags 'Unit' {

    BeforeEach {
        Mock -CommandName 'Invoke-VenafiRestMethod' -ModuleName $ModuleName -ParameterFilter { $UriLeaf -eq 'useraccounts' } -MockWith { @{} }
    }

    Context 'IsExpired' {
        It 'Should return true when token expires within 60 seconds' {
            $sess = New-VenafiSession -VcAccessToken 'dummy' -PassThru
            $sess.Auth.Expires = [DateTime]::UtcNow.AddSeconds(45)

            $sess.IsExpired() | Should -BeTrue
        }

        It 'Should return false when token expires beyond 60 seconds' {
            $sess = New-VenafiSession -VcAccessToken 'dummy' -PassThru
            $sess.Auth.Expires = [DateTime]::UtcNow.AddMinutes(5)

            $sess.IsExpired() | Should -BeFalse
        }
    }

    Context 'CanRefresh' {
        It 'Should return true for VDC when refresh material exists' {
            $sess = New-VenafiSession -VcAccessToken 'dummy' -PassThru
            $sess.Platform = 'VDC'
            $sess.Auth.RefreshToken = New-TestCredential -UserName 'RefreshToken' -Password 'refresh'
            $sess.Auth.AuthServer = 'https://venafi.example.com'
            $sess.Auth.ClientId = 'VenafiPS-MyApp'
            $sess.Auth.RefreshExpires = [DateTime]::UtcNow.AddMinutes(10)

            $sess.CanRefresh() | Should -BeTrue
        }

        It 'Should return true for NGTS when credential exists' {
            $sess = New-VenafiSession -VcAccessToken 'dummy' -PassThru
            $sess.Platform = 'NGTS'
            $sess.Auth.Credential = New-TestCredential -UserName 'svc' -Password 'secret'

            $sess.CanRefresh() | Should -BeTrue
        }
    }

    Context 'Refresh' {
        It 'Should refresh VDC session via New-VdcToken and update Auth' {
            Mock -CommandName 'New-VdcToken' -ModuleName $ModuleName -MockWith {
                [pscustomobject]@{
                    Server         = 'https://venafi.example.com'
                    AccessToken    = (New-TestCredential -UserName 'AccessToken' -Password 'new-access')
                    RefreshToken   = (New-TestCredential -UserName 'RefreshToken' -Password 'new-refresh')
                    Scope          = @{ certificate = 'manage' }
                    ClientId       = 'VenafiPS-MyApp'
                    Expires        = [DateTime]::UtcNow.AddMinutes(30)
                    RefreshExpires = [DateTime]::UtcNow.AddHours(1)
                }
            }

            $sess = New-VenafiSession -VcAccessToken 'dummy' -PassThru
            $sess.Platform = 'VDC'
            $sess.Auth.AuthServer = 'https://venafi.example.com'
            $sess.Auth.ClientId = 'VenafiPS-MyApp'
            $sess.Auth.RefreshToken = New-TestCredential -UserName 'RefreshToken' -Password 'old-refresh'
            $sess.Auth.RefreshExpires = [DateTime]::UtcNow.AddMinutes(5)

            $sess.Refresh()

            $sess.Auth.AccessToken | Should -Not -BeNullOrEmpty
            $sess.Auth.ClientId | Should -Be 'VenafiPS-MyApp'
            $sess.Auth.Expires | Should -BeGreaterThan ([DateTime]::UtcNow)
            Should -Invoke -CommandName 'New-VdcToken' -ModuleName $ModuleName -Times 1
        }

    }
}

Describe 'Invoke-VenafiRestMethod Auth Refresh Integration' -Tags 'Unit' {

    BeforeEach {
        Mock -CommandName 'Invoke-VenafiRestMethod' -ModuleName $ModuleName -ParameterFilter { $UriLeaf -eq 'useraccounts' } -MockWith { @{} }
        Mock -CommandName 'Invoke-RestMethod' -ModuleName $ModuleName -MockWith { @{ ok = $true } }
    }

    It 'Should refresh an explicitly provided expiring VDC session before request execution' {
        Mock -CommandName 'New-VdcToken' -ModuleName $ModuleName -MockWith {
            [pscustomobject]@{
                Server         = 'https://venafi.example.com'
                AccessToken    = (New-TestCredential -UserName 'AccessToken' -Password 'vdc-refreshed')
                RefreshToken   = (New-TestCredential -UserName 'RefreshToken' -Password 'vdc-refresh-new')
                Scope          = @{ certificate = 'manage' }
                ClientId       = 'VenafiPS-MyApp'
                Expires        = [DateTime]::UtcNow.AddMinutes(30)
                RefreshExpires = [DateTime]::UtcNow.AddHours(1)
            }
        }

        $sess = New-VenafiSession -VcAccessToken 'dummy' -PassThru
        $sess.Platform = 'VDC'
        $sess.Server = 'https://venafi.example.com'
        $sess.Auth.Type = 'OAuth'
        $sess.Auth.AccessToken = New-TestCredential -UserName 'AccessToken' -Password 'old'
        $sess.Auth.Expires = [DateTime]::UtcNow.AddSeconds(10)
        $sess.Auth.RefreshToken = New-TestCredential -UserName 'RefreshToken' -Password 'old-refresh'
        $sess.Auth.AuthServer = 'https://venafi.example.com'
        $sess.Auth.ClientId = 'VenafiPS-MyApp'
        $sess.Auth.RefreshExpires = [DateTime]::UtcNow.AddMinutes(10)

        $null = Invoke-VenafiRestMethod -VenafiSession $sess -UriRoot 'vedsdk' -UriLeaf 'Authorize/Verify' -Method Get

        Should -Invoke -CommandName 'New-VdcToken' -ModuleName $ModuleName -Times 1
        $sess.Auth.Expires | Should -BeGreaterThan ([DateTime]::UtcNow.AddMinutes(20))
    }

    It 'Should use v1 as the default UriRoot for NGTS sessions' {
        $sess = New-VenafiSession -VcAccessToken 'dummy' -PassThru
        $sess.Platform = 'NGTS'
        $sess.Server = 'https://api.strata.paloaltonetworks.com'
        $sess.Auth.Type = 'BearerToken'
        $sess.Auth.AccessToken = New-TestCredential -UserName 'AccessToken' -Password 'ngts-token'
        $sess.Auth.Expires = [DateTime]::UtcNow.AddMinutes(30)

        $null = Invoke-VenafiRestMethod -VenafiSession $sess -UriLeaf 'useraccounts' -Method Get

        Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName $ModuleName -Times 1 -ParameterFilter {
            $Uri -eq 'https://api.strata.paloaltonetworks.com/ngts/v1/useraccounts'
        }
    }
}
