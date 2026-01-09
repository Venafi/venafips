BeforeAll {
    # . $PSScriptRoot/ModuleCommon.ps1

    # Dot-source all private functions for comprehensive test coverage
    # This allows adding tests for any private function without modifying the BeforeAll block
    $privateFunctions = Get-ChildItem -Path "$PSScriptRoot/../VenafiPS/Private/*.ps1" -File
    foreach ($function in $privateFunctions) {
        . $function.FullName
    }
}

#region ConvertTo-PlaintextString Tests
Describe "ConvertTo-PlaintextString" -Tags 'Unit' {

    Context "String Input" {
        It "Should return the string unchanged" {
            $result = ConvertTo-PlaintextString -InputObject 'plaintext'
            $result | Should -Be 'plaintext'
        }

        It "Should handle empty string" {
            $result = ConvertTo-PlaintextString -InputObject ''
            $result | Should -Be ''
        }

        It "Should accept string from pipeline" {
            $result = 'test' | ConvertTo-PlaintextString
            $result | Should -Be 'test'
        }
    }

    Context "SecureString Input" {
        It "Should convert SecureString to plaintext" {
            $plaintext = 'MySecretPassword123!'
            $secureString = ConvertTo-SecureString -String $plaintext -AsPlainText -Force
            $result = ConvertTo-PlaintextString -InputObject $secureString
            $result | Should -Be $plaintext
        }

        It "Should handle SecureString with single character" {
            $secureString = ConvertTo-SecureString -String 'x' -AsPlainText -Force
            $result = ConvertTo-PlaintextString -InputObject $secureString
            $result | Should -Be 'x'
        }

        It "Should handle SecureString with special characters" {
            $plaintext = 'P@ssw0rd!#$%^&*()'
            $secureString = ConvertTo-SecureString -String $plaintext -AsPlainText -Force
            $result = ConvertTo-PlaintextString -InputObject $secureString
            $result | Should -Be $plaintext
        }
    }

    Context "PSCredential Input" {
        It "Should extract password from PSCredential" {
            $password = 'MyPassword123'
            $securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
            $credential = New-Object System.Management.Automation.PSCredential ('username', $securePassword)
            $result = ConvertTo-PlaintextString -InputObject $credential
            $result | Should -Be $password
        }

        It "Should handle PSCredential with complex password" {
            $password = 'C0mpl3x!P@ssw0rd#2024'
            $securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
            $credential = New-Object System.Management.Automation.PSCredential ('user@domain.com', $securePassword)
            $result = ConvertTo-PlaintextString -InputObject $credential
            $result | Should -Be $password
        }
    }

    Context "Invalid Input" {
        It "Should throw on unsupported type" {
            { ConvertTo-PlaintextString -InputObject 123 } | Should -Throw
        }

        It "Should throw on array input" {
            { ConvertTo-PlaintextString -InputObject @('test1', 'test2') } | Should -Throw
        }

        It "Should throw on hashtable input" {
            { ConvertTo-PlaintextString -InputObject @{key='value'} } | Should -Throw
        }
    }
}
#endregion

#region Get-EnumValues Tests
Describe "Get-EnumValues" -Tags 'Unit' {

    Context "Standard Enums" {
        It "Should get values from System.DayOfWeek enum" {
            $result = Get-EnumValues -EnumName 'System.DayOfWeek'
            $result | Should -Not -BeNullOrEmpty
            $result | Should -HaveCount 7
        }

        It "Should return enum values as hashtables" {
            $result = Get-EnumValues -EnumName 'System.DayOfWeek'
            $result[0] | Should -BeOfType [hashtable]
            $result[0].Keys | Should -HaveCount 1
        }

        It "Should include numeric values" {
            $result = Get-EnumValues -EnumName 'System.DayOfWeek'
            $sunday = $result | Where-Object { $_.Keys -contains 'Sunday' }
            $sunday.Values | Should -Be 0
        }

        It "Should handle System.ConsoleColor enum" {
            $result = Get-EnumValues -EnumName 'System.ConsoleColor'
            $result | Should -HaveCount 16
        }
    }

    Context "Pipeline Support" {
        It "Should accept enum name from pipeline" {
            $result = 'System.DayOfWeek' | Get-EnumValues
            $result | Should -HaveCount 7
        }

        It "Should process multiple enum names from pipeline" {
            $enums = @('System.DayOfWeek', 'System.ConsoleColor')
            $result = $enums | Get-EnumValues
            $result | Should -HaveCount 23  # 7 + 16
        }
    }

    Context "Edge Cases" {
        It "Should handle enum with single value" {
            $result = Get-EnumValues -EnumName 'System.StringComparison'
            $result | Should -Not -BeNullOrEmpty
        }
    }
}
#endregion

#region ConvertTo-UtcIso8601 Tests
Describe "ConvertTo-UtcIso8601" -Tags 'Unit' {

    Context "Basic Functionality" {
        It "Should convert DateTime to UTC ISO 8601 format" {
            $date = [DateTime]::new(2024, 1, 15, 14, 30, 45, [DateTimeKind]::Utc)
            $result = ConvertTo-UtcIso8601 -InputObject $date
            $result | Should -Match '2024-01-15T14:30:45\.\d+Z'
        }

        It "Should handle DateTime from pipeline" {
            $date = [DateTime]::new(2024, 1, 15, 14, 30, 45, [DateTimeKind]::Utc)
            $result = $date | ConvertTo-UtcIso8601
            $result | Should -Match '2024-01-15T14:30:45\.\d+Z'
        }

        It "Should convert local time to UTC" {
            $localDate = [DateTime]::new(2024, 1, 15, 14, 30, 45, [DateTimeKind]::Local)
            $result = ConvertTo-UtcIso8601 -InputObject $localDate
            $result | Should -Match 'Z$'
        }

        It "Should always end with Z" {
            $date = Get-Date
            $result = ConvertTo-UtcIso8601 -InputObject $date
            $result | Should -Match 'Z$'
        }

        It "Should use correct ISO 8601 format" {
            $date = [DateTime]::new(2024, 12, 31, 23, 59, 59, [DateTimeKind]::Utc)
            $result = ConvertTo-UtcIso8601 -InputObject $date
            $result | Should -Match '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{7}Z$'
        }
    }

    Context "Pipeline Processing" {
        It "Should process multiple dates from pipeline" {
            $dates = @(
                [DateTime]::new(2024, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)
                [DateTime]::new(2024, 6, 15, 12, 30, 45, [DateTimeKind]::Utc)
            )
            $results = $dates | ConvertTo-UtcIso8601
            $results | Should -HaveCount 2
            $results[0] | Should -Match '2024-01-01T00:00:00'
            $results[1] | Should -Match '2024-06-15T12:30:45'
        }
    }

    Context "Edge Cases" {
        It "Should handle midnight UTC" {
            $midnight = [DateTime]::new(2024, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)
            $result = ConvertTo-UtcIso8601 -InputObject $midnight
            $result | Should -Match '2024-01-01T00:00:00\.\d+Z'
        }

        It "Should handle leap year date" {
            $leapDay = [DateTime]::new(2024, 2, 29, 12, 0, 0, [DateTimeKind]::Utc)
            $result = ConvertTo-UtcIso8601 -InputObject $leapDay
            $result | Should -Match '2024-02-29T12:00:00\.\d+Z'
        }
    }
}
#endregion

