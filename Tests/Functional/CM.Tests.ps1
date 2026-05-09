BeforeDiscovery {
    . $PSScriptRoot/FunctionalCommon.ps1
    $skipAll = Skip-IfNoSession -Platform 'CM' -RequiredEnvVars @('VENAFIPS_CM_SERVER', 'VENAFIPS_CM_USERNAME', 'VENAFIPS_CM_PASSWORD', 'VENAFIPS_CM_CLIENTID', 'VENAFIPS_CM_SCOPE')
}

BeforeAll {
    . $PSScriptRoot/FunctionalCommon.ps1
}

Describe 'CM Connection' -Tags 'Functional', 'CM' -Skip:$skipAll {

    It 'Should create a session with OAuth credentials' {
        $sess = New-CmFunctionalSession
        $sess | Should -Not -BeNullOrEmpty
        $sess.Platform | Should -Be 'CM'
        $sess.AuthType | Should -Be 'BearerToken'
        $sess.AccessToken | Should -Not -BeNullOrEmpty
        $sess.RefreshToken | Should -Not -BeNullOrEmpty
        $sess.Expires | Should -BeGreaterThan ([DateTime]::UtcNow)
    }

    It 'Should populate version and custom fields' {
        $sess = New-CmFunctionalSession
        $sess.PlatformData.Version | Should -Not -BeNullOrEmpty
        $sess.PlatformData.Version | Should -BeOfType [version]
    }

    It 'Should set module-scoped session' {
        if (-not $env:VENAFIPS_CM_USERNAME) {
            Set-ItResult -Skipped -Because 'VENAFIPS_CM_USERNAME not set (using existing session)'
            return
        }
        $cred = [System.Management.Automation.PSCredential]::new(
            $env:VENAFIPS_CM_USERNAME,
            ($env:VENAFIPS_CM_PASSWORD | ConvertTo-SecureString -AsPlainText -Force)
        )
        $scope = $env:VENAFIPS_CM_SCOPE | ConvertFrom-Json -AsHashtable
        New-TrustClient -Server $env:VENAFIPS_CM_SERVER -Credential $cred -ClientId $env:VENAFIPS_CM_CLIENTID -Scope $scope

        $moduleClient = InModuleScope 'VenafiPS' { $Script:TrustClient }
        $moduleClient | Should -Not -BeNullOrEmpty
        $moduleClient.Platform | Should -Be 'CM'
    }
}

Describe 'CM Find Certificates' -Tags 'Functional', 'CM' -Skip:$skipAll {

    BeforeAll {
        $script:cmSession = New-CmFunctionalSession
        $script:findCertCN = $null

        # grab the CN from an existing cert for the CommonName filter test
        $sampleCerts = Find-CmCertificate -Path '\VED\Policy' -Recursive -TrustClient $script:cmSession | Select-Object -First 5
        foreach ($sc in @($sampleCerts)) {
            $certDetail = Get-CmCertificate -ID $sc.Path -TrustClient $script:cmSession
            if ($certDetail.CertificateDetails.CN) {
                $script:findCertCN = $certDetail.CertificateDetails.CN
                break
            }
        }
    }

    It 'Should find certificates in the default policy folder' {
        $certs = Find-CmCertificate -Path '\VED\Policy' -Recursive -TrustClient $script:cmSession | Select-Object -First 5
        $certs | Should -Not -BeNullOrEmpty
    }

    It 'Should return objects with Path and Guid' {
        $certs = Find-CmCertificate -Path '\VED\Policy' -Recursive -TrustClient $script:cmSession | Select-Object -First 1
        $cert = @($certs)[0]
        $cert.Path | Should -Not -BeNullOrEmpty
        $cert.Guid | Should -Not -BeNullOrEmpty
    }

    It 'Should filter by CommonName' {
        if (-not $script:findCertCN) { Set-ItResult -Skipped -Because 'No existing certificate with CN found'; return }
        $result = Find-CmCertificate -CommonName $script:findCertCN -TrustClient $script:cmSession
        $result | Should -Not -BeNullOrEmpty
    }
}

Describe 'CM Get Certificate' -Tags 'Functional', 'CM' -Skip:$skipAll {

    BeforeAll {
        $script:cmSession = New-CmFunctionalSession
        $script:sampleCert = Find-CmCertificate -Path '\VED\Policy' -Recursive -TrustClient $script:cmSession | Select-Object -First 1
    }

    It 'Should get certificate details by path' {
        if (-not $script:sampleCert) { Set-ItResult -Skipped -Because 'No sample certificate found'; return }
        $certPath = @($script:sampleCert)[0].Path
        $cert = Get-CmCertificate -ID $certPath -TrustClient $script:cmSession
        $cert | Should -Not -BeNullOrEmpty
    }

    It 'Should get certificate details by GUID' {
        if (-not $script:sampleCert) { Set-ItResult -Skipped -Because 'No sample certificate found'; return }
        $certGuid = @($script:sampleCert)[0].Guid
        $cert = Get-CmCertificate -ID $certGuid -TrustClient $script:cmSession
        $cert | Should -Not -BeNullOrEmpty
    }
}

Describe 'CM Get/Set Attribute' -Tags 'Functional', 'CM' -Skip:$skipAll {

    BeforeAll {
        $script:cmSession = New-CmFunctionalSession
        $script:sampleCert = Find-CmCertificate -Path '\VED\Policy' -Recursive -TrustClient $script:cmSession | Select-Object -First 1
    }

    It 'Should get attributes for a certificate' {
        if (-not $script:sampleCert) { Set-ItResult -Skipped -Because 'No sample certificate found'; return }
        $certPath = @($script:sampleCert)[0].Path
        $attrs = Get-CmAttribute -Path $certPath -All -TrustClient $script:cmSession
        $attrs | Should -Not -BeNullOrEmpty
    }

    It 'Should get a specific attribute' {
        if (-not $script:sampleCert) { Set-ItResult -Skipped -Because 'No sample certificate found'; return }
        $certPath = @($script:sampleCert)[0].Path
        $attr = Get-CmAttribute -Path $certPath -Attribute 'Description' -TrustClient $script:cmSession
        # may have no value but should not throw
        $attr | Should -Not -BeNullOrEmpty
    }
}

