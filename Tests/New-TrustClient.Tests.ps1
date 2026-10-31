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

            $sess = New-TrustClient -CmsKey $apiKey -PassThru

            $sess.GetType().Name | Should -Be 'TrustClient'
            $sess.Platform | Should -Be 'CMS'
            $sess.AuthType | Should -Be 'ApiKey'
            $sess.ApiKey | Should -Not -BeNullOrEmpty
            $sess.AccessToken | Should -BeNullOrEmpty
        }
    }

    Context 'Certificate Manager, SaaS access token session' {
        It 'Should populate Auth as BearerToken' {
            $access = New-TestCredential -UserName 'AccessToken' -Password 'dummy-token'

            $sess = New-TrustClient -CmsAccessToken $access -PassThru

            $sess.Platform | Should -Be 'CMS'
            $sess.AuthType | Should -Be 'BearerToken'
            $sess.AccessToken | Should -Not -BeNullOrEmpty
            $sess.Expires | Should -BeGreaterThan (Get-Date).ToUniversalTime()
        }
    }

    Context 'Certificate Manager, Self-Hosted token session' {
        BeforeEach {
            Mock -CommandName 'New-CmToken' -ModuleName $ModuleName -MockWith {
                $token = & (Get-Module $ModuleName) { [TrustToken]::new() }
                $token.Server         = 'https://venafi.example.com'
                $token.AccessToken    = (New-TestCredential -UserName 'AccessToken' -Password 'cm-token')
                $token.RefreshToken   = (New-TestCredential -UserName 'RefreshToken' -Password 'cm-refresh')
                $token.Scope          = @{ certificate = 'manage' }
                $token.Identity       = 'admin'
                $token.TokenType      = 'Bearer'
                $token.ClientId       = 'VenafiPS-MyApp'
                $token.Expires        = [DateTime]::UtcNow.AddMinutes(30)
                $token.RefreshExpires = [DateTime]::UtcNow.AddHours(1)
                $token
            }
            Mock -CommandName 'Get-CmCustomField' -ModuleName $ModuleName -MockWith { [pscustomobject]@{ Items = @() } }
        }

        It 'Should store OAuth material in Auth for CM token sessions' {
            $cred = New-TestCredential -UserName 'admin' -Password 'secret'
            $scope = @{ certificate = 'manage' }

            $sess = New-TrustClient -Server 'venafi.example.com' -Credential $cred -ClientId 'VenafiPS-MyApp' -Scope $scope -PassThru

            $sess.Platform | Should -Be 'CM'
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
            $sess = New-TrustClient -CmsAccessToken 'dummy' -PassThru
            $sess.Expires = [DateTime]::UtcNow.AddSeconds(45)

            $sess.IsExpired() | Should -BeTrue
        }

        It 'Should return false when token expires beyond 60 seconds' {
            $sess = New-TrustClient -CmsAccessToken 'dummy' -PassThru
            $sess.Expires = [DateTime]::UtcNow.AddMinutes(5)

            $sess.IsExpired() | Should -BeFalse
        }
    }

    Context 'CanRefresh' {
        It 'Should return true for CM when refresh material exists' {
            $sess = New-TrustClient -CmsAccessToken 'dummy' -PassThru
            $sess.Platform = 'CM'
            $sess.RefreshToken = New-TestCredential -UserName 'RefreshToken' -Password 'refresh'
            $sess.AuthServer = 'https://venafi.example.com'
            $sess.ClientId = 'VenafiPS-MyApp'
            $sess.RefreshExpires = [DateTime]::UtcNow.AddMinutes(10)

            $sess.CanRefresh() | Should -BeTrue
        }

        It 'Should return true for NGTS when credential exists' {
            $sess = New-TrustClient -CmsAccessToken 'dummy' -PassThru
            $sess.Platform = 'NGTS'
            $sess.Credential = New-TestCredential -UserName 'svc' -Password 'secret'

            $sess.CanRefresh() | Should -BeTrue
        }
    }

    Context 'Refresh' {
        It 'Should refresh CM session via New-CmToken and update Auth' {
            Mock -CommandName 'New-CmToken' -ModuleName $ModuleName -MockWith {
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

            $sess = New-TrustClient -CmsAccessToken 'dummy' -PassThru
            $sess.Platform = 'CM'
            $sess.AuthServer = 'https://venafi.example.com'
            $sess.ClientId = 'VenafiPS-MyApp'
            $sess.RefreshToken = New-TestCredential -UserName 'RefreshToken' -Password 'old-refresh'
            $sess.RefreshExpires = [DateTime]::UtcNow.AddMinutes(5)

            & (Get-Module $ModuleName) { Invoke-SessionRefresh -Session $args[0] } $sess

            $sess.AccessToken | Should -Not -BeNullOrEmpty
            $sess.ClientId | Should -Be 'VenafiPS-MyApp'
            $sess.Expires | Should -BeGreaterThan ([DateTime]::UtcNow)
            Should -Invoke -CommandName 'New-CmToken' -ModuleName $ModuleName -Times 1
        }

    }
}