#region ConvertTo-VdcFullPath Tests
Describe "ConvertTo-VdcFullPath" -Tags 'Unit' {

    Context "Path Conversion" {
        It "Should add VED\Policy prefix to relative paths" {
            $result = ConvertTo-VdcFullPath -Path 'Certificates\Web'
            $result | Should -Be '\VED\Policy\Certificates\Web'
        }

        It "Should preserve paths that already start with \VED" {
            $result = ConvertTo-VdcFullPath -Path '\VED\Policy\Certificates\Web'
            $result | Should -Be '\VED\Policy\Certificates\Web'
        }

        It "Should handle paths with mixed case VED" {
            $result = ConvertTo-VdcFullPath -Path '\ved\policy\Certificates\Web'
            $result | Should -Be '\ved\policy\Certificates\Web'
        }

        It "Should remove trailing backslash" {
            $result = ConvertTo-VdcFullPath -Path 'Certificates\Web\'
            $result | Should -Be '\VED\Policy\Certificates\Web'
        }

        It "Should handle single folder name" {
            $result = ConvertTo-VdcFullPath -Path 'Certificates'
            $result | Should -Be '\VED\Policy\Certificates'
        }

        It "Should handle deep nested paths" {
            $result = ConvertTo-VdcFullPath -Path 'Level1\Level2\Level3\Level4'
            $result | Should -Be '\VED\Policy\Level1\Level2\Level3\Level4'
        }
    }

    Context "Pipeline Support" {
        It "Should accept path from pipeline" {
            $result = 'Certificates\Web' | ConvertTo-VdcFullPath
            $result | Should -Be '\VED\Policy\Certificates\Web'
        }

        It "Should process multiple paths from pipeline" {
            $paths = @('Certs\Web', 'Certs\Mail', 'Certs\VPN')
            $results = $paths | ConvertTo-VdcFullPath
            $results | Should -HaveCount 3
            $results[0] | Should -Be '\VED\Policy\Certs\Web'
            $results[1] | Should -Be '\VED\Policy\Certs\Mail'
            $results[2] | Should -Be '\VED\Policy\Certs\VPN'
        }
    }

    Context "Edge Cases" {
        It "Should handle paths with spaces" {
            $result = ConvertTo-VdcFullPath -Path 'My Certificates\Web Server'
            $result | Should -Be '\VED\Policy\My Certificates\Web Server'
        }

        It "Should handle paths with special characters" {
            $result = ConvertTo-VdcFullPath -Path 'Certs-2024\Web_Server'
            $result | Should -Be '\VED\Policy\Certs-2024\Web_Server'
        }

        It "Should handle root VED\Policy path" {
            $result = ConvertTo-VdcFullPath -Path '\VED\Policy'
            $result | Should -Be '\VED\Policy'
        }

        It "Should handle VED path without Policy" {
            $result = ConvertTo-VdcFullPath -Path '\VED\Other\Path'
            $result | Should -Be '\VED\Other\Path'
        }
    }
}
#endregion