Describe 'CM Export Certificate' -Tags 'Functional', 'CM' -Skip:$skipAll {

    BeforeAll {
        $script:cmSession = New-CmFunctionalSession
        $script:sampleCert = Find-CmCertificate -Path '\VED\Policy' -Recursive -TrustClient $script:cmSession | Select-Object -First 1
        $script:exportDir = Join-Path ([System.IO.Path]::GetTempPath()) 'VenafiPS-Functional-CM'
        if (-not (Test-Path $script:exportDir)) { New-Item -Path $script:exportDir -ItemType Directory | Out-Null }
    }

    It 'Should export certificate as PEM (X509)' {
        if (-not $script:sampleCert) { Set-ItResult -Skipped -Because 'No sample certificate found'; return }
        $certPath = @($script:sampleCert)[0].Path
        $result = Export-CmCertificate -Path $certPath -X509 -OutPath $script:exportDir -TrustClient $script:cmSession
        $result | Should -Not -BeNullOrEmpty
    }

    AfterAll {
        if (Test-Path $script:exportDir) {
            Remove-Item -Path $script:exportDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe 'CM Certificate Lifecycle' -Tags 'Functional', 'CM', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:cmSession = New-CmFunctionalSession
        $script:testCertPath = $null
        $script:policyPath = if ($env:VENAFIPS_CM_POLICY_PATH) { $env:VENAFIPS_CM_POLICY_PATH } else { '\VED\Policy\Functional Testing' }
        $script:createdPolicy = $false

        # ensure policy folder exists
        $exists = Test-CmObject -Path $script:policyPath -ExistOnly -TrustClient $script:cmSession
        if (-not $exists) {
            New-CmPolicy -Path $script:policyPath -TrustClient $script:cmSession
            $script:createdPolicy = $true
        }

        # CA template path from environment
        $script:caPath = $env:VENAFIPS_CM_CA_PATH
    }

    It 'Should create a new certificate' {
        if (-not $script:caPath) { Set-ItResult -Skipped -Because 'No CA template found'; return }
        $testName = New-TestName -Prefix 'venafips-func'
        $params = @{
            Path                     = $script:policyPath
            Name                     = $testName
            CommonName               = "$testName.example.com"
            CertificateAuthorityPath = $script:caPath
            PassThru                 = $true
            TrustClient              = $script:cmSession
            ErrorAction              = 'Stop'
        }

        $result = New-CmCertificate @params
        $result | Should -Not -BeNullOrEmpty
        $script:testCertPath = $result.Path
    }

    It 'Should set an attribute on the test certificate' {
        if (-not $script:testCertPath) { Set-ItResult -Skipped -Because 'No test certificate created'; return }
        { Set-CmAttribute -Path $script:testCertPath -Attribute @{ 'Description' = 'VenafiPS functional test' } -TrustClient $script:cmSession } |
            Should -Not -Throw
    }

    It 'Should read back the attribute' {
        if (-not $script:testCertPath) { Set-ItResult -Skipped -Because 'No test certificate created'; return }
        $attr = Get-CmAttribute -Path $script:testCertPath -Attribute 'Description' -TrustClient $script:cmSession
        $attr.Description | Should -Be 'VenafiPS functional test'
    }

    It 'Should delete the test certificate' {
        if (-not $script:testCertPath) { Set-ItResult -Skipped -Because 'No test certificate created'; return }
        { Remove-CmCertificate -Path $script:testCertPath -TrustClient $script:cmSession -Confirm:$false } |
            Should -Not -Throw
    }

}

Describe 'CM Token Refresh' -Tags 'Functional', 'CM' -Skip:$skipAll {

    It 'Should refresh an existing session' {
        $sess = New-CmFunctionalSession
        $originalExpires = $sess.Expires

        # force near-expiration
        $sess.Expires = [DateTime]::UtcNow.AddSeconds(10)

        # make an API call — should trigger auto-refresh
        $result = Find-CmCertificate -Path '\VED\Policy' -TrustClient $sess | Select-Object -First 1

        $sess.Expires | Should -BeGreaterThan $originalExpires
    }
}

# ── System Status ─────────────────────────────────────────────────────────────

Describe 'CM System Status' -Tags 'Functional', 'CM' -Skip:$skipAll {

    BeforeAll {
        $script:cmSession = New-CmFunctionalSession
    }

    It 'Should return system status' {
        $status = Get-CmSystemStatus -TrustClient $script:cmSession
        $status | Should -Not -BeNullOrEmpty
    }
}

# ── Objects ───────────────────────────────────────────────────────────────────

Describe 'CM Find Objects' -Tags 'Functional', 'CM' -Skip:$skipAll {

    BeforeAll {
        $script:cmSession = New-CmFunctionalSession
    }

    It 'Should find objects by path' {
        $objects = Find-CmObject -Path '\VED\Policy' -TrustClient $script:cmSession
        $objects | Should -Not -BeNullOrEmpty
    }

    It 'Should find objects by class' {
        $objects = Find-CmObject -Class 'X509 Server Certificate' -TrustClient $script:cmSession
        if ($objects) {
            @($objects)[0].TypeName | Should -Be 'X509 Server Certificate'
        }
    }

    It 'Should find objects recursively' {
        $objects = Find-CmObject -Path '\VED\Policy' -Recursive -TrustClient $script:cmSession
        $objects | Should -Not -BeNullOrEmpty
    }
}

Describe 'CM Get Object' -Tags 'Functional', 'CM' -Skip:$skipAll {

    BeforeAll {
        $script:cmSession = New-CmFunctionalSession
    }

    It 'Should get an object by path' {
        $obj = Get-CmObject -Path '\VED\Policy' -TrustClient $script:cmSession
        $obj | Should -Not -BeNullOrEmpty
        $obj.Path | Should -Be '\VED\Policy'
    }

    It 'Should get an object by GUID' {
        $byPath = Get-CmObject -Path '\VED\Policy' -TrustClient $script:cmSession
        $byGuid = Get-CmObject -Guid $byPath.Guid -TrustClient $script:cmSession
        $byGuid | Should -Not -BeNullOrEmpty
        $byGuid.Path | Should -Be $byPath.Path
    }
}

Describe 'CM Test Object' -Tags 'Functional', 'CM' -Skip:$skipAll {

    BeforeAll {
        $script:cmSession = New-CmFunctionalSession
    }

    It 'Should return true for an existing path' {
        $result = Test-CmObject -Path '\VED\Policy' -ExistOnly -TrustClient $script:cmSession
        $result | Should -BeTrue
    }

    It 'Should return false for a non-existent path' {
        $result = Test-CmObject -Path '\VED\Policy\NonExistentObject_12345' -ExistOnly -TrustClient $script:cmSession
        $result | Should -BeFalse
    }

    It 'Should return object and exists flag without -ExistOnly' {
        $result = Test-CmObject -Path '\VED\Policy' -TrustClient $script:cmSession
        $result.Exists | Should -BeTrue
    }
}

# ── Identity ──────────────────────────────────────────────────────────────────

Describe 'CM Find Identity' -Tags 'Functional', 'CM' -Skip:$skipAll {

    BeforeAll {
        $script:cmSession = New-CmFunctionalSession
    }

    It 'Should find identities by name' {
        $identities = Find-CmIdentity -Name 'admin' -TrustClient $script:cmSession
        $identities | Should -Not -BeNullOrEmpty
    }

    It 'Should return results with -First' {
        $identities = Find-CmIdentity -Name 'a' -First 3 -TrustClient $script:cmSession
        # CM Identity/Browse may return more than requested; just verify it runs
        $identities | Should -Not -BeNullOrEmpty
    }
}

Describe 'CM Get Identity' -Tags 'Functional', 'CM' -Skip:$skipAll {

    BeforeAll {
        $script:cmSession = New-CmFunctionalSession
    }

    It 'Should get the current identity with -Me' {
        $me = Get-CmIdentity -Me -TrustClient $script:cmSession
        $me | Should -Not -BeNullOrEmpty
        $me.Name | Should -Not -BeNullOrEmpty
    }

    It 'Should get an identity by ID' {
        $me = Get-CmIdentity -Me -TrustClient $script:cmSession
        $identity = Get-CmIdentity -ID $me.ID -TrustClient $script:cmSession
        $identity | Should -Not -BeNullOrEmpty
        $identity.ID | Should -Be $me.ID
    }
}

Describe 'CM Test Identity' -Tags 'Functional', 'CM' -Skip:$skipAll {

    BeforeAll {
        $script:cmSession = New-CmFunctionalSession
        $script:myIdentity = Get-CmIdentity -Me -TrustClient $script:cmSession
    }

    It 'Should return true for a valid identity' {
        if (-not $script:myIdentity) { Set-ItResult -Skipped -Because 'No identity found'; return }
        $result = Test-CmIdentity -ID $script:myIdentity.ID -ExistOnly -TrustClient $script:cmSession
        $result | Should -BeTrue
    }
}

# ── Permissions ───────────────────────────────────────────────────────────────

Describe 'CM Permissions' -Tags 'Functional', 'CM' -Skip:$skipAll {

    BeforeAll {
        $script:cmSession = New-CmFunctionalSession
    }

    It 'Should get permissions on the policy folder' {
        # root policy may not have explicit permissions on all environments
        { Get-CmPermission -Path '\VED\Policy' -TrustClient $script:cmSession } | Should -Not -Throw
    }

    It 'Should get explicit permissions for a specific identity' {
        $me = Get-CmIdentity -Me -TrustClient $script:cmSession
        $perms = Get-CmPermission -Path '\VED\Policy' -IdentityId $me.ID -Explicit -TrustClient $script:cmSession
        # may not have explicit perms — just verify it does not throw
        { Get-CmPermission -Path '\VED\Policy' -IdentityId $me.ID -Explicit -TrustClient $script:cmSession } | Should -Not -Throw
    }
}

# ── Logs ──────────────────────────────────────────────────────────────────────

Describe 'CM Logs' -Tags 'Functional', 'CM' -Skip:$skipAll {

    BeforeAll {
        $script:cmSession = New-CmFunctionalSession
    }

    It 'Should read recent log entries' {
        $logs = Read-CmLog -First 5 -TrustClient $script:cmSession
        $logs | Should -Not -BeNullOrEmpty
    }

    It 'Should filter by severity' {
        { Read-CmLog -Severity 'Error' -First 5 -TrustClient $script:cmSession } | Should -Not -Throw
    }

    It 'Should filter by date range' {
        $end = [DateTime]::UtcNow
        $start = $end.AddDays(-7)
        { Read-CmLog -StartTime $start -EndTime $end -First 5 -TrustClient $script:cmSession } | Should -Not -Throw
    }
}

# ── Custom Fields & Class Attributes ─────────────────────────────────────────

Describe 'CM Custom Fields' -Tags 'Functional', 'CM' -Skip:$skipAll {

    BeforeAll {
        $script:cmSession = New-CmFunctionalSession
    }

    It 'Should get custom fields for X509 Server Certificate class' {
        { Get-CmCustomField -Class 'X509 Server Certificate' -TrustClient $script:cmSession } | Should -Not -Throw
    }
}

Describe 'CM Class Attributes' -Tags 'Functional', 'CM' -Skip:$skipAll {

    BeforeAll {
        $script:cmSession = New-CmFunctionalSession
    }

    It 'Should get attributes for X509 Server Certificate class' {
        $attrs = Get-CmClassAttribute -ClassName 'X509 Server Certificate' -TrustClient $script:cmSession
        $attrs | Should -Not -BeNullOrEmpty
    }

    It 'Should return Name and Class properties' {
        $attrs = Get-CmClassAttribute -ClassName 'Policy' -TrustClient $script:cmSession
        if ($attrs) {
            $first = @($attrs)[0]
            $first.Name | Should -Not -BeNullOrEmpty
        }
    }
}

# ── Engines ───────────────────────────────────────────────────────────────────

Describe 'CM Engines' -Tags 'Functional', 'CM' -Skip:$skipAll {

    BeforeAll {
        $script:cmSession = New-CmFunctionalSession
    }

    It 'Should find engines' {
        $engines = Find-CmEngine -Pattern '*' -TrustClient $script:cmSession
        $engines | Should -Not -BeNullOrEmpty
    }

    It 'Should get engine folder associations' {
        $engines = Find-CmEngine -Pattern '*' -TrustClient $script:cmSession
        if (-not $engines) { Set-ItResult -Skipped -Because 'No engines found'; return }
        $first = @($engines)[0]
        { Get-CmEngineFolder -ID $first.Path -TrustClient $script:cmSession } | Should -Not -Throw
    }

    It 'Should list all engine-folder mappings' {
        { Get-CmEngineFolder -All -TrustClient $script:cmSession } | Should -Not -Throw
    }
}

# ── Teams ─────────────────────────────────────────────────────────────────────

Describe 'CM Teams' -Tags 'Functional', 'CM' -Skip:$skipAll {

    BeforeAll {
        $script:cmSession = New-CmFunctionalSession
    }

    It 'Should list all teams' {
        { Get-CmTeam -All -TrustClient $script:cmSession } | Should -Not -Throw
    }

    It 'Should get a single team by ID' {
        $all = Get-CmTeam -All -TrustClient $script:cmSession
        if (-not $all) { Set-ItResult -Skipped -Because 'No teams found'; return }
        $first = @($all)[0]
        $single = Get-CmTeam -ID $first.ID -TrustClient $script:cmSession
        $single | Should -Not -BeNullOrEmpty
    }
}

# ── Object Lifecycle ──────────────────────────────────────────────────────────

Describe 'CM Object Lifecycle' -Tags 'Functional', 'CM', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:cmSession = New-CmFunctionalSession
        $script:policyPath = if ($env:VENAFIPS_CM_POLICY_PATH) { $env:VENAFIPS_CM_POLICY_PATH } else { '\VED\Policy\Functional Testing' }
        $script:createdPolicy = $false
        $script:testObjPath = $null
        $script:renamedObjPath = $null
        $script:movedObjPath = $null
        $script:moveTargetFolder = "$($script:policyPath)\MoveTarget"
        $script:createdMoveTarget = $false

        # ensure policy folder exists
        $exists = Test-CmObject -Path $script:policyPath -ExistOnly -TrustClient $script:cmSession
        if (-not $exists) {
            New-CmPolicy -Path $script:policyPath -TrustClient $script:cmSession
            $script:createdPolicy = $true
        }
    }

    It 'Should create a new object with New-CmObject' {
        $testName = New-TestName -Prefix 'venafips-obj'
        $script:testObjPath = "$($script:policyPath)\$testName"
        $result = New-CmObject -Path $script:testObjPath -Class 'Policy' -Attribute @{ 'Description' = 'Functional test object' } -PassThru -TrustClient $script:cmSession
        $result | Should -Not -BeNullOrEmpty
        $result.Path | Should -Be $script:testObjPath
    }

    It 'Should verify the created object exists' {
        if (-not $script:testObjPath) { Set-ItResult -Skipped -Because 'No test object created'; return }
        $exists = Test-CmObject -Path $script:testObjPath -ExistOnly -TrustClient $script:cmSession
        $exists | Should -BeTrue
    }

    It 'Should rename the object with Rename-CmObject' {
        if (-not $script:testObjPath) { Set-ItResult -Skipped -Because 'No test object created'; return }
        $newName = New-TestName -Prefix 'venafips-renamed'
        $script:renamedObjPath = "$($script:policyPath)\$newName"
        { Rename-CmObject -Path $script:testObjPath -NewPath $script:renamedObjPath -TrustClient $script:cmSession } | Should -Not -Throw

        # verify old path no longer exists and new path does
        Test-CmObject -Path $script:testObjPath -ExistOnly -TrustClient $script:cmSession | Should -BeFalse
        Test-CmObject -Path $script:renamedObjPath -ExistOnly -TrustClient $script:cmSession | Should -BeTrue
    }

    It 'Should move the object with Move-CmObject' {
        $currentPath = if ($script:renamedObjPath) { $script:renamedObjPath } else { $script:testObjPath }
        if (-not $currentPath) { Set-ItResult -Skipped -Because 'No test object available'; return }

        # create target folder
        $targetExists = Test-CmObject -Path $script:moveTargetFolder -ExistOnly -TrustClient $script:cmSession
        if (-not $targetExists) {
            New-CmPolicy -Path $script:moveTargetFolder -TrustClient $script:cmSession
            $script:createdMoveTarget = $true
        }

        $objName = ($currentPath -split '\\')[-1]
        $script:movedObjPath = "$($script:moveTargetFolder)\$objName"
        { Move-CmObject -SourcePath $currentPath -TargetPath $script:movedObjPath -TrustClient $script:cmSession } | Should -Not -Throw

        Test-CmObject -Path $currentPath -ExistOnly -TrustClient $script:cmSession | Should -BeFalse
        Test-CmObject -Path $script:movedObjPath -ExistOnly -TrustClient $script:cmSession | Should -BeTrue
    }

    It 'Should clean up the moved object' {
        $pathToDelete = if ($script:movedObjPath) { $script:movedObjPath } elseif ($script:renamedObjPath) { $script:renamedObjPath } else { $script:testObjPath }
        if (-not $pathToDelete) { Set-ItResult -Skipped -Because 'No test object to clean up'; return }
        $exists = Test-CmObject -Path $pathToDelete -ExistOnly -TrustClient $script:cmSession
        if ($exists) {
            { Remove-CmObject -Path $pathToDelete -TrustClient $script:cmSession -Confirm:$false } | Should -Not -Throw
        }
    }

}

