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

Describe 'New-TrustClient Auth Model' -Tags 'Unit' {

    BeforeEach {
        Mock -CommandName 'Invoke-TrustRestMethod' -ModuleName $ModuleName -MockWith { @{} }
    }

    Context 'Certificate Manager, SaaS key session' {
        It 'Should populate Auth as ApiKey' {
            $apiKey = New-TestCredential -UserName 'VcKey' -Password '9655b66c-8e5e-4b2b-b43e-edfa33b70e5f'

            $sess = New-TrustClient -VcKey $apiKey -PassThru

            $sess.GetType().Name | Should -Be 'TrustClient'
            $sess.Platform | Should -Be 'VC'
            $sess.AuthType | Should -Be 'ApiKey'
            $sess.ApiKey | Should -Not -BeNullOrEmpty
            $sess.AccessToken | Should -BeNullOrEmpty
        }
    }

    Context 'Certificate Manager, SaaS access token session' {
        It 'Should populate Auth as BearerToken' {
            $access = New-TestCredential -UserName 'AccessToken' -Password 'dummy-token'

            $sess = New-TrustClient -VcAccessToken $access -PassThru

            $sess.Platform | Should -Be 'VC'
            $sess.AuthType | Should -Be 'BearerToken'
            $sess.AccessToken | Should -Not -BeNullOrEmpty
            $sess.Expires | Should -BeGreaterThan (Get-Date).ToUniversalTime()
        }
    }

    Context 'Certificate Manager, Self-Hosted token session' {
        BeforeEach {
            Mock -CommandName 'New-VdcToken' -ModuleName $ModuleName -MockWith {
                $token = & (Get-Module $ModuleName) { [TrustToken]::new() }
                $token.Server         = 'https://venafi.example.com'
                $token.AccessToken    = (New-TestCredential -UserName 'AccessToken' -Password 'vdc-token')
                $token.RefreshToken   = (New-TestCredential -UserName 'RefreshToken' -Password 'vdc-refresh')
                $token.Scope          = @{ certificate = 'manage' }
                $token.Identity       = 'admin'
                $token.TokenType      = 'Bearer'
                $token.ClientId       = 'VenafiPS-MyApp'
                $token.Expires        = [DateTime]::UtcNow.AddMinutes(30)
                $token.RefreshExpires = [DateTime]::UtcNow.AddHours(1)
                $token
            }
            Mock -CommandName 'Get-VdcCustomField' -ModuleName $ModuleName -MockWith { [pscustomobject]@{ Items = @() } }
        }

        It 'Should store OAuth material in Auth for VDC token sessions' {
            $cred = New-TestCredential -UserName 'admin' -Password 'secret'
            $scope = @{ certificate = 'manage' }

            $sess = New-TrustClient -Server 'venafi.example.com' -Credential $cred -ClientId 'VenafiPS-MyApp' -Scope $scope -PassThru

            $sess.Platform | Should -Be 'VDC'
            $sess.AuthType | Should -Be 'BearerToken'
            $sess.AccessToken | Should -Not -BeNullOrEmpty
            $sess.RefreshToken | Should -Not -BeNullOrEmpty
            $sess.ClientId | Should -Be 'VenafiPS-MyApp'
            $sess.AuthServer | Should -Be 'https://venafi.example.com'
        }
    }
}

Describe 'TrustClient Refresh Logic' -Tags 'Unit' {

    BeforeEach {
        Mock -CommandName 'Invoke-TrustRestMethod' -ModuleName $ModuleName -ParameterFilter { $UriLeaf -eq 'useraccounts' } -MockWith { @{} }
    }

    Context 'IsExpired' {
        It 'Should return true when token expires within 60 seconds' {
            $sess = New-TrustClient -VcAccessToken 'dummy' -PassThru
            $sess.Expires = [DateTime]::UtcNow.AddSeconds(45)

            $sess.IsExpired() | Should -BeTrue
        }

        It 'Should return false when token expires beyond 60 seconds' {
            $sess = New-TrustClient -VcAccessToken 'dummy' -PassThru
            $sess.Expires = [DateTime]::UtcNow.AddMinutes(5)

            $sess.IsExpired() | Should -BeFalse
        }
    }

    Context 'CanRefresh' {
        It 'Should return true for VDC when refresh material exists' {
            $sess = New-TrustClient -VcAccessToken 'dummy' -PassThru
            $sess.Platform = 'VDC'
            $sess.RefreshToken = New-TestCredential -UserName 'RefreshToken' -Password 'refresh'
            $sess.AuthServer = 'https://venafi.example.com'
            $sess.ClientId = 'VenafiPS-MyApp'
            $sess.RefreshExpires = [DateTime]::UtcNow.AddMinutes(10)

            $sess.CanRefresh() | Should -BeTrue
        }

        It 'Should return true for NGTS when credential exists' {
            $sess = New-TrustClient -VcAccessToken 'dummy' -PassThru
            $sess.Platform = 'NGTS'
            $sess.Credential = New-TestCredential -UserName 'svc' -Password 'secret'

            $sess.CanRefresh() | Should -BeTrue
        }
    }

    Context 'Refresh' {
        It 'Should refresh VDC session via New-VdcToken and update Auth' {
            Mock -CommandName 'New-VdcToken' -ModuleName $ModuleName -MockWith {
                $token = & (Get-Module $ModuleName) { [TrustToken]::new() }
                $token.Server         = 'https://venafi.example.com'
                $token.AccessToken    = (New-TestCredential -UserName 'AccessToken' -Password 'new-access')
                $token.RefreshToken   = (New-TestCredential -UserName 'RefreshToken' -Password 'new-refresh')
                $token.Scope          = @{ certificate = 'manage' }
                $token.ClientId       = 'VenafiPS-MyApp'
                $token.Expires        = [DateTime]::UtcNow.AddMinutes(30)
                $token.RefreshExpires = [DateTime]::UtcNow.AddHours(1)
                $token
            }

            $sess = New-TrustClient -VcAccessToken 'dummy' -PassThru
            $sess.Platform = 'VDC'
            $sess.AuthServer = 'https://venafi.example.com'
            $sess.ClientId = 'VenafiPS-MyApp'
            $sess.RefreshToken = New-TestCredential -UserName 'RefreshToken' -Password 'old-refresh'
            $sess.RefreshExpires = [DateTime]::UtcNow.AddMinutes(5)

            & (Get-Module $ModuleName) { Invoke-SessionRefresh -Session $args[0] } $sess

            $sess.AccessToken | Should -Not -BeNullOrEmpty
            $sess.ClientId | Should -Be 'VenafiPS-MyApp'
            $sess.Expires | Should -BeGreaterThan ([DateTime]::UtcNow)
            Should -Invoke -CommandName 'New-VdcToken' -ModuleName $ModuleName -Times 1
        }

    }
}

