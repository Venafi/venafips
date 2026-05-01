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
        $sess.AuthType = 'BearerToken'
        $sess.AccessToken = New-TestCredential -UserName 'AccessToken' -Password 'ngts-token'
        $sess.Expires = [DateTime]::UtcNow.AddMinutes(30)
        $sess.Credential = New-TestCredential -UserName 'svc' -Password 'secret'

        $null = Invoke-TrustRestMethod -TrustClient $sess -UriLeaf 'useraccounts' -Method Get

        Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName $ModuleName -Times 1 -ParameterFilter {
            $Uri -eq 'https://api.strata.paloaltonetworks.com/ngts/v1/useraccounts'
        }
    }

    It 'Should send ApiKey header for VC key sessions' {
        $sess = New-TrustClient -VcKey (New-TestCredential -UserName 'VcKey' -Password 'my-api-key') -PassThru

        $null = Invoke-TrustRestMethod -TrustClient $sess -UriLeaf 'useraccounts' -Method Get

        Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName $ModuleName -Times 1 -ParameterFilter {
            $Headers -and $Headers['tppl-api-key'] -eq 'my-api-key'
        }
    }

    It 'Should not refresh a non-expired session' {
        Mock -CommandName 'New-VdcToken' -ModuleName $ModuleName

        $sess = New-TrustClient -VcAccessToken 'dummy' -PassThru
        $sess.Platform = 'VDC'
        $sess.Server = 'https://venafi.example.com'
        $sess.AuthType = 'BearerToken'
        $sess.AccessToken = New-TestCredential -UserName 'AccessToken' -Password 'valid'
        $sess.Expires = [DateTime]::UtcNow.AddMinutes(30)

        $null = Invoke-TrustRestMethod -TrustClient $sess -UriRoot 'vedsdk' -UriLeaf 'Certificates' -Method Get

        Should -Invoke -CommandName 'New-VdcToken' -ModuleName $ModuleName -Times 0
    }

    It 'Should throw when expired and cannot refresh' {
        $sess = New-TrustClient -VcAccessToken 'dummy' -PassThru
        $sess.Platform = 'VDC'
        $sess.Server = 'https://venafi.example.com'
        $sess.AuthType = 'BearerToken'
        $sess.AccessToken = New-TestCredential -UserName 'AccessToken' -Password 'expired'
        $sess.Expires = [DateTime]::UtcNow.AddSeconds(-10)
        # No RefreshToken, AuthServer, or ClientId — CanRefresh() is false

        { Invoke-TrustRestMethod -TrustClient $sess -UriRoot 'vedsdk' -UriLeaf 'Certificates' -Method Get } |
            Should -Throw '*expired*'
    }
}