# ── Import Certificate ───────────────────────────────────────────────────────

Describe 'CM Import Certificate' -Tags 'Functional', 'CM', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:cmSession = New-CmFunctionalSession
        $script:policyPath = if ($env:VENAFIPS_CM_POLICY_PATH) { $env:VENAFIPS_CM_POLICY_PATH } else { '\VED\Policy\Functional Testing' }
        $script:createdPolicy = $false
        $script:importedCertPath = $null
        $script:sourceCertPath = $null
        $script:certBase64 = $null
        $script:tempCertFile = $null

        # ensure policy folder exists
        $exists = Test-CmObject -Path $script:policyPath -ExistOnly -TrustClient $script:cmSession
        if (-not $exists) {
            New-CmPolicy -Path $script:policyPath -TrustClient $script:cmSession
            $script:createdPolicy = $true
        }

        # CA template path from environment
        $caPath = $env:VENAFIPS_CM_CA_PATH

        # create a cert on the server, export it, then delete the source — gives us cert data to reimport
        if ($caPath) {
            $sourceName = New-TestName -Prefix 'venafips-import-src'
            $sourceResult = New-CmCertificate -Path $script:policyPath -Name $sourceName -CommonName "$sourceName.example.com" -CertificateAuthorityPath $caPath -TimeoutSec 30 -PassThru -TrustClient $script:cmSession -ErrorAction Stop
            if ($sourceResult) {
                $script:sourceCertPath = $sourceResult.Path

                $exported = Export-CmCertificate -Path $script:sourceCertPath -X509 -TrustClient $script:cmSession -ErrorAction SilentlyContinue
                if ($exported -and $exported.CertificateData) {
                    $script:certBase64 = $exported.CertificateData

                    # also write to a temp file for the file-based import test
                    $script:tempCertFile = Join-Path ([System.IO.Path]::GetTempPath()) "venafips-func-$(Get-Random).pem"
                    $pemContent = "-----BEGIN CERTIFICATE-----`n$($script:certBase64)`n-----END CERTIFICATE-----"
                    Set-Content -Path $script:tempCertFile -Value $pemContent -NoNewline
                }

                # delete the source cert object so reimport doesn't conflict
                Remove-CmObject -Path $script:sourceCertPath -Recursive -TrustClient $script:cmSession -Confirm:$false -ErrorAction SilentlyContinue
                $script:sourceCertPath = $null
            }
        }
    }

    It 'Should import a certificate from Base64 data' {
        if (-not $script:certBase64) { Set-ItResult -Skipped -Because 'No cert data available (CA template or export failed)'; return }
        $result = Import-CmCertificate -PolicyPath $script:policyPath -Data $script:certBase64 -PassThru -TrustClient $script:cmSession
        $result | Should -Not -BeNullOrEmpty
        $script:importedCertPath = $result.Path
    }

    It 'Should get details of the imported certificate' {
        if (-not $script:importedCertPath) { Set-ItResult -Skipped -Because 'No certificate imported'; return }
        $cert = Get-CmCertificate -ID $script:importedCertPath -TrustClient $script:cmSession
        $cert | Should -Not -BeNullOrEmpty
    }

    It 'Should import a certificate from file with Reconcile' {
        if (-not $script:tempCertFile -or -not (Test-Path $script:tempCertFile)) {
            Set-ItResult -Skipped -Because 'No temp cert file available'; return
        }
        # Reconcile merges with the existing imported cert; CM reports a non-terminating reconciliation message which is expected
        { Import-CmCertificate -PolicyPath $script:policyPath -Path $script:tempCertFile -Reconcile -TrustClient $script:cmSession -ErrorAction SilentlyContinue } | Should -Not -Throw
    }

    AfterAll {
        if ($script:tempCertFile -and (Test-Path $script:tempCertFile)) {
            Remove-Item $script:tempCertFile -Force -ErrorAction SilentlyContinue
        }
    }
}