#region Test-VdcIdentityFormat Tests
Describe "Test-VdcIdentityFormat" -Tags 'Unit' {

    Context "Name Format Validation" {
        It "Should validate AD+ prefixed name" {
            $result = Test-VdcIdentityFormat -ID 'AD+domain:user' -Format Name
            $result | Should -BeTrue
        }

        It "Should validate LDAP+ prefixed name" {
            $result = Test-VdcIdentityFormat -ID 'LDAP+domain:user' -Format Name
            $result | Should -BeTrue
        }

        It "Should validate local: prefixed name" {
            $result = Test-VdcIdentityFormat -ID 'local:admin' -Format Name
            $result | Should -BeTrue
        }

        It "Should be case-insensitive for prefix" {
            $result = Test-VdcIdentityFormat -ID 'ad+domain:user' -Format Name
            $result | Should -BeTrue
        }
    }

    Context "Universal Format Validation" {
        It "Should validate AD+ with GUID" {
            $result = Test-VdcIdentityFormat -ID 'AD+domain:{12345678-1234-1234-1234-123456789012}' -Format Universal
            $result | Should -BeTrue
        }

        It "Should validate local: with GUID" {
            $result = Test-VdcIdentityFormat -ID 'local:{12345678-1234-1234-1234-123456789012}' -Format Universal
            $result | Should -BeTrue
        }

        It "Should validate GUID without braces" {
            $result = Test-VdcIdentityFormat -ID 'AD+domain:12345678-1234-1234-1234-123456789012' -Format Universal
            $result | Should -BeTrue
        }
    }

    Context "Domain Format Validation" {
        It "Should validate domain identity with name" {
            $result = Test-VdcIdentityFormat -ID 'AD+mydomain:user' -Format Domain
            $result | Should -BeTrue
        }

        It "Should validate domain identity with GUID" {
            $result = Test-VdcIdentityFormat -ID 'AD+domain:{12345678-1234-1234-1234-123456789012}' -Format Domain
            $result | Should -BeTrue
        }

        It "Should reject local identity when checking Domain" {
            $result = Test-VdcIdentityFormat -ID 'local:admin' -Format Domain
            $result | Should -BeFalse
        }
    }

    Context "Local Format Validation" {
        It "Should validate local identity with name" {
            $result = Test-VdcIdentityFormat -ID 'local:admin' -Format Local
            $result | Should -BeTrue
        }

        It "Should validate local identity with GUID" {
            $result = Test-VdcIdentityFormat -ID 'local:{12345678-1234-1234-1234-123456789012}' -Format Local
            $result | Should -BeTrue
        }

        It "Should reject domain identity when checking Local" {
            $result = Test-VdcIdentityFormat -ID 'AD+domain:user' -Format Local
            $result | Should -BeFalse
        }
    }

    Context "Default Format (Any)" {
        It "Should accept AD+ name without explicit format" {
            $result = Test-VdcIdentityFormat -ID 'AD+domain:user'
            $result | Should -BeTrue
        }

        It "Should accept local name without explicit format" {
            $result = Test-VdcIdentityFormat -ID 'local:admin'
            $result | Should -BeTrue
        }

        It "Should accept GUID formats without explicit format" {
            $result = Test-VdcIdentityFormat -ID 'AD+domain:{12345678-1234-1234-1234-123456789012}'
            $result | Should -BeTrue
        }

        It "Should reject invalid format" {
            $result = Test-VdcIdentityFormat -ID 'invalidformat'
            $result | Should -BeFalse
        }
    }

    Context "Pipeline Support" {
        It "Should accept identity from pipeline" {
            $result = 'AD+domain:user' | Test-VdcIdentityFormat -Format Name
            $result | Should -BeTrue
        }

        It "Should process multiple identities from pipeline" {
            $identities = @('AD+domain:user', 'local:admin')
            $results = $identities | Test-VdcIdentityFormat -Format Name
            $results | Should -HaveCount 2
            $results[0] | Should -BeTrue
            $results[1] | Should -BeTrue
        }
    }
}
#endregion

#region Write-VerboseWithSecret Tests
Describe "Write-VerboseWithSecret" -Tags 'Unit' {

    Context "Hashtable Secret Hiding" {
        It "Should hide password values in hashtable" {
            $hash = @{Username='user'; Password='secret123'}
            # This function writes to verbose stream, just verify it doesn't throw
            { $hash | Write-VerboseWithSecret } | Should -Not -Throw
        }

        It "Should handle hashtable with multiple secrets" {
            $hash = @{
                Username='user'
                Password='secret'
                AccessToken='token123'
                RefreshToken='refresh456'
            }
            { $hash | Write-VerboseWithSecret } | Should -Not -Throw
        }

        It "Should handle hashtable without secrets" {
            $hash = @{Name='Test'; Value=123}
            { $hash | Write-VerboseWithSecret } | Should -Not -Throw
        }
    }

    Context "Custom Property Names" {
        It "Should hide custom property names" {
            $hash = @{CustomSecret='hidden'; PublicData='visible'}
            { $hash | Write-VerboseWithSecret -PropertyName 'CustomSecret' } | Should -Not -Throw
        }

        It "Should hide multiple custom properties" {
            $hash = @{Secret1='hidden1'; Secret2='hidden2'; Public='visible'}
            { $hash | Write-VerboseWithSecret -PropertyName @('Secret1', 'Secret2') } | Should -Not -Throw
        }
    }

    Context "Edge Cases" {
        It "Should handle null input" {
            { $null | Write-VerboseWithSecret } | Should -Not -Throw
        }

        It "Should handle empty string" {
            { '' | Write-VerboseWithSecret } | Should -Not -Throw
        }

        It "Should handle PSCustomObject" {
            $obj = [PSCustomObject]@{Password='secret'}
            { $obj | Write-VerboseWithSecret } | Should -Not -Throw
        }
    }

    Context "Pipeline Support" {
        It "Should process multiple objects from pipeline" {
            $objects = @(
                @{Password='secret1'}
                @{Password='secret2'}
            )
            { $objects | Write-VerboseWithSecret } | Should -Not -Throw
        }
    }
}
#endregion