Describe 'Invoke-TrustRestMethod Auth Refresh Integration' -Tags 'Unit' {

    BeforeEach {
        Mock -CommandName 'Invoke-TrustRestMethod' -ModuleName $ModuleName -ParameterFilter { $UriLeaf -eq 'useraccounts' } -MockWith { @{} }
        Mock -CommandName 'Invoke-RestMethod' -ModuleName $ModuleName -MockWith { @{ ok = $true } }
    }

    It 'Should refresh an explicitly provided expiring VDC session before request execution' {
        Mock -CommandName 'New-VdcToken' -ModuleName $ModuleName -MockWith {
            $token = & (Get-Module $ModuleName) { [TrustToken]::new() }
            $token.Server         = 'https://venafi.example.com'
            $token.AccessToken    = (New-TestCredential -UserName 'AccessToken' -Password 'vdc-refreshed')
            $token.RefreshToken   = (New-TestCredential -UserName 'RefreshToken' -Password 'vdc-refresh-new')
            $token.Scope          = @{ certificate = 'manage' }
            $token.ClientId       = 'VenafiPS-MyApp'
            $token.Expires        = [DateTime]::UtcNow.AddMinutes(30)
            $token.RefreshExpires = [DateTime]::UtcNow.AddHours(1)
            $token
        }

        $sess = New-TrustClient -VcAccessToken 'dummy' -PassThru
        $sess.Platform = 'VDC'
        $sess.Server = 'https://venafi.example.com'
        $sess.AuthType = 'BearerToken'
        $sess.AccessToken = New-TestCredential -UserName 'AccessToken' -Password 'old'
        $sess.Expires = [DateTime]::UtcNow.AddSeconds(10)
        $sess.RefreshToken = New-TestCredential -UserName 'RefreshToken' -Password 'old-refresh'
        $sess.AuthServer = 'https://venafi.example.com'
        $sess.ClientId = 'VenafiPS-MyApp'
        $sess.RefreshExpires = [DateTime]::UtcNow.AddMinutes(10)

        $null = Invoke-TrustRestMethod -TrustClient $sess -UriRoot 'vedsdk' -UriLeaf 'Authorize/Verify' -Method Get

        Should -Invoke -CommandName 'New-VdcToken' -ModuleName $ModuleName -Times 1
        $sess.Expires | Should -BeGreaterThan ([DateTime]::UtcNow.AddMinutes(20))
    }

    It 'Should use v1 as the default UriRoot for NGTS sessions' {
        $sess = New-TrustClient -VcAccessToken 'dummy' -PassThru
        $sess.Platform = 'NGTS'
        $sess.Server = 'https://api.strata.paloaltonetworks.com'
        $sess.AuthType = 'ClientCredential'
        $sess.AccessToken = New-TestCredential -UserName 'AccessToken' -Password 'ngts-token'
        $sess.Expires = [DateTime]::UtcNow.AddMinutes(30)
        $sess.Credential = New-TestCredential -UserName 'svc' -Password 'secret'

        $null = Invoke-TrustRestMethod -TrustClient $sess -UriLeaf 'useraccounts' -Method Get

        Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName $ModuleName -Times 1 -ParameterFilter {
            $Uri -eq 'https://api.strata.paloaltonetworks.com/ngts/v1/useraccounts'
        }
    }
}