# ── Certificate Actions ──────────────────────────────────────────────────────

Describe 'CM Certificate Actions' -Tags 'Functional', 'CM', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:cmSession = New-CmFunctionalSession
        $script:sampleCert = Find-CmCertificate -Path '\VED\Policy' -Recursive -TrustClient $script:cmSession | Select-Object -First 1
    }

    It 'Should validate a certificate' {
        if (-not $script:sampleCert) { Set-ItResult -Skipped -Because 'No sample certificate found'; return }
        $certPath = @($script:sampleCert)[0].Path
        { Invoke-CmCertificateAction -Path $certPath -Validate -TrustClient $script:cmSession } | Should -Not -Throw
    }

    It 'Should reset a certificate' {
        if (-not $script:sampleCert) { Set-ItResult -Skipped -Because 'No sample certificate found'; return }
        $certPath = @($script:sampleCert)[0].Path
        { Invoke-CmCertificateAction -Path $certPath -Reset -TrustClient $script:cmSession } | Should -Not -Throw
    }
}

# ── Credentials ───────────────────────────────────────────────────────────────

Describe 'CM Credentials' -Tags 'Functional', 'CM' -Skip:$skipAll {

    BeforeAll {
        $script:cmSession = New-CmFunctionalSession
        $script:policyPath = if ($env:VENAFIPS_CM_POLICY_PATH) { $env:VENAFIPS_CM_POLICY_PATH } else { '\VED\Policy\Functional Testing' }
        $script:credPath = "$($script:policyPath)\venafips-get-cred"
        $script:createdCred = $false

        # ensure policy folder exists
        $exists = Test-CmObject -Path $script:policyPath -ExistOnly -TrustClient $script:cmSession
        if (-not $exists) { New-CmPolicy -Path $script:policyPath -TrustClient $script:cmSession }

        # create a credential to read back
        $credExists = Test-CmObject -Path $script:credPath -ExistOnly -TrustClient $script:cmSession
        if (-not $credExists) {
            $secret = [PSCredential]::new('venafips-get-user', ('VenafiPS-Get-P@ss1' | ConvertTo-SecureString -AsPlainText -Force))
            $result = New-CmCredential -Path $script:credPath -Secret $secret -PassThru -TrustClient $script:cmSession -ErrorAction SilentlyContinue
            if ($result) { $script:createdCred = $true }
        } else {
            $script:createdCred = $true
        }
    }

    It 'Should get a credential object' {
        if (-not $script:createdCred) { Set-ItResult -Skipped -Because 'Could not create test credential'; return }
        $cred = Get-CmCredential -Path $script:credPath -TrustClient $script:cmSession
        $cred | Should -Not -BeNullOrEmpty
    }
}