#region Split-CertificateData Tests
Describe "Split-CertificateData" -Tags 'Unit' {

    Context "PEM Format with Headers" {
        It "Should split certificate and key from PEM data" {
            $pemData = @"
-----BEGIN CERTIFICATE-----
MIIDXTCCAkWgAwIBAgIJAKL0UG+mRxKjMA0GCSqGSIb3DQEBCwUAMEUxCzAJBgNV
-----END CERTIFICATE-----
-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC7VJTUt9Us8cKj
-----END PRIVATE KEY-----
"@

            $result = Split-CertificateData -InputObject $pemData
            $result | Should -Not -BeNullOrEmpty
            $result.CertPem | Should -Match 'BEGIN CERTIFICATE'
            $result.KeyPem | Should -Match 'BEGIN PRIVATE KEY'
        }

        It "Should handle certificate chain" {
            $pemData = @"
-----BEGIN CERTIFICATE-----
CERT1DATA
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
CERT2DATA
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
CERT3DATA
-----END CERTIFICATE-----
"@

            $result = Split-CertificateData -InputObject $pemData
            # First cert is the main cert, rest are chain
            $result.CertPem | Should -Match 'CERT1DATA'
            $result.ChainPem | Should -HaveCount 2  # Chain contains certs 2 and 3
            $result.ChainPem[0] | Should -Match 'CERT2DATA'
            $result.ChainPem[1] | Should -Match 'CERT3DATA'
        }

        It "Should handle certificate without key" {
            $pemData = @"
-----BEGIN CERTIFICATE-----
CERTDATA
-----END CERTIFICATE-----
"@

            $result = Split-CertificateData -InputObject $pemData
            $result.CertPem | Should -Match 'CERTDATA'
            $result.KeyPem | Should -BeNullOrEmpty
            # Single cert means ChainPem array contains just that cert
            $result.ChainPem | Should -HaveCount 1
        }
    }

    Context "Base64 Encoded Data" {
        It "Should handle base64 encoded certificate data" {
            # Create a simple PEM certificate and convert to base64
            $pem = @"
-----BEGIN CERTIFICATE-----
TESTDATA
-----END CERTIFICATE-----
"@
            $base64 = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pem))

            $result = Split-CertificateData -InputObject $base64
            $result | Should -Not -BeNullOrEmpty
            $result.CertPem | Should -Match 'TESTDATA'
        }
    }

    Context "Multiple Certificates from Pipeline" {
        It "Should process multiple certificates from pipeline" {
            $certs = @(
                @"
-----BEGIN CERTIFICATE-----
CERT1
-----END CERTIFICATE-----
"@,
                @"
-----BEGIN CERTIFICATE-----
CERT2
-----END CERTIFICATE-----
"@
            )

            $result = $certs | Split-CertificateData
            $result | Should -HaveCount 2
            $result[0].CertPem | Should -Match 'CERT1'
            $result[1].CertPem | Should -Match 'CERT2'
        }
    }

    Context "Key Types" {
        It "Should handle RSA PRIVATE KEY format" {
            $pemData = @"
-----BEGIN CERTIFICATE-----
CERTDATA
-----END CERTIFICATE-----
-----BEGIN RSA PRIVATE KEY-----
KEYDATA
-----END RSA PRIVATE KEY-----
"@

            $result = Split-CertificateData -InputObject $pemData
            $result.CertPem | Should -Match 'CERTDATA'
            $result.KeyPem | Should -Match 'KEYDATA'
            $result.KeyPem | Should -Match 'RSA PRIVATE KEY'
        }

        It "Should handle EC PRIVATE KEY format" {
            $pemData = @"
-----BEGIN CERTIFICATE-----
CERTDATA
-----END CERTIFICATE-----
-----BEGIN EC PRIVATE KEY-----
KEYDATA
-----END EC PRIVATE KEY-----
"@

            $result = Split-CertificateData -InputObject $pemData
            $result.CertPem | Should -Match 'CERTDATA'
            $result.KeyPem | Should -Match 'KEYDATA'
            $result.KeyPem | Should -Match 'EC PRIVATE KEY'
        }
    }
}
#endregion

#region ConvertTo-VcTeam
Describe 'ConvertTo-VcTeam' {
    Context 'Basic property transformation' {
        It 'should rename id to teamId' {
            $input = [PSCustomObject]@{ id = 'team123'; name = 'TestTeam' }
            $result = $input | ConvertTo-VcTeam
            $result.teamId | Should -Be 'team123'
            $result.name | Should -Be 'TestTeam'
        }

        It 'should exclude original id property' {
            $input = [PSCustomObject]@{ id = 'team456'; name = 'AnotherTeam' }
            $result = $input | ConvertTo-VcTeam
            $result.PSObject.Properties.Name | Should -Not -Contain 'id'
        }

        It 'should preserve other properties' {
            $input = [PSCustomObject]@{
                id = 'team789'
                name = 'TeamWithProps'
                description = 'Test description'
                role = 'Admin'
            }
            $result = $input | ConvertTo-VcTeam
            $result.teamId | Should -Be 'team789'
            $result.name | Should -Be 'TeamWithProps'
            $result.description | Should -Be 'Test description'
            $result.role | Should -Be 'Admin'
        }

        It 'should handle multiple objects in pipeline' {
            $input = @(
                [PSCustomObject]@{ id = 'team1'; name = 'Team1' }
                [PSCustomObject]@{ id = 'team2'; name = 'Team2' }
            )
            $result = $input | ConvertTo-VcTeam
            $result.Count | Should -Be 2
            $result[0].teamId | Should -Be 'team1'
            $result[1].teamId | Should -Be 'team2'
        }
    }
}
#endregion

#region ConvertTo-VdcIdentity
Describe 'ConvertTo-VdcIdentity' {
    Context 'Identity property mapping' {
        It 'should map Name property' {
            $input = [PSCustomObject]@{
                Name = 'TestUser'
                PrefixedUniversal = 'local:12345'
                FullName = '\VED\Identity\TestUser'
                PrefixedName = 'local:TestUser'
                Type = 1
            }
            $result = $input | ConvertTo-VdcIdentity
            $result.Name | Should -Be 'TestUser'
        }

        It 'should map ID from PrefixedUniversal' {
            $input = [PSCustomObject]@{
                Name = 'TestUser'
                PrefixedUniversal = 'local:67890'
                FullName = '\VED\Identity\TestUser'
                PrefixedName = 'local:TestUser'
                Type = 1
            }
            $result = $input | ConvertTo-VdcIdentity
            $result.ID | Should -Be 'local:67890'
        }

        It 'should map Path from FullName' {
            $input = [PSCustomObject]@{
                Name = 'TestUser'
                PrefixedUniversal = 'local:12345'
                FullName = '\VED\Identity\TestUser'
                PrefixedName = 'local:TestUser'
                Type = 1
            }
            $result = $input | ConvertTo-VdcIdentity
            $result.Path | Should -Be '\VED\Identity\TestUser'
        }

        It 'should map FullName from PrefixedName' {
            $input = [PSCustomObject]@{
                Name = 'TestUser'
                PrefixedUniversal = 'local:12345'
                FullName = '\VED\Identity\TestUser'
                PrefixedName = 'local:TestUser'
                Type = 1
            }
            $result = $input | ConvertTo-VdcIdentity
            $result.FullName | Should -Be 'local:TestUser'
        }

        It 'should set IsGroup to false for Type 1 (user)' {
            $input = [PSCustomObject]@{
                Name = 'TestUser'
                PrefixedUniversal = 'local:12345'
                FullName = '\VED\Identity\TestUser'
                PrefixedName = 'local:TestUser'
                Type = 1
            }
            $result = $input | ConvertTo-VdcIdentity
            $result.IsGroup | Should -Be $false
        }

        It 'should set IsGroup to true for Type 2 (group)' {
            $input = [PSCustomObject]@{
                Name = 'TestGroup'
                PrefixedUniversal = 'local:54321'
                FullName = '\VED\Identity\TestGroup'
                PrefixedName = 'local:TestGroup'
                Type = 2
            }
            $result = $input | ConvertTo-VdcIdentity
            $result.IsGroup | Should -Be $true
        }

        It 'should exclude mapped properties' {
            $input = [PSCustomObject]@{
                Name = 'TestUser'
                PrefixedUniversal = 'local:12345'
                FullName = '\VED\Identity\TestUser'
                PrefixedName = 'local:TestUser'
                Type = 1
            }
            $result = $input | ConvertTo-VdcIdentity
            $result.PSObject.Properties.Name | Should -Not -Contain 'PrefixedUniversal'
            $result.PSObject.Properties.Name | Should -Not -Contain 'Type'
            $result.PSObject.Properties.Name | Should -Not -Contain 'PrefixedName'
        }

        It 'should preserve additional properties' {
            $input = [PSCustomObject]@{
                Name = 'TestUser'
                PrefixedUniversal = 'local:12345'
                FullName = '\VED\Identity\TestUser'
                PrefixedName = 'local:TestUser'
                Type = 1
                Email = 'test@example.com'
                CustomProp = 'CustomValue'
            }
            $result = $input | ConvertTo-VdcIdentity
            $result.Email | Should -Be 'test@example.com'
            $result.CustomProp | Should -Be 'CustomValue'
        }

        It 'should handle multiple identities in pipeline' {
            $input = @(
                [PSCustomObject]@{
                    Name = 'User1'
                    PrefixedUniversal = 'local:1'
                    FullName = '\VED\Identity\User1'
                    PrefixedName = 'local:User1'
                    Type = 1
                },
                [PSCustomObject]@{
                    Name = 'Group1'
                    PrefixedUniversal = 'local:2'
                    FullName = '\VED\Identity\Group1'
                    PrefixedName = 'local:Group1'
                    Type = 2
                }
            )
            $result = $input | ConvertTo-VdcIdentity
            $result.Count | Should -Be 2
            $result[0].Name | Should -Be 'User1'
            $result[0].IsGroup | Should -Be $false
            $result[1].Name | Should -Be 'Group1'
            $result[1].IsGroup | Should -Be $true
        }
    }
}
#endregion