Describe 'Invoke-TrustRestMethod Auth Refresh Integration' -Tags 'Unit' {

    BeforeEach {
        Mock -CommandName 'Invoke-TrustRestMethod' -ModuleName $ModuleName -ParameterFilter { $UriLeaf -eq 'useraccounts' } -MockWith { @{} }
        Mock -CommandName 'Invoke-RestMethod' -ModuleName $ModuleName -MockWith { @{ ok = $true } }
    }

    It 'Should refresh an explicitly provided expiring CM session before request execution' {
        Mock -CommandName 'New-CmToken' -ModuleName $ModuleName -MockWith {
            $token = & (Get-Module $ModuleName) { [TrustToken]::new() }
            $token.Server         = 'https://venafi.example.com'
            $token.AccessToken    = (New-TestCredential -UserName 'AccessToken' -Password 'cm-refreshed')
            $token.RefreshToken   = (New-TestCredential -UserName 'RefreshToken' -Password 'cm-refresh-new')
            $token.Scope          = @{ certificate = 'manage' }
            $token.ClientId       = 'VenafiPS-MyApp'
            $token.Expires        = [DateTime]::UtcNow.AddMinutes(30)
            $token.RefreshExpires = [DateTime]::UtcNow.AddHours(1)
            $token
        }

        $sess = New-TrustClient -CmsAccessToken 'dummy' -PassThru
        $sess.Platform = 'CM'
        $sess.Server = 'https://venafi.example.com'
        $sess.AuthType = 'BearerToken'
        $sess.AccessToken = New-TestCredential -UserName 'AccessToken' -Password 'old'
        $sess.Expires = [DateTime]::UtcNow.AddSeconds(10)
        $sess.RefreshToken = New-TestCredential -UserName 'RefreshToken' -Password 'old-refresh'
        $sess.AuthServer = 'https://venafi.example.com'
        $sess.ClientId = 'VenafiPS-MyApp'
        $sess.RefreshExpires = [DateTime]::UtcNow.AddMinutes(10)

        $null = Invoke-TrustRestMethod -TrustClient $sess -UriRoot 'vedsdk' -UriLeaf 'Authorize/Verify' -Method Get

        Should -Invoke -CommandName 'New-CmToken' -ModuleName $ModuleName -Times 1
        $sess.Expires | Should -BeGreaterThan ([DateTime]::UtcNow.AddMinutes(20))
    }

    It 'Should use v1 as the default UriRoot for NGTS sessions' {
        $sess = New-TrustClient -CmsAccessToken 'dummy' -PassThru
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
        $sess = New-TrustClient -CmsKey (New-TestCredential -UserName 'VcKey' -Password 'my-api-key') -PassThru

        $null = Invoke-TrustRestMethod -TrustClient $sess -UriLeaf 'useraccounts' -Method Get

        Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName $ModuleName -Times 1 -ParameterFilter {
            $Headers -and $Headers['tppl-api-key'] -eq 'my-api-key'
        }
    }

    It 'Should not refresh a non-expired session' {
        Mock -CommandName 'New-CmToken' -ModuleName $ModuleName

        $sess = New-TrustClient -CmsAccessToken 'dummy' -PassThru
        $sess.Platform = 'CM'
        $sess.Server = 'https://venafi.example.com'
        $sess.AuthType = 'BearerToken'
        $sess.AccessToken = New-TestCredential -UserName 'AccessToken' -Password 'valid'
        $sess.Expires = [DateTime]::UtcNow.AddMinutes(30)

        $null = Invoke-TrustRestMethod -TrustClient $sess -UriRoot 'vedsdk' -UriLeaf 'Certificates' -Method Get

        Should -Invoke -CommandName 'New-CmToken' -ModuleName $ModuleName -Times 0
    }

    It 'Should throw when expired and cannot refresh' {
        $sess = New-TrustClient -CmsAccessToken 'dummy' -PassThru
        $sess.Platform = 'CM'
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
        Mock -CommandName 'Get-CmCustomField' -ModuleName $ModuleName -MockWith { [pscustomobject]@{ Items = @() } }
    }

    Context 'CM AccessToken (existing token)' {
        It 'Should create CM session from an existing access token string' {
            $sess = New-TrustClient -Server 'venafi.example.com' -AccessToken 'my-token' -PassThru

            $sess.Platform | Should -Be 'CM'
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

    Context 'CM RefreshToken' {
        BeforeEach {
            Mock -CommandName 'New-CmToken' -ModuleName $ModuleName -MockWith {
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

        It 'Should create CM session from a refresh token' {
            $sess = New-TrustClient -Server 'venafi.example.com' -RefreshToken 'old-refresh' -ClientId 'VenafiPS-MyApp' -PassThru

            $sess.Platform | Should -Be 'CM'
            $sess.AuthType | Should -Be 'BearerToken'
            $sess.AccessToken | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName 'New-CmToken' -ModuleName $ModuleName -Times 1
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

    Context 'NGTS credential vault' {
        BeforeAll {
            # SecretManagement may not be installed where tests run, Mock needs the commands to exist
            if ( -not (Get-Command 'Set-Secret' -ErrorAction SilentlyContinue) ) {
                function global:Set-Secret { [CmdletBinding(SupportsShouldProcess)] param($Name, $Secret, $Vault, $Metadata) }
            }
            if ( -not (Get-Command 'Get-Secret' -ErrorAction SilentlyContinue) ) {
                function global:Get-Secret { param($Name, $Vault) }
            }
            if ( -not (Get-Command 'Get-SecretInfo' -ErrorAction SilentlyContinue) ) {
                function global:Get-SecretInfo { param($Name, $Vault) }
            }
            if ( -not (Get-Command 'Get-SecretVault' -ErrorAction SilentlyContinue) ) {
                function global:Get-SecretVault { param($Name) }
            }
        }

        BeforeEach {
            Mock -CommandName 'New-NgtsToken' -ModuleName $ModuleName -MockWith {
                $token = & (Get-Module $ModuleName) { [TrustToken]::new() }
                $token.Server      = 'https://auth.apps.paloaltonetworks.com'
                $token.AccessToken = (New-TestCredential -UserName 'AccessToken' -Password 'ngts-access')
                $token.Expires     = [DateTime]::UtcNow.AddMinutes(30)
                $token.Scope       = 'tsg_id:1234567890 logging-service:read'
                $token
            }
            Mock -CommandName 'Get-Module' -ModuleName $ModuleName -ParameterFilter { $Name -eq 'Microsoft.PowerShell.SecretManagement' } -MockWith { [pscustomobject]@{ Name = $Name } }
            Mock -CommandName 'Get-SecretVault' -ModuleName $ModuleName -MockWith { [pscustomobject]@{ Name = 'VenafiPS' } }
            Mock -CommandName 'Set-Secret' -ModuleName $ModuleName
            $ngtsCred = New-TestCredential -UserName 'svcaccount@1234567890.iam.panserviceaccount.com' -Password 'client-secret'
        }

        It 'Should save the credential to the vault once the session is created' {
            $sess = New-TrustClient -NgtsCredential $ngtsCred -VaultNgtsCredentialName 'ngts' -PassThru

            $sess.Platform | Should -Be 'NGTS'
            Should -Invoke -CommandName 'Set-Secret' -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter {
                $Name -eq 'ngts' -and $Vault -eq 'VenafiPS' -and
                $Secret.UserName -eq 'svcaccount@1234567890.iam.panserviceaccount.com' -and $Secret.GetNetworkCredential().Password -eq 'client-secret' -and
                -not $Metadata.Tsg
            }
        }

        It 'Should save the Tsg with the credential when provided' {
            $null = New-TrustClient -NgtsCredential $ngtsCred -Tsg 9999999999 -VaultNgtsCredentialName 'ngts' -PassThru

            Should -Invoke -CommandName 'Set-Secret' -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter { $Metadata.Tsg -eq '9999999999' }
        }

        It 'Should not save the credential when it fails to authenticate' {
            Mock -CommandName 'New-NgtsToken' -ModuleName $ModuleName -MockWith { throw 'invalid_client' }

            { New-TrustClient -NgtsCredential $ngtsCred -VaultNgtsCredentialName 'ngts' } | Should -Throw '*invalid_client*'
            Should -Invoke -CommandName 'Set-Secret' -ModuleName $ModuleName -Times 0 -Exactly
        }

        It 'Should create a session from the credential in the vault' {
            Mock -CommandName 'Get-Secret' -ModuleName $ModuleName -MockWith { $ngtsCred }
            Mock -CommandName 'Get-SecretInfo' -ModuleName $ModuleName -MockWith { [pscustomobject]@{ Name = $Name; Metadata = @{} } }

            $sess = New-TrustClient -VaultNgtsCredentialName 'ngts' -PassThru

            $sess.Platform | Should -Be 'NGTS'
            $sess.Credential.UserName | Should -Be 'svcaccount@1234567890.iam.panserviceaccount.com'
            $sess.PlatformData.Tsg | Should -Be '1234567890'
            Should -Invoke -CommandName 'New-NgtsToken' -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter { $Credential.UserName -eq 'svcaccount@1234567890.iam.panserviceaccount.com' -and -not $Tsg }
            Should -Invoke -CommandName 'Set-Secret' -ModuleName $ModuleName -Times 0 -Exactly
        }

        It 'Should use the Tsg saved with the credential' {
            Mock -CommandName 'Get-Secret' -ModuleName $ModuleName -MockWith { $ngtsCred }
            Mock -CommandName 'Get-SecretInfo' -ModuleName $ModuleName -MockWith { [pscustomobject]@{ Name = $Name; Metadata = @{ Tsg = '9999999999' } } }

            $sess = New-TrustClient -VaultNgtsCredentialName 'ngts' -PassThru

            $sess.PlatformData.Tsg | Should -Be 9999999999
            Should -Invoke -CommandName 'New-NgtsToken' -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter { $Tsg -eq 9999999999 }
        }

        It 'Should throw when the vault entry is not found' {
            Mock -CommandName 'Get-Secret' -ModuleName $ModuleName -MockWith {}

            { New-TrustClient -VaultNgtsCredentialName 'missing' } | Should -Throw "*'missing' NGTS credential not found*"
            Should -Invoke -CommandName 'New-NgtsToken' -ModuleName $ModuleName -Times 0 -Exactly
        }
    }

    Context 'VC string key' {
        It 'Should accept a plain string for VcKey' {
            $sess = New-TrustClient -CmsKey 'my-api-key-string' -PassThru

            $sess.Platform | Should -Be 'CMS'
            $sess.AuthType | Should -Be 'ApiKey'
            $sess.ApiKey.GetNetworkCredential().Password | Should -Be 'my-api-key-string'
        }
    }

    Context 'VC access token string' {
        It 'Should accept a plain string for VcAccessToken' {
            $sess = New-TrustClient -CmsAccessToken 'vc-bearer-string' -PassThru

            $sess.Platform | Should -Be 'CMS'
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
        $client.Platform = 'CM'
        $client.AuthType = 'ApiKey'

        { $client.Validate() } | Should -Throw '*not a valid auth type*'
    }

    It 'Should throw when required properties are missing' {
        $client = & (Get-Module $ModuleName) { [TrustClient]::new() }
        $client.Platform = 'CM'
        $client.AuthType = 'BearerToken'
        # AccessToken and Server are required but not set

        { $client.Validate() } | Should -Throw '*Missing required properties*'
    }
}

Describe 'TrustClient CanRefresh Negative Cases' -Tags 'Unit' {

    BeforeEach {
        Mock -CommandName 'Invoke-TrustRestMethod' -ModuleName $ModuleName -MockWith { @{} }
    }

    It 'Should return false for CM without refresh material' {
        $sess = New-TrustClient -CmsAccessToken 'dummy' -PassThru
        $sess.Platform = 'CM'
        # No RefreshToken, AuthServer, or ClientId

        $sess.CanRefresh() | Should -BeFalse
    }

    It 'Should return false for CM when RefreshExpires is in the past' {
        $sess = New-TrustClient -CmsAccessToken 'dummy' -PassThru
        $sess.Platform = 'CM'
        $sess.RefreshToken = New-TestCredential -UserName 'RefreshToken' -Password 'refresh'
        $sess.AuthServer = 'https://venafi.example.com'
        $sess.ClientId = 'VenafiPS-MyApp'
        $sess.RefreshExpires = [DateTime]::UtcNow.AddMinutes(-5)

        $sess.CanRefresh() | Should -BeFalse
    }

    It 'Should return true for CMS ApiKey sessions' {
        $sess = New-TrustClient -CmsKey (New-TestCredential -UserName 'VcKey' -Password 'key') -PassThru

        $sess.CanRefresh() | Should -BeTrue
    }

    It 'Should return false for NGTS without credential' {
        $sess = New-TrustClient -CmsAccessToken 'dummy' -PassThru
        $sess.Platform = 'NGTS'
        $sess.Credential = $null

        $sess.CanRefresh() | Should -BeFalse
    }
}

Describe 'TrustClient IsExpired Edge Cases' -Tags 'Unit' {

    BeforeEach {
        Mock -CommandName 'Invoke-TrustRestMethod' -ModuleName $ModuleName -MockWith { @{} }
    }

    It 'Should return false when Expires is MaxValue (no expiry set)' {
        $sess = New-TrustClient -CmsKey (New-TestCredential -UserName 'VcKey' -Password 'key') -PassThru
        # ApiKey sessions have Expires set to MaxValue when no validityEndDate exists

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

        $sess = New-TrustClient -CmsAccessToken 'dummy' -PassThru
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

Describe 'CMS ApiKey Session Refresh' -Tags 'Unit' {

    BeforeEach {
        Mock -CommandName 'Invoke-TrustRestMethod' -ModuleName $ModuleName -MockWith { @{} }
    }

    It 'Should refresh CMS ApiKey session via Update-CmsApiKey and update ApiKey' {
        Mock -CommandName 'Update-CmsApiKey' -ModuleName $ModuleName -MockWith {
            @{
                ApiKey  = (New-TestCredential -UserName 'ApiKey' -Password 'rotated-key-value')
                Expires = [DateTime]::UtcNow.AddDays(90)
            }
        }

        $sess = New-TrustClient -CmsKey (New-TestCredential -UserName 'VcKey' -Password 'old-key') -PassThru
        $sess.Expires = [DateTime]::UtcNow.AddSeconds(10)

        & (Get-Module $ModuleName) { Invoke-SessionRefresh -Session $args[0] } $sess

        $sess.ApiKey.GetNetworkCredential().Password | Should -Be 'rotated-key-value'
        $sess.Expires | Should -BeGreaterThan ([DateTime]::UtcNow)
        Should -Invoke -CommandName 'Update-CmsApiKey' -ModuleName $ModuleName -Times 1
    }

    It 'Should not refresh a non-expired CMS ApiKey session' {
        Mock -CommandName 'Update-CmsApiKey' -ModuleName $ModuleName
        Mock -CommandName 'Invoke-RestMethod' -ModuleName $ModuleName -MockWith { @{ ok = $true } }

        $sess = New-TrustClient -CmsKey (New-TestCredential -UserName 'VcKey' -Password 'valid-key') -PassThru
        $sess.Expires = [DateTime]::UtcNow.AddDays(30)

        $null = Invoke-TrustRestMethod -TrustClient $sess -UriLeaf 'useraccounts' -Method Get

        Should -Invoke -CommandName 'Update-CmsApiKey' -ModuleName $ModuleName -Times 0
    }
}

Describe 'CM Session Refresh Vault Write-Back' -Tags 'Unit' {

    BeforeAll {
        # SecretManagement may not be installed where tests run, Mock needs the commands to exist
        if ( -not (Get-Command 'Set-Secret' -ErrorAction SilentlyContinue) ) {
            function global:Set-Secret { [CmdletBinding(SupportsShouldProcess)] param($Name, $Secret, $Vault, $Metadata) }
        }
        if ( -not (Get-Command 'Get-SecretInfo' -ErrorAction SilentlyContinue) ) {
            function global:Get-SecretInfo { param($Name, $Vault) }
        }
        if ( -not (Get-Command 'Get-SecretVault' -ErrorAction SilentlyContinue) ) {
            function global:Get-SecretVault { param($Name) }
        }
    }

    BeforeEach {
        Mock -CommandName 'New-CmToken' -ModuleName $ModuleName -MockWith {
            $token = & (Get-Module $ModuleName) { [TrustToken]::new() }
            $token.Server       = 'https://venafi.example.com'
            $token.AccessToken  = (New-TestCredential -UserName 'AccessToken' -Password 'new-access')
            $token.RefreshToken = (New-TestCredential -UserName 'RefreshToken' -Password 'new-refresh')
            $token.ClientId     = 'VenafiPS-MyApp'
            $token.Expires      = [DateTime]::UtcNow.AddMinutes(30)
            $token
        }
        Mock -CommandName 'Get-SecretInfo' -ModuleName $ModuleName -MockWith {
            [pscustomobject]@{ Name = $Name; Metadata = @{ AuthServer = 'https://venafi.example.com'; ClientId = 'VenafiPS-MyApp' } }
        }
        Mock -CommandName 'Set-Secret' -ModuleName $ModuleName
        Mock -CommandName 'Invoke-TrustRestMethod' -ModuleName $ModuleName -MockWith { @{} }
        Mock -CommandName 'Get-CmCustomField' -ModuleName $ModuleName -MockWith { [pscustomobject]@{ Items = @() } }

        $sess = New-TrustClient -CmsAccessToken 'dummy' -PassThru
        $sess.Platform = 'CM'
        $sess.AuthServer = 'https://venafi.example.com'
        $sess.ClientId = 'VenafiPS-MyApp'
        $sess.RefreshToken = New-TestCredential -UserName 'RefreshToken' -Password 'old-refresh'
    }

    It 'Should save the new refresh token and existing metadata to the vault' {
        $sess.VaultRefreshTokenName = 'mcp'

        & (Get-Module $ModuleName) { Invoke-SessionRefresh -Session $args[0] } $sess

        $sess.RefreshToken.GetNetworkCredential().Password | Should -Be 'new-refresh'
        Should -Invoke -CommandName 'Set-Secret' -ModuleName $ModuleName -Times 1 -ParameterFilter {
            $Name -eq 'mcp' -and $Vault -eq 'VenafiPS' -and
            $Secret.GetNetworkCredential().Password -eq 'new-refresh' -and
            $Metadata.ClientId -eq 'VenafiPS-MyApp' -and $Metadata.AuthServer -eq 'https://venafi.example.com'
        }
    }

    It 'Should save the new refresh token when the caller has WhatIf on' {
        $sess.VaultRefreshTokenName = 'mcp'

        try {
            $global:WhatIfPreference = $true
            & (Get-Module $ModuleName) { Invoke-SessionRefresh -Session $args[0] } $sess
        }
        finally {
            $global:WhatIfPreference = $false
        }

        Should -Invoke -CommandName 'Set-Secret' -ModuleName $ModuleName -Times 1 -ParameterFilter {
            $Name -eq 'mcp' -and $PesterBoundParameters.ContainsKey('WhatIf') -and -not $WhatIf
        }
    }

    It 'Should not touch the vault when the session did not come from one' {
        & (Get-Module $ModuleName) { Invoke-SessionRefresh -Session $args[0] } $sess

        Should -Invoke -CommandName 'Set-Secret' -ModuleName $ModuleName -Times 0
    }

    It 'Should keep the refreshed session and warn when the vault cannot be updated' {
        Mock -CommandName 'Set-Secret' -ModuleName $ModuleName -MockWith { throw 'vault locked' }
        $sess.VaultRefreshTokenName = 'mcp'

        $warn = & (Get-Module $ModuleName) { Invoke-SessionRefresh -Session $args[0] } $sess 3>&1 |
            Where-Object { $_ -is [System.Management.Automation.WarningRecord] }

        $sess.AccessToken.GetNetworkCredential().Password | Should -Be 'new-access'
        $warn | Should -Match "vault entry 'mcp'"
        $warn | Should -Match 'vault locked'
    }

    It 'Should remember the vault entry when New-TrustClient saves a refresh token' {
        Mock -CommandName 'Get-Module' -ModuleName $ModuleName -ParameterFilter { $Name -eq 'Microsoft.PowerShell.SecretManagement' } -MockWith { [pscustomobject]@{ Name = $Name } }
        Mock -CommandName 'Get-SecretVault' -ModuleName $ModuleName -MockWith { [pscustomobject]@{ Name = 'VenafiPS' } }
        $newSess = New-TrustClient -Server 'venafi.example.com' -RefreshToken 'old-refresh' -ClientId 'VenafiPS-MyApp' -VaultRefreshTokenName 'mcp' -PassThru

        $newSess.VaultRefreshTokenName | Should -Be 'mcp'
        Should -Invoke -CommandName 'Set-Secret' -ModuleName $ModuleName -Times 1 -ParameterFilter { $Name -eq 'mcp' }
    }
}