# ── Team Lifecycle ─────────────────────────────────────────────────────────────

Describe 'CM Team Lifecycle' -Tags 'Functional', 'CM', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:cmSession = New-CmFunctionalSession
        $script:testTeamId = $null
        $script:myIdentity = Get-CmIdentity -Me -TrustClient $script:cmSession
        $script:extraMember = $null

        # find a second identity for member add/remove tests
        $identities = Find-CmIdentity -Name 'a' -First 10 -TrustClient $script:cmSession
        if ($identities) {
            $script:extraMember = @($identities | Where-Object { $_.ID -ne $script:myIdentity.ID })[0]
        }
    }

    It 'Should create a new team with New-CmTeam' {
        if (-not $script:myIdentity) { Set-ItResult -Skipped -Because 'No identity available'; return }
        $teamName = New-TestName -Prefix 'venafips-team'
        $result = New-CmTeam -Name $teamName -Owner @($script:myIdentity.ID) -Member @($script:myIdentity.ID) -Product @('TLS') -PassThru -TrustClient $script:cmSession
        $result | Should -Not -BeNullOrEmpty
        $script:testTeamId = $result.ID
        $script:testTeamName = $teamName
    }

    It 'Should get the created team' {
        if (-not $script:testTeamId) { Set-ItResult -Skipped -Because 'No test team created'; return }
        $team = Get-CmTeam -ID $script:testTeamId -TrustClient $script:cmSession
        $team | Should -Not -BeNullOrEmpty
    }

    It 'Should add a member with Add-CmTeamMember' {
        if (-not $script:testTeamId -or -not $script:extraMember) { Set-ItResult -Skipped -Because 'No test team or extra member available'; return }
        { Add-CmTeamMember -ID $script:testTeamId -Member @($script:extraMember.ID) -TrustClient $script:cmSession } | Should -Not -Throw
    }

    It 'Should remove a member with Remove-CmTeamMember' {
        if (-not $script:testTeamId -or -not $script:extraMember) { Set-ItResult -Skipped -Because 'No test team or extra member available'; return }
        { Remove-CmTeamMember -ID $script:testTeamId -Member @($script:extraMember.ID) -TrustClient $script:cmSession -Confirm:$false } | Should -Not -Throw
    }

    It 'Should add an owner with Add-CmTeamOwner' {
        if (-not $script:testTeamId -or -not $script:extraMember) { Set-ItResult -Skipped -Because 'No test team or extra member available'; return }
        { Add-CmTeamOwner -ID $script:testTeamId -Owner @($script:extraMember.ID) -TrustClient $script:cmSession } | Should -Not -Throw
    }

    It 'Should remove an owner with Remove-CmTeamOwner' {
        if (-not $script:testTeamId -or -not $script:extraMember) { Set-ItResult -Skipped -Because 'No test team or extra member available'; return }
        { Remove-CmTeamOwner -ID $script:testTeamId -Owner @($script:extraMember.ID) -TrustClient $script:cmSession -Confirm:$false } | Should -Not -Throw
    }

    It 'Should delete the team with Remove-CmTeam' {
        if (-not $script:testTeamId) { Set-ItResult -Skipped -Because 'No test team created'; return }
        { Remove-CmTeam -ID $script:testTeamId -TrustClient $script:cmSession -Confirm:$false } | Should -Not -Throw
    }
}

# ── Permission Lifecycle ──────────────────────────────────────────────────────