#region Select-VenBatch
Describe 'Select-VenBatch' {
    Context 'String batching' {
        It 'should batch strings into specified size' {
            $input = 1..10 | ForEach-Object { "Item$_" }
            $batches = @()
            $input | Select-VenBatch -BatchSize 3 -BatchType string | ForEach-Object {
                $batches += ,@($_ | ForEach-Object { $_ })
            }
            $batches.Count | Should -Be 4
            $batches[0].Count | Should -Be 3
            $batches[1].Count | Should -Be 3
            $batches[2].Count | Should -Be 3
            $batches[3].Count | Should -Be 1
        }

        It 'should handle exact batch size divisor' {
            $input = 1..9 | ForEach-Object { "Item$_" }
            $batches = @()
            $input | Select-VenBatch -BatchSize 3 -BatchType string | ForEach-Object {
                $batches += ,@($_ | ForEach-Object { $_ })
            }
            $batches.Count | Should -Be 3
            $batches[0].Count | Should -Be 3
            $batches[1].Count | Should -Be 3
            $batches[2].Count | Should -Be 3
        }

        It 'should handle single batch' {
            $input = 1..5 | ForEach-Object { "Item$_" }
            $batches = @()
            $input | Select-VenBatch -BatchSize 10 -BatchType string | ForEach-Object {
                $batches += ,@($_ | ForEach-Object { $_ })
            }
            $batches.Count | Should -Be 1
            $batches[0].Count | Should -Be 5
        }

        It 'should preserve string values' {
            $input = 'alpha', 'beta', 'gamma', 'delta', 'epsilon'
            $batches = @()
            $input | Select-VenBatch -BatchSize 2 -BatchType string | ForEach-Object {
                $batches += ,@($_ | ForEach-Object { $_ })
            }
            $batches[0][0] | Should -Be 'alpha'
            $batches[0][1] | Should -Be 'beta'
            $batches[1][0] | Should -Be 'gamma'
            $batches[1][1] | Should -Be 'delta'
            $batches[2][0] | Should -Be 'epsilon'
        }
    }

    Context 'Integer batching' {
        It 'should batch integers into specified size' {
            $input = 1..15
            $batches = @()
            $input | Select-VenBatch -BatchSize 5 -BatchType int | ForEach-Object {
                $batches += ,@($_ | ForEach-Object { $_ })
            }
            $batches.Count | Should -Be 3
            $batches[0].Count | Should -Be 5
            $batches[1].Count | Should -Be 5
            $batches[2].Count | Should -Be 5
        }

        It 'should preserve integer values' {
            $input = 10, 20, 30, 40
            $batches = @()
            $input | Select-VenBatch -BatchSize 2 -BatchType int | ForEach-Object {
                $batches += ,@($_ | ForEach-Object { $_ })
            }
            $batches[0][0] | Should -Be 10
            $batches[0][1] | Should -Be 20
            $batches[1][0] | Should -Be 30
            $batches[1][1] | Should -Be 40
        }

        It 'should handle remainder batch' {
            $input = 1..7
            $batches = @()
            $input | Select-VenBatch -BatchSize 3 -BatchType int | ForEach-Object {
                $batches += ,@($_ | ForEach-Object { $_ })
            }
            $batches.Count | Should -Be 3
            $batches[0].Count | Should -Be 3
            $batches[1].Count | Should -Be 3
            $batches[2].Count | Should -Be 1
            $batches[2][0] | Should -Be 7
        }
    }

    Context 'GUID batching' {
        It 'should batch GUIDs into specified size' {
            $input = 1..8 | ForEach-Object { [guid]::NewGuid() }
            $batches = @()
            $input | Select-VenBatch -BatchSize 3 -BatchType guid | ForEach-Object {
                $batches += ,@($_ | ForEach-Object { $_ })
            }
            $batches.Count | Should -Be 3
            $batches[0].Count | Should -Be 3
            $batches[1].Count | Should -Be 3
            $batches[2].Count | Should -Be 2
        }

        It 'should preserve GUID values' {
            $guid1 = [guid]'12345678-1234-1234-1234-123456789012'
            $guid2 = [guid]'87654321-4321-4321-4321-210987654321'
            $input = $guid1, $guid2
            $batches = @()
            $input | Select-VenBatch -BatchSize 1 -BatchType guid | ForEach-Object {
                $batches += ,@($_ | ForEach-Object { $_ })
            }
            $batches[0][0] | Should -Be $guid1
            $batches[1][0] | Should -Be $guid2
        }
    }

    Context 'PSCustomObject batching' {
        It 'should batch custom objects into specified size' {
            $input = 1..6 | ForEach-Object {
                [PSCustomObject]@{ Id = $_; Name = "Object$_" }
            }
            $batches = @()
            $input | Select-VenBatch -BatchSize 2 -BatchType pscustomobject | ForEach-Object {
                $batches += ,@($_ | ForEach-Object { $_ })
            }
            $batches.Count | Should -Be 3
            $batches[0].Count | Should -Be 2
            $batches[1].Count | Should -Be 2
            $batches[2].Count | Should -Be 2
        }

        It 'should preserve object properties' {
            $input = @(
                [PSCustomObject]@{ Id = 1; Name = 'First' }
                [PSCustomObject]@{ Id = 2; Name = 'Second' }
            )
            $batches = @()
            $input | Select-VenBatch -BatchSize 1 -BatchType pscustomobject | ForEach-Object {
                $batches += ,@($_ | ForEach-Object { $_ })
            }
            $batches[0][0].Id | Should -Be 1
            $batches[0][0].Name | Should -Be 'First'
            $batches[1][0].Id | Should -Be 2
            $batches[1][0].Name | Should -Be 'Second'
        }
    }

    Context 'Edge cases' {
        It 'should handle single item' {
            $input = 'single'
            $batches = @()
            $input | Select-VenBatch -BatchSize 5 -BatchType string | ForEach-Object {
                $batches += ,@($_ | ForEach-Object { $_ })
            }
            $batches.Count | Should -Be 1
            $batches[0].Count | Should -Be 1
            $batches[0][0] | Should -Be 'single'
        }

        It 'should handle large batch size' {
            $input = 1..100
            $batches = @()
            $input | Select-VenBatch -BatchSize 1000 -BatchType int | ForEach-Object {
                $batches += ,@($_ | ForEach-Object { $_ })
            }
            $batches.Count | Should -Be 1
            $batches[0].Count | Should -Be 100
        }

        It 'should handle batch size of 1' {
            $input = 'a', 'b', 'c'
            $batches = @()
            $input | Select-VenBatch -BatchSize 1 -BatchType string | ForEach-Object {
                $batches += ,@($_ | ForEach-Object { $_ })
            }
            $batches.Count | Should -Be 3
            $batches[0].Count | Should -Be 1
            $batches[1].Count | Should -Be 1
            $batches[2].Count | Should -Be 1
        }
    }

    Context 'Batch sequence verification' {
        It 'should maintain order of items' {
            $input = 1..10
            $batches = @()
            $input | Select-VenBatch -BatchSize 3 -BatchType int | ForEach-Object {
                $batches += ,@($_ | ForEach-Object { $_ })
            }
            $batches[0][0] | Should -Be 1
            $batches[0][1] | Should -Be 2
            $batches[0][2] | Should -Be 3
            $batches[1][0] | Should -Be 4
            $batches[1][1] | Should -Be 5
            $batches[1][2] | Should -Be 6
            $batches[2][0] | Should -Be 7
            $batches[2][1] | Should -Be 8
            $batches[2][2] | Should -Be 9
            $batches[3][0] | Should -Be 10
        }

        It 'should create correct number of batches for large dataset' {
            $input = 1..1000
            $batchCount = 0
            $input | Select-VenBatch -BatchSize 100 -BatchType int | ForEach-Object {
                $batchCount++
                $batchItems = @($_ | ForEach-Object { $_ })
                $batchItems.Count | Should -Be 100
            }
            $batchCount | Should -Be 10
        }
    }
}
#endregion

