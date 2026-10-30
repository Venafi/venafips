BeforeAll {
    . $PSScriptRoot/ModuleCommonTrust.ps1

    # Mock needs the command to exist, PSSodium may not be installed where tests run
    if ( -not (Get-Command 'ConvertTo-SodiumEncryptedString' -ErrorAction SilentlyContinue) ) {
        function global:ConvertTo-SodiumEncryptedString { param($Text, $PublicKey) }
    }

    # the keystore api returns a zip of pem files
    function New-KeystoreZip {
        param ([string] $Name)
        $rsa = [System.Security.Cryptography.RSA]::Create(2048)
        $req = [System.Security.Cryptography.X509Certificates.CertificateRequest]::new("CN=$Name", $rsa, 'SHA256', [System.Security.Cryptography.RSASignaturePadding]::Pkcs1)
        $cert = $req.CreateSelfSigned((Get-Date).AddDays(-1), (Get-Date).AddDays(30))
        $certPem = "-----BEGIN CERTIFICATE-----`n{0}`n-----END CERTIFICATE-----`n" -f [Convert]::ToBase64String($cert.RawData, 'InsertLineBreaks')
        $files = @{
            "$Name.crt"           = $certPem
            "$Name.key"           = "-----BEGIN ENCRYPTED PRIVATE KEY-----`nMIIdummy`n-----END ENCRYPTED PRIVATE KEY-----`n"
            "${Name}_root-last.pem" = $certPem
        }
        $ms = [IO.MemoryStream]::new()
        $zip = [IO.Compression.ZipArchive]::new($ms, [IO.Compression.ZipArchiveMode]::Create, $true)
        foreach ($f in $files.GetEnumerator()) {
            $writer = [IO.StreamWriter]::new($zip.CreateEntry($f.Key).Open())
            $writer.Write($f.Value)
            $writer.Dispose()
        }
        $zip.Dispose()
        , $ms.ToArray()
    }
}

# exporting a private key is only supported on PowerShell 7
Describe 'Export-TrustCertificate' -Tags 'Unit' -Skip:($PSVersionTable.PSVersion.Major -lt 7) {

    BeforeEach {
        $certId = '22222222-2222-2222-2222-222222222222'
        $zipBytes = New-KeystoreZip -Name 'test.company.com'

        Mock -CommandName 'Initialize-PSSodium' -ModuleName $ModuleName -MockWith {}
        Mock -CommandName 'Import-Module' -ModuleName $ModuleName -ParameterFilter { $Name -eq 'PSSodium' } -MockWith {}
        Mock -CommandName 'ConvertTo-SodiumEncryptedString' -ModuleName $ModuleName -MockWith { 'encrypted' }
        Mock -CommandName 'Get-TrustCertificate' -ModuleName $ModuleName -MockWith {
            [pscustomobject]@{ certificateId = $certId; certificateName = 'test.company.com'; dekHash = 'abc' }
        }
        Mock -CommandName 'Invoke-TrustRestMethod' -ModuleName $ModuleName -ParameterFilter { $UriLeaf -like 'edgeencryptionkeys/*' } -MockWith {
            [pscustomobject]@{ key = 'publickey' }
        }
        Mock -CommandName 'Invoke-TrustRestMethod' -ModuleName $ModuleName -ParameterFilter { $UriLeaf -like 'certificates/*/keystore' } -MockWith {
            [pscustomobject]@{ StatusCode = 200; Content = $zipBytes }
        }.GetNewClosure()
    }

    Context 'WhatIf' {

        It 'Should export the certificate and key when the caller has WhatIf on and no OutPath is provided' {
            try {
                $global:WhatIfPreference = $true
                $result = Export-TrustCertificate -ID $certId -PrivateKeyPassword 'myPassw0rd!'
            }
            finally {
                $global:WhatIfPreference = $false
            }

            $result.error | Should -BeNullOrEmpty
            $result.KeyPem | Should -Match 'BEGIN ENCRYPTED PRIVATE KEY'
            $result.CertPem | Should -Not -BeNullOrEmpty
        }

        It 'Should not export to OutPath with -WhatIf' {
            Export-TrustCertificate -ID $certId -PrivateKeyPassword 'myPassw0rd!' -OutPath $TestDrive -WhatIf

            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -ModuleName $ModuleName -Times 0 -Exactly
            @(Get-ChildItem -Path $TestDrive -Recurse -File) | Should -HaveCount 0
        }

        It 'Should export to OutPath with -WhatIf:$false when the caller has WhatIf on' {
            try {
                $global:WhatIfPreference = $true
                $result = Export-TrustCertificate -ID $certId -PrivateKeyPassword 'myPassw0rd!' -OutPath $TestDrive -WhatIf:$false
            }
            finally {
                $global:WhatIfPreference = $false
            }

            $result.error | Should -BeNullOrEmpty
            (Get-ChildItem -Path (Join-Path $TestDrive 'test.company.com') -File).Name | Should -Contain 'test.company.com.key'
        }
    }
}