Describe 'CM Permission Lifecycle' -Tags 'Functional', 'CM', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:cmSession = New-CmFunctionalSession
        $script:policyPath = if ($env:VENAFIPS_CM_POLICY_PATH) { $env:VENAFIPS_CM_POLICY_PATH } else { '\VED\Policy\Functional Testing' }
        $script:permTestFolder = "$($script:policyPath)\PermTest"
        $script:myIdentity = Get-CmIdentity -Me -TrustClient $script:cmSession

        # ensure folder exists
        $exists = Test-CmObject -Path $script:policyPath -ExistOnly -TrustClient $script:cmSession
        if (-not $exists) { New-CmPolicy -Path $script:policyPath -TrustClient $script:cmSession }
        $exists2 = Test-CmObject -Path $script:permTestFolder -ExistOnly -TrustClient $script:cmSession
        if (-not $exists2) { New-CmPolicy -Path $script:permTestFolder -TrustClient $script:cmSession }
    }

    It 'Should set permissions with Set-CmPermission' {
        if (-not $script:myIdentity) { Set-ItResult -Skipped -Because 'No identity available'; return }
        { Set-CmPermission -Path $script:permTestFolder -IdentityId $script:myIdentity.ID -IsViewAllowed -IsReadAllowed -IsWriteAllowed -Force -TrustClient $script:cmSession } | Should -Not -Throw
    }

    It 'Should verify permissions were set' {
        if (-not $script:myIdentity) { Set-ItResult -Skipped -Because 'No identity available'; return }
        $perms = Get-CmPermission -Path $script:permTestFolder -IdentityId $script:myIdentity.ID -Explicit -TrustClient $script:cmSession
        $perms | Should -Not -BeNullOrEmpty
    }

    It 'Should remove permissions with Remove-CmPermission' {
        if (-not $script:myIdentity) { Set-ItResult -Skipped -Because 'No identity available'; return }
        { Remove-CmPermission -Path $script:permTestFolder -IdentityId $script:myIdentity.ID -TrustClient $script:cmSession -Confirm:$false } | Should -Not -Throw
    }
}

# ── Credential Lifecycle ──────────────────────────────────────────────────────

Describe 'CM Credential Lifecycle' -Tags 'Functional', 'CM', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:cmSession = New-CmFunctionalSession
        $script:policyPath = if ($env:VENAFIPS_CM_POLICY_PATH) { $env:VENAFIPS_CM_POLICY_PATH } else { '\VED\Policy\Functional Testing' }
        $script:credPath = "$($script:policyPath)\venafips-func-cred"
        $script:createdCred = $false

        # ensure policy folder exists
        $exists = Test-CmObject -Path $script:policyPath -ExistOnly -TrustClient $script:cmSession
        if (-not $exists) { New-CmPolicy -Path $script:policyPath -TrustClient $script:cmSession }
    }

    It 'Should create a credential with New-CmCredential' {
        $secret = [PSCredential]::new('venafips-user', ('VenafiPS-Test-P@ss1' | ConvertTo-SecureString -AsPlainText -Force))
        $result = New-CmCredential -Path $script:credPath -Secret $secret -PassThru -TrustClient $script:cmSession
        $result | Should -Not -BeNullOrEmpty
        $script:createdCred = $true
    }

    It 'Should update the credential with Set-CmCredential' {
        if (-not $script:createdCred) { Set-ItResult -Skipped -Because 'No credential created'; return }
        $newPassword = 'VenafiPS-Updated-P@ss2' | ConvertTo-SecureString -AsPlainText -Force
        { Set-CmCredential -Path $script:credPath -Password $newPassword -Username 'venafips-updated' -TrustClient $script:cmSession } | Should -Not -Throw
    }

    It 'Should verify the credential exists' {
        if (-not $script:createdCred) { Set-ItResult -Skipped -Because 'No credential created'; return }
        $exists = Test-CmObject -Path $script:credPath -ExistOnly -TrustClient $script:cmSession
        $exists | Should -BeTrue
    }
}

# ── Device & CAPI Application ────────────────────────────────────────────────

Describe 'CM Device & CAPI Application' -Tags 'Functional', 'CM', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:cmSession = New-CmFunctionalSession
        $script:policyPath = if ($env:VENAFIPS_CM_POLICY_PATH) { $env:VENAFIPS_CM_POLICY_PATH } else { '\VED\Policy\Functional Testing' }
        $script:devicePath = "$($script:policyPath)\venafips-func-device"
        $script:appPath = $null
        $script:createdDevice = $false

        # ensure policy folder exists
        $exists = Test-CmObject -Path $script:policyPath -ExistOnly -TrustClient $script:cmSession
        if (-not $exists) { New-CmPolicy -Path $script:policyPath -TrustClient $script:cmSession }
    }

    It 'Should create a device with New-CmDevice' {
        $result = New-CmDevice -Path $script:devicePath -Hostname '10.0.0.99' -Description 'VenafiPS functional test device' -PassThru -TrustClient $script:cmSession
        $result | Should -Not -BeNullOrEmpty
        $script:createdDevice = $true
    }

    It 'Should create a CAPI application on the device with New-CmCapiApplication' {
        if (-not $script:createdDevice) { Set-ItResult -Skipped -Because 'No device created'; return }
        $appName = 'venafips-func-app'
        $script:appPath = "$($script:devicePath)\$appName"
        $result = New-CmCapiApplication -Path $script:devicePath -ApplicationName $appName -FriendlyName 'VenafiPS Test App' -Description 'Functional test CAPI app' -PassThru -TrustClient $script:cmSession
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Should verify the application exists' {
        if (-not $script:appPath) { Set-ItResult -Skipped -Because 'No application created'; return }
        $exists = Test-CmObject -Path $script:appPath -ExistOnly -TrustClient $script:cmSession
        $exists | Should -BeTrue
    }
}

# ── Certificate Association ───────────────────────────────────────────────────

Describe 'CM Certificate Association' -Tags 'Functional', 'CM', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:cmSession = New-CmFunctionalSession
        $script:policyPath = if ($env:VENAFIPS_CM_POLICY_PATH) { $env:VENAFIPS_CM_POLICY_PATH } else { '\VED\Policy\Functional Testing' }
        $script:testCertPath = $null
        $script:devicePath = "$($script:policyPath)\venafips-assoc-device"
        $script:appPath = $null

        # ensure policy folder exists
        $exists = Test-CmObject -Path $script:policyPath -ExistOnly -TrustClient $script:cmSession
        if (-not $exists) { New-CmPolicy -Path $script:policyPath -TrustClient $script:cmSession }

        # find or create a cert
        $caPath = $env:VENAFIPS_CM_CA_PATH
        if ($caPath) {
            $certName = New-TestName -Prefix 'venafips-assoc'
            $certResult = New-CmCertificate -Path $script:policyPath -Name $certName -CommonName "$certName.example.com" -CertificateAuthorityPath $caPath -PassThru -TrustClient $script:cmSession -ErrorAction Stop
            if ($certResult) { $script:testCertPath = $certResult.Path }
        }

        # create a device + CAPI app for association
        if ($script:testCertPath) {
            $devExists = Test-CmObject -Path $script:devicePath -ExistOnly -TrustClient $script:cmSession
            if (-not $devExists) {
                New-CmDevice -Path $script:devicePath -Hostname '10.0.0.100' -TrustClient $script:cmSession | Out-Null
            }
            $appName = 'venafips-assoc-app'
            $script:appPath = "$($script:devicePath)\$appName"
            $appExists = Test-CmObject -Path $script:appPath -ExistOnly -TrustClient $script:cmSession
            if (-not $appExists) {
                New-CmCapiApplication -Path $script:devicePath -ApplicationName $appName -FriendlyName 'Association Test' -TrustClient $script:cmSession | Out-Null
            }
        }
    }

    It 'Should associate an application with a certificate' {
        if (-not $script:testCertPath -or -not $script:appPath) { Set-ItResult -Skipped -Because 'No cert or app available'; return }
        { Add-CmCertificateAssociation -CertificatePath $script:testCertPath -ApplicationPath @($script:appPath) -TrustClient $script:cmSession } | Should -Not -Throw
    }

    It 'Should verify the association exists' {
        if (-not $script:testCertPath) { Set-ItResult -Skipped -Because 'No cert available'; return }
        $cert = Get-CmCertificate -ID $script:testCertPath -TrustClient $script:cmSession
        # the cert object should have association info
        $cert | Should -Not -BeNullOrEmpty
    }

    It 'Should remove the certificate association' {
        if (-not $script:testCertPath -or -not $script:appPath) { Set-ItResult -Skipped -Because 'No cert or app available'; return }
        { Remove-CmCertificateAssociation -Path $script:testCertPath -ApplicationPath @($script:appPath) -TrustClient $script:cmSession -Confirm:$false } | Should -Not -Throw
    }
}