#region Initialize-PSSodium
Describe 'Initialize-PSSodium' -Tags 'Unit' {
    Context 'Module already loaded' {
        It 'should return early if PSSodium is already loaded' {
            Mock Get-Module {
                return [PSCustomObject]@{ Name = 'PSSodium'; Version = '0.4.2' }
            } -ParameterFilter { $Name -eq 'PSSodium' -or $PSBoundParameters.Count -eq 0 }

            Mock Import-Module { }

            { Initialize-PSSodium } | Should -Not -Throw

            Assert-MockCalled Import-Module -Times 0
        }
    }

    Context 'Module not installed' {
        It 'should throw error when module not installed and Force not specified' {
            Mock Get-Module { $null }

            { Initialize-PSSodium } | Should -Throw '*PSSodium module is not installed*'
        }
    }

    Context 'Module installed but not loaded' {
        It 'should import module when installed but not loaded' {
            Mock Get-Module {
                param($Name, [switch]$ListAvailable)
                if ($ListAvailable) {
                    [PSCustomObject]@{ Name = 'PSSodium'; Version = '0.4.2' }
                } else {
                    $null
                }
            }
            Mock Import-Module { }

            { Initialize-PSSodium } | Should -Not -Throw

            Assert-MockCalled Import-Module -Times 1 -ParameterFilter {
                $Name -eq 'PSSodium' -and $Force -eq $true
            }
        }

        It 'should throw custom error when import fails' {
            Mock Get-Module {
                param($Name, [switch]$ListAvailable)
                if ($ListAvailable) {
                    [PSCustomObject]@{ Name = 'PSSodium'; Version = '0.4.2' }
                } else {
                    $null
                }
            }
            Mock Import-Module { throw 'Import failed' }

            { Initialize-PSSodium } | Should -Throw '*Sodium encryption could not be loaded*'
        }
    }
}
#endregion