Describe 'New-TrustClient Additional Parameter Sets' -Tags 'Unit' {

    BeforeEach {
        Mock -CommandName 'Invoke-TrustRestMethod' -ModuleName $ModuleName -MockWith { @{} }
        Mock -CommandName 'Get-VdcCustomField' -ModuleName $ModuleName -MockWith { [pscustomobject]@{ Items = @() } }
    }

    Context 'VDC AccessToken (existing token)' {
        It 'Should create VDC session from an existing access token string' {
            $sess = New-TrustClient -Server 'venafi.example.com' -AccessToken 'my-token' -PassThru

            $sess.Platform | Should -Be 'VDC'
            $sess.AuthType | Should -Be 'BearerToken'
            $sess.AccessToken | Should -Not -BeNullOrEmpty
            $sess.Expires | Should -BeGreaterThan (Get-Date).ToUniversalTime()
        }

        It 'Should accept a PSCredential for AccessToken' {
            $cred = New-TestCredential -UserName 'AccessToken' -Password 'cred-token'

            $sess = New-TrustClient -Server 'venafi.example.com' -AccessToken $cred -PassThru

            $sess.AccessToken.GetNetworkCredential().Password | Should -Be 'cred-token'
        }

        It 'Should accept a SecureString for AccessToken' {
            $secure = 'secure-token' | ConvertTo-SecureString -AsPlainText -Force

            $sess = New-TrustClient -Server 'venafi.example.com' -AccessToken $secure -PassThru

            $sess.AccessToken | Should -Not -BeNullOrEmpty
        }
    }

    Context 'VDC RefreshToken' {
        BeforeEach {
            Mock -CommandName 'New-VdcToken' -ModuleName $ModuleName -MockWith {
                $token = & (Get-Module $ModuleName) { [TrustToken]::new() }
                $token.Server       = 'https://venafi.example.com'
                $token.AccessToken  = (New-TestCredential -UserName 'AccessToken' -Password 'refreshed-access')
                $token.RefreshToken = (New-TestCredential -UserName 'RefreshToken' -Password 'new-refresh')
                $token.ClientId     = 'VenafiPS-MyApp'
                $token.Expires      = [DateTime]::UtcNow.AddMinutes(30)
                $token.RefreshExpires = [DateTime]::UtcNow.AddHours(1)
                $token
            }
        }

        It 'Should create VDC session from a refresh token' {
            $sess = New-TrustClient -Server 'venafi.example.com' -RefreshToken 'old-refresh' -ClientId 'VenafiPS-MyApp' -PassThru

            $sess.Platform | Should -Be 'VDC'
            $sess.AuthType | Should -Be 'BearerToken'
            $sess.AccessToken | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName 'New-VdcToken' -ModuleName $ModuleName -Times 1
        }
    }

    Context 'NGTS credential session' {
        BeforeEach {
            Mock -CommandName 'New-NgtsToken' -ModuleName $ModuleName -MockWith {
                $token = & (Get-Module $ModuleName) { [TrustToken]::new() }
                $token.Server      = 'https://auth.apps.paloaltonetworks.com'
                $token.AccessToken = (New-TestCredential -UserName 'AccessToken' -Password 'ngts-access')
                $token.Expires     = [DateTime]::UtcNow.AddMinutes(30)
                $token.Scope       = 'tsg_id:1234567890 logging-service:read'
                $token
            }
        }

        It 'Should create NGTS session with credential' {
            $ngtsCred = New-TestCredential -UserName 'svcaccount@1234567890.iam.panserviceaccount.com' -Password 'client-secret'

            $sess = New-TrustClient -NgtsCredential $ngtsCred -PassThru

            $sess.Platform | Should -Be 'NGTS'
            $sess.AuthType | Should -Be 'BearerToken'
            $sess.AccessToken | Should -Not -BeNullOrEmpty
            $sess.Credential | Should -Not -BeNullOrEmpty
            $sess.PlatformData.Tsg | Should -Be '1234567890'
        }

        It 'Should override Tsg when explicitly provided' {
            $ngtsCred = New-TestCredential -UserName 'svcaccount@1234567890.iam.panserviceaccount.com' -Password 'client-secret'

            $sess = New-TrustClient -NgtsCredential $ngtsCred -Tsg 9999999999 -PassThru

            $sess.PlatformData.Tsg | Should -Be 9999999999
        }
    }

    Context 'VC string key' {
        It 'Should accept a plain string for VcKey' {
            $sess = New-TrustClient -VcKey 'my-api-key-string' -PassThru

            $sess.Platform | Should -Be 'VC'
            $sess.AuthType | Should -Be 'ApiKey'
            $sess.ApiKey.GetNetworkCredential().Password | Should -Be 'my-api-key-string'
        }
    }

    Context 'VC access token string' {
        It 'Should accept a plain string for VcAccessToken' {
            $sess = New-TrustClient -VcAccessToken 'vc-bearer-string' -PassThru

            $sess.Platform | Should -Be 'VC'
            $sess.AuthType | Should -Be 'BearerToken'
            $sess.AccessToken.GetNetworkCredential().Password | Should -Be 'vc-bearer-string'
        }
    }
}

Describe 'TrustClient Validate' -Tags 'Unit' {

    It 'Should throw when Platform is None' {
        $client = & (Get-Module $ModuleName) { [TrustClient]::new() }

        { $client.Validate() } | Should -Throw '*Platform must be set*'
    }

    It 'Should throw when AuthType is invalid for platform' {
        $client = & (Get-Module $ModuleName) { [TrustClient]::new() }
        $client.Platform = 'VDC'
        $client.AuthType = 'ApiKey'

        { $client.Validate() } | Should -Throw '*not a valid auth type*'
    }

    It 'Should throw when required properties are missing' {
        $client = & (Get-Module $ModuleName) { [TrustClient]::new() }
        $client.Platform = 'VDC'
        $client.AuthType = 'BearerToken'
        # AccessToken and Server are required but not set

        { $client.Validate() } | Should -Throw '*Missing required properties*'
    }
}