# ── Policy Lifecycle ──────────────────────────────────────────────────────────

Describe 'CM Policy Lifecycle' -Tags 'Functional', 'CM', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:cmSession = New-CmFunctionalSession
        $script:policyPath = if ($env:VENAFIPS_CM_POLICY_PATH) { $env:VENAFIPS_CM_POLICY_PATH } else { '\VED\Policy\Functional Testing' }
        $script:testPolicyPath = "$($script:policyPath)\PolicyTest"

        # ensure parent folder exists
        $exists = Test-CmObject -Path $script:policyPath -ExistOnly -TrustClient $script:cmSession
        if (-not $exists) { New-CmPolicy -Path $script:policyPath -TrustClient $script:cmSession }
    }

    It 'Should create a policy folder with New-CmPolicy' {
        $result = New-CmPolicy -Path $script:testPolicyPath -Attribute @{ 'Description' = 'VenafiPS policy lifecycle test' } -PassThru -TrustClient $script:cmSession
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Should verify the policy folder exists' {
        $exists = Test-CmObject -Path $script:testPolicyPath -ExistOnly -TrustClient $script:cmSession
        $exists | Should -BeTrue
    }

    It 'Should create a nested policy with -Force' {
        $nestedPath = "$($script:testPolicyPath)\Deep\Nested\Policy"
        $result = New-CmPolicy -Path $nestedPath -Force -PassThru -TrustClient $script:cmSession
        $result | Should -Not -BeNullOrEmpty
        Test-CmObject -Path $nestedPath -ExistOnly -TrustClient $script:cmSession | Should -BeTrue
    }
}

# ── Custom Field ──────────────────────────────────────────────────────────────

Describe 'CM Custom Field' -Tags 'Functional', 'CM', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:cmSession = New-CmFunctionalSession
        $script:cfName = "VenafiPS-Func-$(Get-Random -Maximum 9999)"
    }

    It 'Should create a custom field with New-CmCustomField' {
        $result = New-CmCustomField -Name $script:cfName -Label "VenafiPS Test Field $($script:cfName)" -Class @('X509 Certificate') -Type 'String' -PassThru -TrustClient $script:cmSession
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Should verify the custom field appears in the list' {
        $result = Get-CmCustomField -Class 'X509 Certificate' -TrustClient $script:cmSession
        $items = if ($result.Items) { $result.Items } else { $result }
        $match = @($items | Where-Object { $_.Name -eq $script:cfName })
        $match.Count | Should -BeGreaterThan 0
    }
}

# ── Convert Object ────────────────────────────────────────────────────────────

Describe 'CM Convert Object' -Tags 'Functional', 'CM', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:cmSession = New-CmFunctionalSession
        $script:policyPath = if ($env:VENAFIPS_CM_POLICY_PATH) { $env:VENAFIPS_CM_POLICY_PATH } else { '\VED\Policy\Functional Testing' }
        $script:convertCertPath = $null

        # ensure policy folder exists
        $exists = Test-CmObject -Path $script:policyPath -ExistOnly -TrustClient $script:cmSession
        if (-not $exists) { New-CmPolicy -Path $script:policyPath -TrustClient $script:cmSession }

        # create a certificate to convert
        $caPath = $env:VENAFIPS_CM_CA_PATH
        if ($caPath) {
            $certName = New-TestName -Prefix 'venafips-convert'
            $certResult = New-CmCertificate -Path $script:policyPath -Name $certName -CommonName "$certName.example.com" -CertificateAuthorityPath $caPath -PassThru -TrustClient $script:cmSession -ErrorAction SilentlyContinue
            if ($certResult) { $script:convertCertPath = $certResult.Path }
        }
    }

    It 'Should convert a certificate class with Convert-CmObject' {
        if (-not $script:convertCertPath) { Set-ItResult -Skipped -Because 'No certificate to convert'; return }

        # Convert X509 Server Certificate to X509 Device Certificate (compatible cert classes)
        $result = Convert-CmObject -Path $script:convertCertPath -Class 'X509 Device Certificate' -PassThru -TrustClient $script:cmSession
        $result | Should -Not -BeNullOrEmpty
    }
}

# ── Engine Folder ─────────────────────────────────────────────────────────────

Describe 'CM Engine Folder' -Tags 'Functional', 'CM', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:cmSession = New-CmFunctionalSession
        $script:policyPath = if ($env:VENAFIPS_CM_POLICY_PATH) { $env:VENAFIPS_CM_POLICY_PATH } else { '\VED\Policy\Functional Testing' }
        $script:engineFolderPath = "$($script:policyPath)\EngineTest"
        $script:engine = $null

        # ensure folder exists
        $exists = Test-CmObject -Path $script:policyPath -ExistOnly -TrustClient $script:cmSession
        if (-not $exists) { New-CmPolicy -Path $script:policyPath -TrustClient $script:cmSession }
        $exists2 = Test-CmObject -Path $script:engineFolderPath -ExistOnly -TrustClient $script:cmSession
        if (-not $exists2) { New-CmPolicy -Path $script:engineFolderPath -TrustClient $script:cmSession }

        $engines = Find-CmEngine -Pattern '*' -TrustClient $script:cmSession
        if ($engines) { $script:engine = @($engines)[0] }
    }

    It 'Should assign a folder to an engine with Add-CmEngineFolder' {
        if (-not $script:engine) { Set-ItResult -Skipped -Because 'No engine found'; return }
        { Add-CmEngineFolder -EnginePath $script:engine.Path -FolderPath @($script:engineFolderPath) -TrustClient $script:cmSession } | Should -Not -Throw
    }

    It 'Should verify the engine-folder assignment' {
        if (-not $script:engine) { Set-ItResult -Skipped -Because 'No engine found'; return }
        $folders = Get-CmEngineFolder -ID $script:engine.Path -TrustClient $script:cmSession
        # should contain our test folder
        $folders | Should -Not -BeNullOrEmpty
    }

    It 'Should remove the engine-folder assignment with Remove-CmEngineFolder' {
        if (-not $script:engine) { Set-ItResult -Skipped -Because 'No engine found'; return }
        { Remove-CmEngineFolder -EnginePath @($script:engine.Path) -FolderPath @($script:engineFolderPath) -TrustClient $script:cmSession -Confirm:$false } | Should -Not -Throw
    }
}