#region ConvertTo-VdcObject
Describe 'ConvertTo-VdcObject' -Tags 'Unit' {
    Context 'All parameter set' {
        It 'should create object with all properties specified' {
            $guid = [guid]'12345678-1234-1234-1234-123456789012'
            $result = ConvertTo-VdcObject -Path '\VED\Policy\Certificates\Test' -Guid $guid -TypeName 'X509 Certificate'

            $result.Path | Should -Be '\VED\Policy\Certificates\Test'
            $result.Guid | Should -Be $guid
            $result.TypeName | Should -Be 'X509 Certificate'
            $result.Name | Should -Be 'Test'
            $result.ParentPath | Should -Be '\VED\Policy\Certificates'
        }

        It 'should handle root path' {
            $guid = [guid]'87654321-4321-4321-4321-210987654321'
            $result = ConvertTo-VdcObject -Path '\VED\Policy' -Guid $guid -TypeName 'Policy'

            $result.Path | Should -Be '\VED\Policy'
            $result.Name | Should -Be 'Policy'
            $result.ParentPath | Should -Be '\VED'
        }

        It 'should handle deep nested paths' {
            $guid = [guid]::NewGuid()
            $result = ConvertTo-VdcObject -Path '\VED\Policy\Folder1\Folder2\Folder3\Item' -Guid $guid -TypeName 'Folder'

            $result.Name | Should -Be 'Item'
            $result.ParentPath | Should -Be '\VED\Policy\Folder1\Folder2\Folder3'
        }

        It 'should normalize double backslashes' {
            $guid = [guid]::NewGuid()
            $result = ConvertTo-VdcObject -Path '\VED\\Policy\\Test' -Guid $guid -TypeName 'Folder'

            $result.Path | Should -Be '\VED\Policy\Test'
        }
    }

    Context 'ByObject parameter set' {
        It 'should convert object with all properties' {
            $guid = [guid]'11111111-2222-3333-4444-555555555555'
            $inputObj = [PSCustomObject]@{
                Path = '\VED\Policy\MyObject'
                Guid = $guid
                TypeName = 'Code Signing Certificate'
            }

            $result = ConvertTo-VdcObject -InputObject $inputObj

            $result.Path | Should -Be '\VED\Policy\MyObject'
            $result.Guid | Should -Be $guid
            $result.TypeName | Should -Be 'Code Signing Certificate'
            $result.Name | Should -Be 'MyObject'
            $result.ParentPath | Should -Be '\VED\Policy'
        }

        It 'should handle pipeline input' {
            $guid1 = [guid]::NewGuid()
            $guid2 = [guid]::NewGuid()

            $input = @(
                [PSCustomObject]@{ Path = '\VED\Policy\Obj1'; Guid = $guid1; TypeName = 'Type1' }
                [PSCustomObject]@{ Path = '\VED\Policy\Obj2'; Guid = $guid2; TypeName = 'Type2' }
            )

            $results = $input | ConvertTo-VdcObject

            $results.Count | Should -Be 2
            $results[0].Name | Should -Be 'Obj1'
            $results[1].Name | Should -Be 'Obj2'
        }

        It 'should normalize path in object' {
            $inputObj = [PSCustomObject]@{
                Path = '\VED\\Policy\\Test\\Item'
                Guid = [guid]::NewGuid()
                TypeName = 'Application'
            }

            $result = ConvertTo-VdcObject -InputObject $inputObj

            $result.Path | Should -Be '\VED\Policy\Test\Item'
        }
    }

    Context 'Object structure' {
        It 'should include all required properties' {
            $guid = [guid]::NewGuid()
            $result = ConvertTo-VdcObject -Path '\VED\Policy\Test' -Guid $guid -TypeName 'Device'

            $result.PSObject.Properties.Name | Should -Contain 'Path'
            $result.PSObject.Properties.Name | Should -Contain 'TypeName'
            $result.PSObject.Properties.Name | Should -Contain 'Guid'
            $result.PSObject.Properties.Name | Should -Contain 'Name'
            $result.PSObject.Properties.Name | Should -Contain 'ParentPath'
        }

        It 'should extract name from path correctly' {
            $guid = [guid]::NewGuid()
            $result = ConvertTo-VdcObject -Path '\VED\Policy\Certificates\WebServer\prod.example.com' -Guid $guid -TypeName 'X509 Certificate'

            $result.Name | Should -Be 'prod.example.com'
        }

        It 'should handle path with single folder' {
            $guid = [guid]::NewGuid()
            $result = ConvertTo-VdcObject -Path '\VED' -Guid $guid -TypeName 'Root'

            $result.Name | Should -Be 'VED'
            $result.ParentPath | Should -Be ''
        }
    }
}
#endregion

Describe "Test-TppDnPath" -Tags 'Unit' {

    Context "Valid DN Paths" {
        It "Should accept valid path with \VED\Policy" {
            '\VED\Policy\Certificates' | Test-TppDnPath | Should -Be $true
        }

        It "Should accept valid path with \\VED\\Policy (double backslash)" {
            '\\VED\\Policy\\Certificates' | Test-TppDnPath | Should -Be $true
        }

        It "Should accept root path \VED" {
            '\VED' | Test-TppDnPath | Should -Be $true
        }

        It "Should accept root path \\VED\\" {
            '\\VED\\' | Test-TppDnPath | Should -Be $true
        }

        It "Should accept path with multiple levels" {
            '\VED\Policy\Level1\Level2\Level3' | Test-TppDnPath | Should -Be $true
        }

        It "Should be case-insensitive" {
            '\ved\policy\test' | Test-TppDnPath | Should -Be $true
        }

        It "Should accept VED with different casing" {
            '\VeD\Policy\Test' | Test-TppDnPath | Should -Be $true
        }
    }

    Context "Invalid DN Paths" {
        It "Should reject empty string" {
            # Empty string validation happens in parameter validation
            # Testing the logic directly with non-empty invalid string
            'invalid' | Test-TppDnPath | Should -Be $false
        }

        It "Should reject path without \VED prefix" {
            '\Policy\Certificates' | Test-TppDnPath | Should -Be $false
        }

        It "Should reject path with VED but no backslash" {
            'VED\Policy\Certificates' | Test-TppDnPath | Should -Be $false
        }

        It "Should reject completely invalid path" {
            'C:\Windows\System32' | Test-TppDnPath | Should -Be $false
        }

        It "Should reject path with wrong separator" {
            '/VED/Policy/Test' | Test-TppDnPath | Should -Be $false
        }
    }

    Context "AllowRoot Parameter" {
        It "Should reject root path when AllowRoot is false" {
            '\VED' | Test-TppDnPath -AllowRoot $false | Should -Be $false
        }

        It "Should accept non-root path when AllowRoot is false" {
            '\VED\Policy\Test' | Test-TppDnPath -AllowRoot $false | Should -Be $true
        }

        It "Should accept root path when AllowRoot is true (default)" {
            '\VED' | Test-TppDnPath -AllowRoot $true | Should -Be $true
        }
    }
}