Describe 'TrustClient CanRefresh Negative Cases' -Tags 'Unit' {

    BeforeEach {
        Mock -CommandName 'Invoke-TrustRestMethod' -ModuleName $ModuleName -MockWith { @{} }
    }

    It 'Should return false for VDC without refresh material' {
        $sess = New-TrustClient -VcAccessToken 'dummy' -PassThru
        $sess.Platform = 'VDC'
        # No RefreshToken, AuthServer, or ClientId

        $sess.CanRefresh() | Should -BeFalse
    }

    It 'Should return false for VDC when RefreshExpires is in the past' {
        $sess = New-TrustClient -VcAccessToken 'dummy' -PassThru
        $sess.Platform = 'VDC'
        $sess.RefreshToken = New-TestCredential -UserName 'RefreshToken' -Password 'refresh'
        $sess.AuthServer = 'https://venafi.example.com'
        $sess.ClientId = 'VenafiPS-MyApp'
        $sess.RefreshExpires = [DateTime]::UtcNow.AddMinutes(-5)

        $sess.CanRefresh() | Should -BeFalse
    }

    It 'Should return false for VC ApiKey sessions' {
        $sess = New-TrustClient -VcKey (New-TestCredential -UserName 'VcKey' -Password 'key') -PassThru

        $sess.CanRefresh() | Should -BeFalse
    }

    It 'Should return false for NGTS without credential' {
        $sess = New-TrustClient -VcAccessToken 'dummy' -PassThru
        $sess.Platform = 'NGTS'
        $sess.Credential = $null

        $sess.CanRefresh() | Should -BeFalse
    }
}

Describe 'TrustClient IsExpired Edge Cases' -Tags 'Unit' {

    BeforeEach {
        Mock -CommandName 'Invoke-TrustRestMethod' -ModuleName $ModuleName -MockWith { @{} }
    }

    It 'Should return false when Expires is MinValue (never set)' {
        $sess = New-TrustClient -VcKey (New-TestCredential -UserName 'VcKey' -Password 'key') -PassThru
        # ApiKey sessions have Expires at MinValue

        $sess.IsExpired() | Should -BeFalse
    }
}

Describe 'NGTS Session Refresh' -Tags 'Unit' {

    BeforeEach {
        Mock -CommandName 'Invoke-TrustRestMethod' -ModuleName $ModuleName -MockWith { @{} }
    }

    It 'Should refresh NGTS session via New-NgtsToken and update Auth' {
        Mock -CommandName 'New-NgtsToken' -ModuleName $ModuleName -MockWith {
            $token = & (Get-Module $ModuleName) { [TrustToken]::new() }
            $token.Server      = 'https://auth.apps.paloaltonetworks.com'
            $token.AccessToken = (New-TestCredential -UserName 'AccessToken' -Password 'ngts-refreshed')
            $token.Expires     = [DateTime]::UtcNow.AddMinutes(30)
            $token.Scope       = 'tsg_id:1234567890'
            $token
        }

        $sess = New-TrustClient -VcAccessToken 'dummy' -PassThru
        $sess.Platform = 'NGTS'
        $sess.Server = 'https://api.strata.paloaltonetworks.com'
        $sess.AuthType = 'BearerToken'
        $sess.AccessToken = New-TestCredential -UserName 'AccessToken' -Password 'old-ngts'
        $sess.Expires = [DateTime]::UtcNow.AddSeconds(10)
        $sess.Credential = New-TestCredential -UserName 'svcaccount@1234567890.iam.panserviceaccount.com' -Password 'secret'
        $sess.PlatformData.Tsg = '1234567890'

        & (Get-Module $ModuleName) { Invoke-SessionRefresh -Session $args[0] } $sess

        $sess.AccessToken.GetNetworkCredential().Password | Should -Be 'ngts-refreshed'
        $sess.Expires | Should -BeGreaterThan ([DateTime]::UtcNow)
        Should -Invoke -CommandName 'New-NgtsToken' -ModuleName $ModuleName -Times 1
    }
}