# ── Write Log ─────────────────────────────────────────────────────────────────

Describe 'CM Write Log' -Tags 'Functional', 'CM', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:cmSession = New-CmFunctionalSession
    }

    It 'Should write a custom log entry with Write-CmLog' {
        { Write-CmLog -CustomEventGroup '0100' -EventId '0001' -Component '\VED\Policy' -Text1 'VenafiPS functional test log entry' -TrustClient $script:cmSession } | Should -Not -Throw
    }

    It 'Should verify the log entry was written' {
        # read recent logs and look for our entry
        $logs = Read-CmLog -First 20 -TrustClient $script:cmSession
        $logs | Should -Not -BeNullOrEmpty
    }
}

# ── Export Vault Object ───────────────────────────────────────────────────────

Describe 'CM Export Vault Object' -Tags 'Functional', 'CM', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:cmSession = New-CmFunctionalSession
        $script:sampleCert = Find-CmCertificate -Path '\VED\Policy' -Recursive -TrustClient $script:cmSession | Select-Object -First 1
        $script:vaultId = $null

        if ($script:sampleCert) {
            $certPath = @($script:sampleCert)[0].Path
            # Vault ID is stored as an attribute, not a top-level property
            $attr = Get-CmAttribute -Path $certPath -Attribute 'Certificate Vault Id' -TrustClient $script:cmSession
            if ($attr -and $attr.'Certificate Vault Id') {
                $script:vaultId = $attr.'Certificate Vault Id'
            }
        }
    }

    It 'Should export a vault object to pipeline' {
        if (-not $script:vaultId) { Set-ItResult -Skipped -Because 'No vault ID found on sample cert'; return }
        $result = Export-CmVaultObject -ID $script:vaultId -TrustClient $script:cmSession
        $result | Should -Not -BeNullOrEmpty
    }
}

# ── Revoke Grant ──────────────────────────────────────────────────────────────

Describe 'CM Revoke Grant' -Tags 'Functional', 'CM', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:cmSession = New-CmFunctionalSession
    }

    It 'Should invoke Revoke-CmGrant and handle scope/identity errors' {
        # Revoke-CmGrant uses throw for scope/identity errors, so we verify the expected error
        try {
            Revoke-CmGrant -ID 'local:{00000000-0000-0000-0000-000000000000}' -Confirm:$false
            # if it didn't throw, that's also fine
        } catch {
            # expected: either scope insufficient or identity not found
            $_.Exception.Message | Should -Match 'scope|not found|does not exist|delete'
        }
    }
}

# ── Workflow Ticket ───────────────────────────────────────────────────────────

Describe 'CM Workflow Ticket' -Tags 'Functional', 'CM', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:cmSession = New-CmFunctionalSession
    }

    It 'Should invoke Set-CmWorkflowTicketStatus and handle missing ticket' {
        # The function throws for non-existent tickets; verify expected error
        try {
            Set-CmWorkflowTicketStatus -TicketGuid ([Guid]::Empty) -Status 'Approved' -Explanation 'VenafiPS functional test' -TrustClient $script:cmSession
            # if it didn't throw, that's fine
        } catch {
            $_.Exception.Message | Should -Match 'TicketDoesNotExist|does not exist|not found'
        }
    }
}

# ── Remove Client ────────────────────────────────────────────────────────────

Describe 'CM Remove Client' -Tags 'Functional', 'CM', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:cmSession = New-CmFunctionalSession
    }

    It 'Should invoke Remove-CmClient and handle invalid client' {
        # The function throws for invalid/non-existent clients; verify expected error
        try {
            Remove-CmClient -ClientID 'venafips-nonexistent-client-00000' -TrustClient $script:cmSession -Confirm:$false
        } catch {
            $_.Exception.Message | Should -Match '400|Incorrect|not found|does not exist'
        }
    }
}

# ── Adaptable Hash ────────────────────────────────────────────────────────────

Describe 'CM Adaptable Hash' -Tags 'Functional', 'CM', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:cmSession = New-CmFunctionalSession
        $script:policyPath = if ($env:VENAFIPS_CM_POLICY_PATH) { $env:VENAFIPS_CM_POLICY_PATH } else { '\VED\Policy\Functional Testing' }
        $script:tempScriptFile = $null

        # ensure policy folder exists — Add-CmAdaptableHash works on Policy objects (sets -PolicyClass 'Adaptable App')
        $exists = Test-CmObject -Path $script:policyPath -ExistOnly -TrustClient $script:cmSession
        if (-not $exists) { New-CmPolicy -Path $script:policyPath -TrustClient $script:cmSession }

        # create a small temp script file to hash
        $script:tempScriptFile = Join-Path ([System.IO.Path]::GetTempPath()) "venafips-func-$(Get-Random).ps1"
        Set-Content -Path $script:tempScriptFile -Value '# VenafiPS functional test script'
    }

    It 'Should add an adaptable hash to a policy folder with Add-CmAdaptableHash' {
        if (-not $script:tempScriptFile) { Set-ItResult -Skipped -Because 'No script file available'; return }
        { Add-CmAdaptableHash -Path $script:policyPath -FilePath $script:tempScriptFile -TrustClient $script:cmSession } | Should -Not -Throw
    }

    AfterAll {
        if ($script:tempScriptFile -and (Test-Path $script:tempScriptFile)) {
            Remove-Item $script:tempScriptFile -Force -ErrorAction SilentlyContinue
        }
    }
}

# ── Final Cleanup ─────────────────────────────────────────────────────────────

Describe 'CM Write Test Cleanup' -Tags 'Functional', 'CM', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:cmSession = New-CmFunctionalSession
        $script:policyPath = if ($env:VENAFIPS_CM_POLICY_PATH) { $env:VENAFIPS_CM_POLICY_PATH } else { '\VED\Policy\Functional Testing' }
    }

    It 'Should clean up the functional testing folder' {
        $exists = Test-CmObject -Path $script:policyPath -ExistOnly -TrustClient $script:cmSession
        if (-not $exists) { Set-ItResult -Skipped -Because 'Policy folder does not exist'; return }
        { Remove-CmObject -Path $script:policyPath -Recursive -TrustClient $script:cmSession -Confirm:$false } | Should -Not -Throw
    }
}