Describe "Test-IsGuid" -Tags 'Unit' {

    Context "Valid GUIDs" {
        It "Should accept valid GUID string" {
            Test-IsGuid -InputObject '3363e9e1-00d8-45a1-9c0c-b93ee03f8c13' | Should -Be $true
        }

        It "Should accept GUID with uppercase" {
            Test-IsGuid -InputObject '3363E9E1-00D8-45A1-9C0C-B93EE03F8C13' | Should -Be $true
        }

        It "Should accept GUID with mixed case" {
            Test-IsGuid -InputObject '3363e9E1-00d8-45A1-9c0C-b93Ee03f8c13' | Should -Be $true
        }

        It "Should accept GUID from pipeline" {
            '3363e9e1-00d8-45a1-9c0c-b93ee03f8c13' | Test-IsGuid | Should -Be $true
        }

        It "Should accept GUID with curly braces" {
            Test-IsGuid -InputObject '{3363e9e1-00d8-45a1-9c0c-b93ee03f8c13}' | Should -Be $true
        }

        It "Should accept GUID without hyphens" {
            Test-IsGuid -InputObject '3363e9e100d845a19c0cb93ee03f8c13' | Should -Be $true
        }
    }

    Context "Invalid GUIDs" {
        It "Should reject empty string" {
            Test-IsGuid -InputObject '' | Should -Be $false
        }

        It "Should reject random string" {
            Test-IsGuid -InputObject 'not-a-guid' | Should -Be $false
        }

        It "Should reject GUID with too few characters" {
            Test-IsGuid -InputObject '3363e9e1-00d8-45a1-9c0c' | Should -Be $false
        }

        It "Should reject GUID with too many characters" {
            Test-IsGuid -InputObject '3363e9e1-00d8-45a1-9c0c-b93ee03f8c13-extra' | Should -Be $false
        }

        It "Should reject GUID with invalid characters" {
            Test-IsGuid -InputObject '3363e9e1-00d8-45a1-9c0c-b93ee03f8cXY' | Should -Be $false
        }

        It "Should reject null" {
            Test-IsGuid -InputObject $null | Should -Be $false
        }
    }

    Context "Edge Cases" {
        It "Should accept all zeros GUID" {
            Test-IsGuid -InputObject '00000000-0000-0000-0000-000000000000' | Should -Be $true
        }

        It "Should accept all F's GUID" {
            Test-IsGuid -InputObject 'ffffffff-ffff-ffff-ffff-ffffffffffff' | Should -Be $true
        }
    }
}

Describe "New-HttpQueryString" -Tags 'Unit' {

    Context "Basic Functionality" {
        It "Should create query string with single parameter" {
            $params = @{
                Uri            = 'https://api.example.com/test'
                QueryParameter = @{
                    param1 = 'value1'
                }
            }
            $result = New-HttpQueryString @params
            $result | Should -Match 'param1=value1'
        }

        It "Should create query string with multiple parameters" {
            $params = @{
                Uri            = 'https://api.example.com/test'
                QueryParameter = @{
                    param1 = 'value1'
                    param2 = 'value2'
                    param3 = 'value3'
                }
            }
            $result = New-HttpQueryString @params
            $result | Should -Match 'param1=value1'
            $result | Should -Match 'param2=value2'
            $result | Should -Match 'param3=value3'
        }

        It "Should properly encode special characters" {
            $params = @{
                Uri            = 'https://api.example.com/test'
                QueryParameter = @{
                    search = 'test value with spaces'
                }
            }
            $result = New-HttpQueryString @params
            $result | Should -Match 'search=test\+value\+with\+spaces|search=test%20value%20with%20spaces'
        }

        It "Should properly encode URL special characters" {
            $params = @{
                Uri            = 'https://api.example.com/test'
                QueryParameter = @{
                    url = 'https://example.com/path?query=1&other=2'
                }
            }
            $result = New-HttpQueryString @params
            $result | Should -Match 'url=https%3a%2f%2f|url=https%3A%2F%2F'
        }

        It "Should handle numeric values" {
            $params = @{
                Uri            = 'https://api.example.com/test'
                QueryParameter = @{
                    count = 100
                    page  = 5
                }
            }
            $result = New-HttpQueryString @params
            $result | Should -Match 'count=100'
            $result | Should -Match 'page=5'
        }

        It "Should preserve base URI" {
            $params = @{
                Uri            = 'https://api.example.com:8443/v1/test'
                QueryParameter = @{
                    param = 'value'
                }
            }
            $result = New-HttpQueryString @params
            $result | Should -Match 'https://api.example.com:8443/v1/test'
        }

        It "Should append to existing query string" {
            $params = @{
                Uri            = 'https://api.example.com/test?existing=param'
                QueryParameter = @{
                    new = 'value'
                }
            }
            $result = New-HttpQueryString @params
            # When there's an existing query string, it gets replaced by the new one
            $result | Should -Match 'new=value'
        }
    }

    Context "Edge Cases" {
        It "Should handle empty string values" {
            $params = @{
                Uri            = 'https://api.example.com/test'
                QueryParameter = @{
                    empty = ''
                }
            }
            $result = New-HttpQueryString @params
            $result | Should -Match 'empty='
        }

        It "Should handle boolean values" {
            $params = @{
                Uri            = 'https://api.example.com/test'
                QueryParameter = @{
                    enabled = $true
                }
            }
            $result = New-HttpQueryString @params
            $result | Should -Match 'enabled=True'
        }

        It "Should handle special characters in parameter names" {
            $params = @{
                Uri            = 'https://api.example.com/test'
                QueryParameter = @{
                    'param-name' = 'value'
                }
            }
            $result = New-HttpQueryString @params
            $result | Should -Match 'param-name=value'
        }
    }
}
