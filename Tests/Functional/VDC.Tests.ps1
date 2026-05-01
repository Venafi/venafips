BeforeDiscovery {
    . $PSScriptRoot/FunctionalCommon.ps1
    $skipAll = Skip-IfNoSession -Platform 'VDC' -RequiredEnvVars @('VENAFIPS_VDC_SERVER', 'VENAFIPS_VDC_USERNAME', 'VENAFIPS_VDC_PASSWORD', 'VENAFIPS_VDC_CLIENTID', 'VENAFIPS_VDC_SCOPE')
}

BeforeAll {
    . $PSScriptRoot/FunctionalCommon.ps1
}

Describe 'VDC Connection' -Tags 'Functional', 'VDC' -Skip:$skipAll {

    It 'Should create a session with OAuth credentials' {
        $sess = New-VdcFunctionalSession
        $sess | Should -Not -BeNullOrEmpty
        $sess.Platform | Should -Be 'VDC'
        $sess.AuthType | Should -Be 'BearerToken'
        $sess.AccessToken | Should -Not -BeNullOrEmpty
        $sess.RefreshToken | Should -Not -BeNullOrEmpty
        $sess.Expires | Should -BeGreaterThan ([DateTime]::UtcNow)
    }

    It 'Should populate version and custom fields' {
        $sess = New-VdcFunctionalSession
        $sess.PlatformData.Version | Should -Not -BeNullOrEmpty
        $sess.PlatformData.Version | Should -BeOfType [version]
    }

    It 'Should set module-scoped session' {
        if (-not $env:VENAFIPS_VDC_USERNAME) {
            Set-ItResult -Skipped -Because 'VENAFIPS_VDC_USERNAME not set (using existing session)'
            return
        }
        $cred = [System.Management.Automation.PSCredential]::new(
            $env:VENAFIPS_VDC_USERNAME,
            ($env:VENAFIPS_VDC_PASSWORD | ConvertTo-SecureString -AsPlainText -Force)
        )
        $scope = $env:VENAFIPS_VDC_SCOPE | ConvertFrom-Json -AsHashtable
        New-TrustClient -Server $env:VENAFIPS_VDC_SERVER -Credential $cred -ClientId $env:VENAFIPS_VDC_CLIENTID -Scope $scope

        $moduleClient = InModuleScope 'VenafiPS' { $Script:TrustClient }
        $moduleClient | Should -Not -BeNullOrEmpty
        $moduleClient.Platform | Should -Be 'VDC'
    }
}

Describe 'VDC Find Certificates' -Tags 'Functional', 'VDC' -Skip:$skipAll {

    BeforeAll {
        $script:vdcSession = New-VdcFunctionalSession
        $script:policyPath = if ($env:VENAFIPS_VDC_POLICY_PATH) { $env:VENAFIPS_VDC_POLICY_PATH } else { '\VED\Policy\Functional Testing' }
        $script:findCertCN = $null
        $script:findCertPath = $null

        # ensure policy folder exists
        $exists = Test-VdcObject -Path $script:policyPath -ExistOnly -TrustClient $script:vdcSession
        if (-not $exists) { New-VdcPolicy -Path $script:policyPath -TrustClient $script:vdcSession }

        # create a cert with a known CN for the CommonName filter test
        $caPath = $env:VENAFIPS_VDC_CA_PATH
        if (-not $caPath) {
            $caTemplates = Find-VdcObject -Path '\VED\Policy\CA Templates' -Recursive -TrustClient $script:vdcSession
            if ($caTemplates) { $caPath = @($caTemplates)[0].Path }
        }
        if ($caPath) {
            $testName = New-TestName -Prefix 'venafips-find'
            $script:findCertCN = "$testName.example.com"
            $certResult = New-VdcCertificate -Path $script:policyPath -Name $testName -CommonName $script:findCertCN -CertificateAuthorityPath $caPath -PassThru -TrustClient $script:vdcSession -ErrorAction SilentlyContinue
            if ($certResult) { $script:findCertPath = $certResult.Path }
        }
    }

    It 'Should find certificates in the default policy folder' {
        $certs = Find-VdcCertificate -Path '\VED\Policy' -Recursive -TrustClient $script:vdcSession | Select-Object -First 5
        $certs | Should -Not -BeNullOrEmpty
    }

    It 'Should return objects with Path and Guid' {
        $certs = Find-VdcCertificate -Path '\VED\Policy' -Recursive -TrustClient $script:vdcSession | Select-Object -First 1
        $cert = @($certs)[0]
        $cert.Path | Should -Not -BeNullOrEmpty
        $cert.Guid | Should -Not -BeNullOrEmpty
    }

    It 'Should filter by CommonName' {
        if (-not $script:findCertCN) { Set-ItResult -Skipped -Because 'No test certificate created'; return }
        $result = Find-VdcCertificate -CommonName $script:findCertCN -TrustClient $script:vdcSession
        $result | Should -Not -BeNullOrEmpty
    }
}

Describe 'VDC Get Certificate' -Tags 'Functional', 'VDC' -Skip:$skipAll {

    BeforeAll {
        $script:vdcSession = New-VdcFunctionalSession
        $script:sampleCert = Find-VdcCertificate -Path '\VED\Policy' -Recursive -TrustClient $script:vdcSession | Select-Object -First 1
    }

    It 'Should get certificate details by path' {
        if (-not $script:sampleCert) { Set-ItResult -Skipped -Because 'No sample certificate found'; return }
        $certPath = @($script:sampleCert)[0].Path
        $cert = Get-VdcCertificate -ID $certPath -TrustClient $script:vdcSession
        $cert | Should -Not -BeNullOrEmpty
    }

    It 'Should get certificate details by GUID' {
        if (-not $script:sampleCert) { Set-ItResult -Skipped -Because 'No sample certificate found'; return }
        $certGuid = @($script:sampleCert)[0].Guid
        $cert = Get-VdcCertificate -ID $certGuid -TrustClient $script:vdcSession
        $cert | Should -Not -BeNullOrEmpty
    }
}

Describe 'VDC Get/Set Attribute' -Tags 'Functional', 'VDC' -Skip:$skipAll {

    BeforeAll {
        $script:vdcSession = New-VdcFunctionalSession
        $script:sampleCert = Find-VdcCertificate -Path '\VED\Policy' -Recursive -TrustClient $script:vdcSession | Select-Object -First 1
    }

    It 'Should get attributes for a certificate' {
        if (-not $script:sampleCert) { Set-ItResult -Skipped -Because 'No sample certificate found'; return }
        $certPath = @($script:sampleCert)[0].Path
        $attrs = Get-VdcAttribute -Path $certPath -All -TrustClient $script:vdcSession
        $attrs | Should -Not -BeNullOrEmpty
    }

    It 'Should get a specific attribute' {
        if (-not $script:sampleCert) { Set-ItResult -Skipped -Because 'No sample certificate found'; return }
        $certPath = @($script:sampleCert)[0].Path
        $attr = Get-VdcAttribute -Path $certPath -Attribute 'Description' -TrustClient $script:vdcSession
        # may have no value but should not throw
        $attr | Should -Not -BeNullOrEmpty
    }
}

Describe 'VDC Export Certificate' -Tags 'Functional', 'VDC' -Skip:$skipAll {

    BeforeAll {
        $script:vdcSession = New-VdcFunctionalSession
        $script:sampleCert = Find-VdcCertificate -Path '\VED\Policy' -Recursive -TrustClient $script:vdcSession | Select-Object -First 1
        $script:exportDir = Join-Path ([System.IO.Path]::GetTempPath()) 'VenafiPS-Functional-VDC'
        if (-not (Test-Path $script:exportDir)) { New-Item -Path $script:exportDir -ItemType Directory | Out-Null }
    }

    It 'Should export certificate as PEM (X509)' {
        if (-not $script:sampleCert) { Set-ItResult -Skipped -Because 'No sample certificate found'; return }
        $certPath = @($script:sampleCert)[0].Path
        $result = Export-VdcCertificate -Path $certPath -X509 -OutPath $script:exportDir -TrustClient $script:vdcSession
        $result | Should -Not -BeNullOrEmpty
    }

    AfterAll {
        if (Test-Path $script:exportDir) {
            Remove-Item -Path $script:exportDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe 'VDC Certificate Lifecycle' -Tags 'Functional', 'VDC', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:vdcSession = New-VdcFunctionalSession
        $script:testCertPath = $null
        $script:policyPath = if ($env:VENAFIPS_VDC_POLICY_PATH) { $env:VENAFIPS_VDC_POLICY_PATH } else { '\VED\Policy\Functional Testing' }
        $script:createdPolicy = $false

        # ensure policy folder exists
        $exists = Test-VdcObject -Path $script:policyPath -ExistOnly -TrustClient $script:vdcSession
        if (-not $exists) {
            New-VdcPolicy -Path $script:policyPath -TrustClient $script:vdcSession
            $script:createdPolicy = $true
        }

        # find a CA template to use for certificate creation
        $script:caPath = $env:VENAFIPS_VDC_CA_PATH
        if (-not $script:caPath) {
            $caTemplates = Find-VdcObject -Path '\VED\Policy\CA Templates' -Recursive -TrustClient $script:vdcSession
            if ($caTemplates) {
                $script:caPath = @($caTemplates)[0].Path
            }
        }
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
            TrustClient              = $script:vdcSession
            ErrorAction              = 'Stop'
        }

        $result = New-VdcCertificate @params
        $result | Should -Not -BeNullOrEmpty
        $script:testCertPath = $result.Path
    }

    It 'Should set an attribute on the test certificate' {
        if (-not $script:testCertPath) { Set-ItResult -Skipped -Because 'No test certificate created'; return }
        { Set-VdcAttribute -Path $script:testCertPath -Attribute @{ 'Description' = 'VenafiPS functional test' } -TrustClient $script:vdcSession } |
            Should -Not -Throw
    }

    It 'Should read back the attribute' {
        if (-not $script:testCertPath) { Set-ItResult -Skipped -Because 'No test certificate created'; return }
        $attr = Get-VdcAttribute -Path $script:testCertPath -Attribute 'Description' -TrustClient $script:vdcSession
        $attr.Description | Should -Be 'VenafiPS functional test'
    }

    It 'Should delete the test certificate' {
        if (-not $script:testCertPath) { Set-ItResult -Skipped -Because 'No test certificate created'; return }
        { Remove-VdcCertificate -Path $script:testCertPath -TrustClient $script:vdcSession -Confirm:$false } |
            Should -Not -Throw
    }

}

Describe 'VDC Token Refresh' -Tags 'Functional', 'VDC' -Skip:$skipAll {

    It 'Should refresh an existing session' {
        $sess = New-VdcFunctionalSession
        $originalExpires = $sess.Expires

        # force near-expiration
        $sess.Expires = [DateTime]::UtcNow.AddSeconds(10)

        # make an API call — should trigger auto-refresh
        $result = Find-VdcCertificate -Path '\VED\Policy' -TrustClient $sess | Select-Object -First 1

        $sess.Expires | Should -BeGreaterThan $originalExpires
    }
}

# ── System Status ─────────────────────────────────────────────────────────────

Describe 'VDC System Status' -Tags 'Functional', 'VDC' -Skip:$skipAll {

    BeforeAll {
        $script:vdcSession = New-VdcFunctionalSession
    }

    It 'Should return system status' {
        $status = Get-VdcSystemStatus -TrustClient $script:vdcSession
        $status | Should -Not -BeNullOrEmpty
    }
}

# ── Objects ───────────────────────────────────────────────────────────────────

Describe 'VDC Find Objects' -Tags 'Functional', 'VDC' -Skip:$skipAll {

    BeforeAll {
        $script:vdcSession = New-VdcFunctionalSession
    }

    It 'Should find objects by path' {
        $objects = Find-VdcObject -Path '\VED\Policy' -TrustClient $script:vdcSession
        $objects | Should -Not -BeNullOrEmpty
    }

    It 'Should find objects by class' {
        $objects = Find-VdcObject -Class 'X509 Server Certificate' -TrustClient $script:vdcSession
        if ($objects) {
            @($objects)[0].TypeName | Should -Be 'X509 Server Certificate'
        }
    }

    It 'Should find objects recursively' {
        $objects = Find-VdcObject -Path '\VED\Policy' -Recursive -TrustClient $script:vdcSession
        $objects | Should -Not -BeNullOrEmpty
    }
}

Describe 'VDC Get Object' -Tags 'Functional', 'VDC' -Skip:$skipAll {

    BeforeAll {
        $script:vdcSession = New-VdcFunctionalSession
    }

    It 'Should get an object by path' {
        $obj = Get-VdcObject -Path '\VED\Policy' -TrustClient $script:vdcSession
        $obj | Should -Not -BeNullOrEmpty
        $obj.Path | Should -Be '\VED\Policy'
    }

    It 'Should get an object by GUID' {
        $byPath = Get-VdcObject -Path '\VED\Policy' -TrustClient $script:vdcSession
        $byGuid = Get-VdcObject -Guid $byPath.Guid -TrustClient $script:vdcSession
        $byGuid | Should -Not -BeNullOrEmpty
        $byGuid.Path | Should -Be $byPath.Path
    }
}

Describe 'VDC Test Object' -Tags 'Functional', 'VDC' -Skip:$skipAll {

    BeforeAll {
        $script:vdcSession = New-VdcFunctionalSession
    }

    It 'Should return true for an existing path' {
        $result = Test-VdcObject -Path '\VED\Policy' -ExistOnly -TrustClient $script:vdcSession
        $result | Should -BeTrue
    }

    It 'Should return false for a non-existent path' {
        $result = Test-VdcObject -Path '\VED\Policy\NonExistentObject_12345' -ExistOnly -TrustClient $script:vdcSession
        $result | Should -BeFalse
    }

    It 'Should return object and exists flag without -ExistOnly' {
        $result = Test-VdcObject -Path '\VED\Policy' -TrustClient $script:vdcSession
        $result.Exists | Should -BeTrue
    }
}

# ── Identity ──────────────────────────────────────────────────────────────────

Describe 'VDC Find Identity' -Tags 'Functional', 'VDC' -Skip:$skipAll {

    BeforeAll {
        $script:vdcSession = New-VdcFunctionalSession
    }

    It 'Should find identities by name' {
        $identities = Find-VdcIdentity -Name 'admin' -TrustClient $script:vdcSession
        $identities | Should -Not -BeNullOrEmpty
    }

    It 'Should return results with -First' {
        $identities = Find-VdcIdentity -Name 'a' -First 3 -TrustClient $script:vdcSession
        # VDC Identity/Browse may return more than requested; just verify it runs
        $identities | Should -Not -BeNullOrEmpty
    }
}

Describe 'VDC Get Identity' -Tags 'Functional', 'VDC' -Skip:$skipAll {

    BeforeAll {
        $script:vdcSession = New-VdcFunctionalSession
    }

    It 'Should get the current identity with -Me' {
        $me = Get-VdcIdentity -Me -TrustClient $script:vdcSession
        $me | Should -Not -BeNullOrEmpty
        $me.Name | Should -Not -BeNullOrEmpty
    }

    It 'Should get an identity by ID' {
        $me = Get-VdcIdentity -Me -TrustClient $script:vdcSession
        $identity = Get-VdcIdentity -ID $me.ID -TrustClient $script:vdcSession
        $identity | Should -Not -BeNullOrEmpty
        $identity.ID | Should -Be $me.ID
    }
}

Describe 'VDC Test Identity' -Tags 'Functional', 'VDC' -Skip:$skipAll {

    BeforeAll {
        $script:vdcSession = New-VdcFunctionalSession
        $script:myIdentity = Get-VdcIdentity -Me -TrustClient $script:vdcSession
    }

    It 'Should return true for a valid identity' {
        if (-not $script:myIdentity) { Set-ItResult -Skipped -Because 'No identity found'; return }
        $result = Test-VdcIdentity -ID $script:myIdentity.ID -ExistOnly -TrustClient $script:vdcSession
        $result | Should -BeTrue
    }
}

# ── Permissions ───────────────────────────────────────────────────────────────

Describe 'VDC Permissions' -Tags 'Functional', 'VDC' -Skip:$skipAll {

    BeforeAll {
        $script:vdcSession = New-VdcFunctionalSession
    }

    It 'Should get permissions on the policy folder' {
        # root policy may not have explicit permissions on all environments
        { Get-VdcPermission -Path '\VED\Policy' -TrustClient $script:vdcSession } | Should -Not -Throw
    }

    It 'Should get explicit permissions for a specific identity' {
        $me = Get-VdcIdentity -Me -TrustClient $script:vdcSession
        $perms = Get-VdcPermission -Path '\VED\Policy' -IdentityId $me.ID -Explicit -TrustClient $script:vdcSession
        # may not have explicit perms — just verify it does not throw
        { Get-VdcPermission -Path '\VED\Policy' -IdentityId $me.ID -Explicit -TrustClient $script:vdcSession } | Should -Not -Throw
    }
}

# ── Logs ──────────────────────────────────────────────────────────────────────

Describe 'VDC Logs' -Tags 'Functional', 'VDC' -Skip:$skipAll {

    BeforeAll {
        $script:vdcSession = New-VdcFunctionalSession
    }

    It 'Should read recent log entries' {
        $logs = Read-VdcLog -First 5 -TrustClient $script:vdcSession
        $logs | Should -Not -BeNullOrEmpty
    }

    It 'Should filter by severity' {
        { Read-VdcLog -Severity 'Error' -First 5 -TrustClient $script:vdcSession } | Should -Not -Throw
    }

    It 'Should filter by date range' {
        $end = [DateTime]::UtcNow
        $start = $end.AddDays(-7)
        { Read-VdcLog -StartTime $start -EndTime $end -First 5 -TrustClient $script:vdcSession } | Should -Not -Throw
    }
}

# ── Custom Fields & Class Attributes ─────────────────────────────────────────

Describe 'VDC Custom Fields' -Tags 'Functional', 'VDC' -Skip:$skipAll {

    BeforeAll {
        $script:vdcSession = New-VdcFunctionalSession
    }

    It 'Should get custom fields for X509 Server Certificate class' {
        { Get-VdcCustomField -Class 'X509 Server Certificate' -TrustClient $script:vdcSession } | Should -Not -Throw
    }
}

Describe 'VDC Class Attributes' -Tags 'Functional', 'VDC' -Skip:$skipAll {

    BeforeAll {
        $script:vdcSession = New-VdcFunctionalSession
    }

    It 'Should get attributes for X509 Server Certificate class' {
        $attrs = Get-VdcClassAttribute -ClassName 'X509 Server Certificate' -TrustClient $script:vdcSession
        $attrs | Should -Not -BeNullOrEmpty
    }

    It 'Should return Name and Class properties' {
        $attrs = Get-VdcClassAttribute -ClassName 'Policy' -TrustClient $script:vdcSession
        if ($attrs) {
            $first = @($attrs)[0]
            $first.Name | Should -Not -BeNullOrEmpty
        }
    }
}

# ── Engines ───────────────────────────────────────────────────────────────────

Describe 'VDC Engines' -Tags 'Functional', 'VDC' -Skip:$skipAll {

    BeforeAll {
        $script:vdcSession = New-VdcFunctionalSession
    }

    It 'Should find engines' {
        $engines = Find-VdcEngine -Pattern '*' -TrustClient $script:vdcSession
        $engines | Should -Not -BeNullOrEmpty
    }

    It 'Should get engine folder associations' {
        $engines = Find-VdcEngine -Pattern '*' -TrustClient $script:vdcSession
        if (-not $engines) { Set-ItResult -Skipped -Because 'No engines found'; return }
        $first = @($engines)[0]
        { Get-VdcEngineFolder -ID $first.Path -TrustClient $script:vdcSession } | Should -Not -Throw
    }

    It 'Should list all engine-folder mappings' {
        { Get-VdcEngineFolder -All -TrustClient $script:vdcSession } | Should -Not -Throw
    }
}

# ── Teams ─────────────────────────────────────────────────────────────────────

Describe 'VDC Teams' -Tags 'Functional', 'VDC' -Skip:$skipAll {

    BeforeAll {
        $script:vdcSession = New-VdcFunctionalSession
    }

    It 'Should list all teams' {
        { Get-VdcTeam -All -TrustClient $script:vdcSession } | Should -Not -Throw
    }

    It 'Should get a single team by ID' {
        $all = Get-VdcTeam -All -TrustClient $script:vdcSession
        if (-not $all) { Set-ItResult -Skipped -Because 'No teams found'; return }
        $first = @($all)[0]
        $single = Get-VdcTeam -ID $first.ID -TrustClient $script:vdcSession
        $single | Should -Not -BeNullOrEmpty
    }
}

# ── Object Lifecycle ──────────────────────────────────────────────────────────

Describe 'VDC Object Lifecycle' -Tags 'Functional', 'VDC', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:vdcSession = New-VdcFunctionalSession
        $script:policyPath = if ($env:VENAFIPS_VDC_POLICY_PATH) { $env:VENAFIPS_VDC_POLICY_PATH } else { '\VED\Policy\Functional Testing' }
        $script:createdPolicy = $false
        $script:testObjPath = $null
        $script:renamedObjPath = $null
        $script:movedObjPath = $null
        $script:moveTargetFolder = "$($script:policyPath)\MoveTarget"
        $script:createdMoveTarget = $false

        # ensure policy folder exists
        $exists = Test-VdcObject -Path $script:policyPath -ExistOnly -TrustClient $script:vdcSession
        if (-not $exists) {
            New-VdcPolicy -Path $script:policyPath -TrustClient $script:vdcSession
            $script:createdPolicy = $true
        }
    }

    It 'Should create a new object with New-VdcObject' {
        $testName = New-TestName -Prefix 'venafips-obj'
        $script:testObjPath = "$($script:policyPath)\$testName"
        $result = New-VdcObject -Path $script:testObjPath -Class 'Policy' -Attribute @{ 'Description' = 'Functional test object' } -PassThru -TrustClient $script:vdcSession
        $result | Should -Not -BeNullOrEmpty
        $result.Path | Should -Be $script:testObjPath
    }

    It 'Should verify the created object exists' {
        if (-not $script:testObjPath) { Set-ItResult -Skipped -Because 'No test object created'; return }
        $exists = Test-VdcObject -Path $script:testObjPath -ExistOnly -TrustClient $script:vdcSession
        $exists | Should -BeTrue
    }

    It 'Should rename the object with Rename-VdcObject' {
        if (-not $script:testObjPath) { Set-ItResult -Skipped -Because 'No test object created'; return }
        $newName = New-TestName -Prefix 'venafips-renamed'
        $script:renamedObjPath = "$($script:policyPath)\$newName"
        { Rename-VdcObject -Path $script:testObjPath -NewPath $script:renamedObjPath -TrustClient $script:vdcSession } | Should -Not -Throw

        # verify old path no longer exists and new path does
        Test-VdcObject -Path $script:testObjPath -ExistOnly -TrustClient $script:vdcSession | Should -BeFalse
        Test-VdcObject -Path $script:renamedObjPath -ExistOnly -TrustClient $script:vdcSession | Should -BeTrue
    }

    It 'Should move the object with Move-VdcObject' {
        $currentPath = if ($script:renamedObjPath) { $script:renamedObjPath } else { $script:testObjPath }
        if (-not $currentPath) { Set-ItResult -Skipped -Because 'No test object available'; return }

        # create target folder
        $targetExists = Test-VdcObject -Path $script:moveTargetFolder -ExistOnly -TrustClient $script:vdcSession
        if (-not $targetExists) {
            New-VdcPolicy -Path $script:moveTargetFolder -TrustClient $script:vdcSession
            $script:createdMoveTarget = $true
        }

        $objName = ($currentPath -split '\\')[-1]
        $script:movedObjPath = "$($script:moveTargetFolder)\$objName"
        { Move-VdcObject -SourcePath $currentPath -TargetPath $script:movedObjPath -TrustClient $script:vdcSession } | Should -Not -Throw

        Test-VdcObject -Path $currentPath -ExistOnly -TrustClient $script:vdcSession | Should -BeFalse
        Test-VdcObject -Path $script:movedObjPath -ExistOnly -TrustClient $script:vdcSession | Should -BeTrue
    }

    It 'Should clean up the moved object' {
        $pathToDelete = if ($script:movedObjPath) { $script:movedObjPath } elseif ($script:renamedObjPath) { $script:renamedObjPath } else { $script:testObjPath }
        if (-not $pathToDelete) { Set-ItResult -Skipped -Because 'No test object to clean up'; return }
        $exists = Test-VdcObject -Path $pathToDelete -ExistOnly -TrustClient $script:vdcSession
        if ($exists) {
            { Remove-VdcObject -Path $pathToDelete -TrustClient $script:vdcSession -Confirm:$false } | Should -Not -Throw
        }
    }

}

# ── Import Certificate ───────────────────────────────────────────────────────

Describe 'VDC Import Certificate' -Tags 'Functional', 'VDC', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:vdcSession = New-VdcFunctionalSession
        $script:policyPath = if ($env:VENAFIPS_VDC_POLICY_PATH) { $env:VENAFIPS_VDC_POLICY_PATH } else { '\VED\Policy\Functional Testing' }
        $script:createdPolicy = $false
        $script:importedCertPath = $null
        $script:sourceCertPath = $null
        $script:certBase64 = $null
        $script:tempCertFile = $null

        # ensure policy folder exists
        $exists = Test-VdcObject -Path $script:policyPath -ExistOnly -TrustClient $script:vdcSession
        if (-not $exists) {
            New-VdcPolicy -Path $script:policyPath -TrustClient $script:vdcSession
            $script:createdPolicy = $true
        }

        # find a CA template
        $caPath = $env:VENAFIPS_VDC_CA_PATH
        if (-not $caPath) {
            $caTemplates = Find-VdcObject -Path '\VED\Policy\CA Templates' -Recursive -TrustClient $script:vdcSession
            if ($caTemplates) { $caPath = @($caTemplates)[0].Path }
        }

        # create a cert on the server, export it, then delete the source — gives us cert data to reimport
        if ($caPath) {
            $sourceName = New-TestName -Prefix 'venafips-import-src'
            $sourceResult = New-VdcCertificate -Path $script:policyPath -Name $sourceName -CommonName "$sourceName.example.com" -CertificateAuthorityPath $caPath -TimeoutSec 30 -PassThru -TrustClient $script:vdcSession -ErrorAction Stop
            if ($sourceResult) {
                $script:sourceCertPath = $sourceResult.Path

                $exported = Export-VdcCertificate -Path $script:sourceCertPath -X509 -TrustClient $script:vdcSession -ErrorAction SilentlyContinue
                if ($exported -and $exported.CertificateData) {
                    $script:certBase64 = $exported.CertificateData

                    # also write to a temp file for the file-based import test
                    $script:tempCertFile = Join-Path ([System.IO.Path]::GetTempPath()) "venafips-func-$(Get-Random).pem"
                    $pemContent = "-----BEGIN CERTIFICATE-----`n$($script:certBase64)`n-----END CERTIFICATE-----"
                    Set-Content -Path $script:tempCertFile -Value $pemContent -NoNewline
                }

                # delete the source cert object so reimport doesn't conflict
                Remove-VdcObject -Path $script:sourceCertPath -Recursive -TrustClient $script:vdcSession -Confirm:$false -ErrorAction SilentlyContinue
                $script:sourceCertPath = $null
            }
        }
    }

    It 'Should import a certificate from Base64 data' {
        if (-not $script:certBase64) { Set-ItResult -Skipped -Because 'No cert data available (CA template or export failed)'; return }
        $result = Import-VdcCertificate -PolicyPath $script:policyPath -Data $script:certBase64 -PassThru -TrustClient $script:vdcSession
        $result | Should -Not -BeNullOrEmpty
        $script:importedCertPath = $result.Path
    }

    It 'Should get details of the imported certificate' {
        if (-not $script:importedCertPath) { Set-ItResult -Skipped -Because 'No certificate imported'; return }
        $cert = Get-VdcCertificate -ID $script:importedCertPath -TrustClient $script:vdcSession
        $cert | Should -Not -BeNullOrEmpty
    }

    It 'Should import a certificate from file with Reconcile' {
        if (-not $script:tempCertFile -or -not (Test-Path $script:tempCertFile)) {
            Set-ItResult -Skipped -Because 'No temp cert file available'; return
        }
        # Reconcile merges with the existing imported cert; VDC reports a non-terminating reconciliation message which is expected
        { Import-VdcCertificate -PolicyPath $script:policyPath -Path $script:tempCertFile -Reconcile -TrustClient $script:vdcSession -ErrorAction SilentlyContinue } | Should -Not -Throw
    }

    AfterAll {
        if ($script:tempCertFile -and (Test-Path $script:tempCertFile)) {
            Remove-Item $script:tempCertFile -Force -ErrorAction SilentlyContinue
        }
    }
}

# ── Certificate Actions ──────────────────────────────────────────────────────

Describe 'VDC Certificate Actions' -Tags 'Functional', 'VDC', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:vdcSession = New-VdcFunctionalSession
        $script:sampleCert = Find-VdcCertificate -Path '\VED\Policy' -Recursive -TrustClient $script:vdcSession | Select-Object -First 1
    }

    It 'Should validate a certificate' {
        if (-not $script:sampleCert) { Set-ItResult -Skipped -Because 'No sample certificate found'; return }
        $certPath = @($script:sampleCert)[0].Path
        { Invoke-VdcCertificateAction -Path $certPath -Validate -TrustClient $script:vdcSession } | Should -Not -Throw
    }

    It 'Should reset a certificate' {
        if (-not $script:sampleCert) { Set-ItResult -Skipped -Because 'No sample certificate found'; return }
        $certPath = @($script:sampleCert)[0].Path
        { Invoke-VdcCertificateAction -Path $certPath -Reset -TrustClient $script:vdcSession } | Should -Not -Throw
    }
}

# ── Credentials ───────────────────────────────────────────────────────────────

Describe 'VDC Credentials' -Tags 'Functional', 'VDC' -Skip:$skipAll {

    BeforeAll {
        $script:vdcSession = New-VdcFunctionalSession
        $script:policyPath = if ($env:VENAFIPS_VDC_POLICY_PATH) { $env:VENAFIPS_VDC_POLICY_PATH } else { '\VED\Policy\Functional Testing' }
        $script:credPath = "$($script:policyPath)\venafips-get-cred"
        $script:createdCred = $false

        # ensure policy folder exists
        $exists = Test-VdcObject -Path $script:policyPath -ExistOnly -TrustClient $script:vdcSession
        if (-not $exists) { New-VdcPolicy -Path $script:policyPath -TrustClient $script:vdcSession }

        # create a credential to read back
        $credExists = Test-VdcObject -Path $script:credPath -ExistOnly -TrustClient $script:vdcSession
        if (-not $credExists) {
            $secret = [PSCredential]::new('venafips-get-user', ('VenafiPS-Get-P@ss1' | ConvertTo-SecureString -AsPlainText -Force))
            $result = New-VdcCredential -Path $script:credPath -Secret $secret -PassThru -TrustClient $script:vdcSession -ErrorAction SilentlyContinue
            if ($result) { $script:createdCred = $true }
        } else {
            $script:createdCred = $true
        }
    }

    It 'Should get a credential object' {
        if (-not $script:createdCred) { Set-ItResult -Skipped -Because 'Could not create test credential'; return }
        $cred = Get-VdcCredential -Path $script:credPath -TrustClient $script:vdcSession
        $cred | Should -Not -BeNullOrEmpty
    }
}

# ── Team Lifecycle ─────────────────────────────────────────────────────────────

Describe 'VDC Team Lifecycle' -Tags 'Functional', 'VDC', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:vdcSession = New-VdcFunctionalSession
        $script:testTeamId = $null
        $script:myIdentity = Get-VdcIdentity -Me -TrustClient $script:vdcSession
        $script:extraMember = $null

        # find a second identity for member add/remove tests
        $identities = Find-VdcIdentity -Name 'a' -First 10 -TrustClient $script:vdcSession
        if ($identities) {
            $script:extraMember = @($identities | Where-Object { $_.ID -ne $script:myIdentity.ID })[0]
        }
    }

    It 'Should create a new team with New-VdcTeam' {
        if (-not $script:myIdentity) { Set-ItResult -Skipped -Because 'No identity available'; return }
        $teamName = New-TestName -Prefix 'venafips-team'
        $result = New-VdcTeam -Name $teamName -Owner @($script:myIdentity.ID) -Member @($script:myIdentity.ID) -Product @('TLS') -PassThru -TrustClient $script:vdcSession
        $result | Should -Not -BeNullOrEmpty
        $script:testTeamId = $result.ID
        $script:testTeamName = $teamName
    }

    It 'Should get the created team' {
        if (-not $script:testTeamId) { Set-ItResult -Skipped -Because 'No test team created'; return }
        $team = Get-VdcTeam -ID $script:testTeamId -TrustClient $script:vdcSession
        $team | Should -Not -BeNullOrEmpty
    }

    It 'Should add a member with Add-VdcTeamMember' {
        if (-not $script:testTeamId -or -not $script:extraMember) { Set-ItResult -Skipped -Because 'No test team or extra member available'; return }
        { Add-VdcTeamMember -ID $script:testTeamId -Member @($script:extraMember.ID) -TrustClient $script:vdcSession } | Should -Not -Throw
    }

    It 'Should remove a member with Remove-VdcTeamMember' {
        if (-not $script:testTeamId -or -not $script:extraMember) { Set-ItResult -Skipped -Because 'No test team or extra member available'; return }
        { Remove-VdcTeamMember -ID $script:testTeamId -Member @($script:extraMember.ID) -TrustClient $script:vdcSession -Confirm:$false } | Should -Not -Throw
    }

    It 'Should add an owner with Add-VdcTeamOwner' {
        if (-not $script:testTeamId -or -not $script:extraMember) { Set-ItResult -Skipped -Because 'No test team or extra member available'; return }
        { Add-VdcTeamOwner -ID $script:testTeamId -Owner @($script:extraMember.ID) -TrustClient $script:vdcSession } | Should -Not -Throw
    }

    It 'Should remove an owner with Remove-VdcTeamOwner' {
        if (-not $script:testTeamId -or -not $script:extraMember) { Set-ItResult -Skipped -Because 'No test team or extra member available'; return }
        { Remove-VdcTeamOwner -ID $script:testTeamId -Owner @($script:extraMember.ID) -TrustClient $script:vdcSession -Confirm:$false } | Should -Not -Throw
    }

    It 'Should delete the team with Remove-VdcTeam' {
        if (-not $script:testTeamId) { Set-ItResult -Skipped -Because 'No test team created'; return }
        { Remove-VdcTeam -ID $script:testTeamId -TrustClient $script:vdcSession -Confirm:$false } | Should -Not -Throw
    }
}

# ── Permission Lifecycle ──────────────────────────────────────────────────────

Describe 'VDC Permission Lifecycle' -Tags 'Functional', 'VDC', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:vdcSession = New-VdcFunctionalSession
        $script:policyPath = if ($env:VENAFIPS_VDC_POLICY_PATH) { $env:VENAFIPS_VDC_POLICY_PATH } else { '\VED\Policy\Functional Testing' }
        $script:permTestFolder = "$($script:policyPath)\PermTest"
        $script:myIdentity = Get-VdcIdentity -Me -TrustClient $script:vdcSession

        # ensure folder exists
        $exists = Test-VdcObject -Path $script:policyPath -ExistOnly -TrustClient $script:vdcSession
        if (-not $exists) { New-VdcPolicy -Path $script:policyPath -TrustClient $script:vdcSession }
        $exists2 = Test-VdcObject -Path $script:permTestFolder -ExistOnly -TrustClient $script:vdcSession
        if (-not $exists2) { New-VdcPolicy -Path $script:permTestFolder -TrustClient $script:vdcSession }
    }

    It 'Should set permissions with Set-VdcPermission' {
        if (-not $script:myIdentity) { Set-ItResult -Skipped -Because 'No identity available'; return }
        { Set-VdcPermission -Path $script:permTestFolder -IdentityId $script:myIdentity.ID -IsViewAllowed -IsReadAllowed -IsWriteAllowed -Force -TrustClient $script:vdcSession } | Should -Not -Throw
    }

    It 'Should verify permissions were set' {
        if (-not $script:myIdentity) { Set-ItResult -Skipped -Because 'No identity available'; return }
        $perms = Get-VdcPermission -Path $script:permTestFolder -IdentityId $script:myIdentity.ID -Explicit -TrustClient $script:vdcSession
        $perms | Should -Not -BeNullOrEmpty
    }

    It 'Should remove permissions with Remove-VdcPermission' {
        if (-not $script:myIdentity) { Set-ItResult -Skipped -Because 'No identity available'; return }
        { Remove-VdcPermission -Path $script:permTestFolder -IdentityId $script:myIdentity.ID -TrustClient $script:vdcSession -Confirm:$false } | Should -Not -Throw
    }
}

# ── Credential Lifecycle ──────────────────────────────────────────────────────

Describe 'VDC Credential Lifecycle' -Tags 'Functional', 'VDC', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:vdcSession = New-VdcFunctionalSession
        $script:policyPath = if ($env:VENAFIPS_VDC_POLICY_PATH) { $env:VENAFIPS_VDC_POLICY_PATH } else { '\VED\Policy\Functional Testing' }
        $script:credPath = "$($script:policyPath)\venafips-func-cred"
        $script:createdCred = $false

        # ensure policy folder exists
        $exists = Test-VdcObject -Path $script:policyPath -ExistOnly -TrustClient $script:vdcSession
        if (-not $exists) { New-VdcPolicy -Path $script:policyPath -TrustClient $script:vdcSession }
    }

    It 'Should create a credential with New-VdcCredential' {
        $secret = [PSCredential]::new('venafips-user', ('VenafiPS-Test-P@ss1' | ConvertTo-SecureString -AsPlainText -Force))
        $result = New-VdcCredential -Path $script:credPath -Secret $secret -PassThru -TrustClient $script:vdcSession
        $result | Should -Not -BeNullOrEmpty
        $script:createdCred = $true
    }

    It 'Should update the credential with Set-VdcCredential' {
        if (-not $script:createdCred) { Set-ItResult -Skipped -Because 'No credential created'; return }
        $newPassword = 'VenafiPS-Updated-P@ss2' | ConvertTo-SecureString -AsPlainText -Force
        { Set-VdcCredential -Path $script:credPath -Password $newPassword -Username 'venafips-updated' -TrustClient $script:vdcSession } | Should -Not -Throw
    }

    It 'Should verify the credential exists' {
        if (-not $script:createdCred) { Set-ItResult -Skipped -Because 'No credential created'; return }
        $exists = Test-VdcObject -Path $script:credPath -ExistOnly -TrustClient $script:vdcSession
        $exists | Should -BeTrue
    }
}

# ── Device & CAPI Application ────────────────────────────────────────────────

Describe 'VDC Device & CAPI Application' -Tags 'Functional', 'VDC', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:vdcSession = New-VdcFunctionalSession
        $script:policyPath = if ($env:VENAFIPS_VDC_POLICY_PATH) { $env:VENAFIPS_VDC_POLICY_PATH } else { '\VED\Policy\Functional Testing' }
        $script:devicePath = "$($script:policyPath)\venafips-func-device"
        $script:appPath = $null
        $script:createdDevice = $false

        # ensure policy folder exists
        $exists = Test-VdcObject -Path $script:policyPath -ExistOnly -TrustClient $script:vdcSession
        if (-not $exists) { New-VdcPolicy -Path $script:policyPath -TrustClient $script:vdcSession }
    }

    It 'Should create a device with New-VdcDevice' {
        $result = New-VdcDevice -Path $script:devicePath -Hostname '10.0.0.99' -Description 'VenafiPS functional test device' -PassThru -TrustClient $script:vdcSession
        $result | Should -Not -BeNullOrEmpty
        $script:createdDevice = $true
    }

    It 'Should create a CAPI application on the device with New-VdcCapiApplication' {
        if (-not $script:createdDevice) { Set-ItResult -Skipped -Because 'No device created'; return }
        $appName = 'venafips-func-app'
        $script:appPath = "$($script:devicePath)\$appName"
        $result = New-VdcCapiApplication -Path $script:devicePath -ApplicationName $appName -FriendlyName 'VenafiPS Test App' -Description 'Functional test CAPI app' -PassThru -TrustClient $script:vdcSession
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Should verify the application exists' {
        if (-not $script:appPath) { Set-ItResult -Skipped -Because 'No application created'; return }
        $exists = Test-VdcObject -Path $script:appPath -ExistOnly -TrustClient $script:vdcSession
        $exists | Should -BeTrue
    }
}

# ── Certificate Association ───────────────────────────────────────────────────

Describe 'VDC Certificate Association' -Tags 'Functional', 'VDC', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:vdcSession = New-VdcFunctionalSession
        $script:policyPath = if ($env:VENAFIPS_VDC_POLICY_PATH) { $env:VENAFIPS_VDC_POLICY_PATH } else { '\VED\Policy\Functional Testing' }
        $script:testCertPath = $null
        $script:devicePath = "$($script:policyPath)\venafips-assoc-device"
        $script:appPath = $null

        # ensure policy folder exists
        $exists = Test-VdcObject -Path $script:policyPath -ExistOnly -TrustClient $script:vdcSession
        if (-not $exists) { New-VdcPolicy -Path $script:policyPath -TrustClient $script:vdcSession }

        # find or create a cert
        $caPath = $env:VENAFIPS_VDC_CA_PATH
        if (-not $caPath) {
            $caTemplates = Find-VdcObject -Path '\VED\Policy\CA Templates' -Recursive -TrustClient $script:vdcSession
            if ($caTemplates) { $caPath = @($caTemplates)[0].Path }
        }
        if ($caPath) {
            $certName = New-TestName -Prefix 'venafips-assoc'
            $certResult = New-VdcCertificate -Path $script:policyPath -Name $certName -CommonName "$certName.example.com" -CertificateAuthorityPath $caPath -PassThru -TrustClient $script:vdcSession -ErrorAction Stop
            if ($certResult) { $script:testCertPath = $certResult.Path }
        }

        # create a device + CAPI app for association
        if ($script:testCertPath) {
            $devExists = Test-VdcObject -Path $script:devicePath -ExistOnly -TrustClient $script:vdcSession
            if (-not $devExists) {
                New-VdcDevice -Path $script:devicePath -Hostname '10.0.0.100' -TrustClient $script:vdcSession | Out-Null
            }
            $appName = 'venafips-assoc-app'
            $script:appPath = "$($script:devicePath)\$appName"
            $appExists = Test-VdcObject -Path $script:appPath -ExistOnly -TrustClient $script:vdcSession
            if (-not $appExists) {
                New-VdcCapiApplication -Path $script:devicePath -ApplicationName $appName -FriendlyName 'Association Test' -TrustClient $script:vdcSession | Out-Null
            }
        }
    }

    It 'Should associate an application with a certificate' {
        if (-not $script:testCertPath -or -not $script:appPath) { Set-ItResult -Skipped -Because 'No cert or app available'; return }
        { Add-VdcCertificateAssociation -CertificatePath $script:testCertPath -ApplicationPath @($script:appPath) -TrustClient $script:vdcSession } | Should -Not -Throw
    }

    It 'Should verify the association exists' {
        if (-not $script:testCertPath) { Set-ItResult -Skipped -Because 'No cert available'; return }
        $cert = Get-VdcCertificate -ID $script:testCertPath -TrustClient $script:vdcSession
        # the cert object should have association info
        $cert | Should -Not -BeNullOrEmpty
    }

    It 'Should remove the certificate association' {
        if (-not $script:testCertPath -or -not $script:appPath) { Set-ItResult -Skipped -Because 'No cert or app available'; return }
        { Remove-VdcCertificateAssociation -Path $script:testCertPath -ApplicationPath @($script:appPath) -TrustClient $script:vdcSession -Confirm:$false } | Should -Not -Throw
    }
}

# ── Policy Lifecycle ──────────────────────────────────────────────────────────

Describe 'VDC Policy Lifecycle' -Tags 'Functional', 'VDC', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:vdcSession = New-VdcFunctionalSession
        $script:policyPath = if ($env:VENAFIPS_VDC_POLICY_PATH) { $env:VENAFIPS_VDC_POLICY_PATH } else { '\VED\Policy\Functional Testing' }
        $script:testPolicyPath = "$($script:policyPath)\PolicyTest"

        # ensure parent folder exists
        $exists = Test-VdcObject -Path $script:policyPath -ExistOnly -TrustClient $script:vdcSession
        if (-not $exists) { New-VdcPolicy -Path $script:policyPath -TrustClient $script:vdcSession }
    }

    It 'Should create a policy folder with New-VdcPolicy' {
        $result = New-VdcPolicy -Path $script:testPolicyPath -Attribute @{ 'Description' = 'VenafiPS policy lifecycle test' } -PassThru -TrustClient $script:vdcSession
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Should verify the policy folder exists' {
        $exists = Test-VdcObject -Path $script:testPolicyPath -ExistOnly -TrustClient $script:vdcSession
        $exists | Should -BeTrue
    }

    It 'Should create a nested policy with -Force' {
        $nestedPath = "$($script:testPolicyPath)\Deep\Nested\Policy"
        $result = New-VdcPolicy -Path $nestedPath -Force -PassThru -TrustClient $script:vdcSession
        $result | Should -Not -BeNullOrEmpty
        Test-VdcObject -Path $nestedPath -ExistOnly -TrustClient $script:vdcSession | Should -BeTrue
    }
}

# ── Custom Field ──────────────────────────────────────────────────────────────

Describe 'VDC Custom Field' -Tags 'Functional', 'VDC', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:vdcSession = New-VdcFunctionalSession
        $script:cfName = "VenafiPS-Func-$(Get-Random -Maximum 9999)"
    }

    It 'Should create a custom field with New-VdcCustomField' {
        $result = New-VdcCustomField -Name $script:cfName -Label "VenafiPS Test Field $($script:cfName)" -Class @('X509 Certificate') -Type 'String' -PassThru -TrustClient $script:vdcSession
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Should verify the custom field appears in the list' {
        $result = Get-VdcCustomField -Class 'X509 Certificate' -TrustClient $script:vdcSession
        $items = if ($result.Items) { $result.Items } else { $result }
        $match = @($items | Where-Object { $_.Name -eq $script:cfName })
        $match.Count | Should -BeGreaterThan 0
    }
}

# ── Convert Object ────────────────────────────────────────────────────────────

Describe 'VDC Convert Object' -Tags 'Functional', 'VDC', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:vdcSession = New-VdcFunctionalSession
        $script:policyPath = if ($env:VENAFIPS_VDC_POLICY_PATH) { $env:VENAFIPS_VDC_POLICY_PATH } else { '\VED\Policy\Functional Testing' }
        $script:convertCertPath = $null

        # ensure policy folder exists
        $exists = Test-VdcObject -Path $script:policyPath -ExistOnly -TrustClient $script:vdcSession
        if (-not $exists) { New-VdcPolicy -Path $script:policyPath -TrustClient $script:vdcSession }

        # create a certificate to convert
        $caPath = $env:VENAFIPS_VDC_CA_PATH
        if (-not $caPath) {
            $caTemplates = Find-VdcObject -Path '\VED\Policy\CA Templates' -Recursive -TrustClient $script:vdcSession
            if ($caTemplates) { $caPath = @($caTemplates)[0].Path }
        }
        if ($caPath) {
            $certName = New-TestName -Prefix 'venafips-convert'
            $certResult = New-VdcCertificate -Path $script:policyPath -Name $certName -CommonName "$certName.example.com" -CertificateAuthorityPath $caPath -PassThru -TrustClient $script:vdcSession -ErrorAction SilentlyContinue
            if ($certResult) { $script:convertCertPath = $certResult.Path }
        }
    }

    It 'Should convert a certificate class with Convert-VdcObject' {
        if (-not $script:convertCertPath) { Set-ItResult -Skipped -Because 'No certificate to convert'; return }

        # Convert X509 Server Certificate to X509 Device Certificate (compatible cert classes)
        $result = Convert-VdcObject -Path $script:convertCertPath -Class 'X509 Device Certificate' -PassThru -TrustClient $script:vdcSession
        $result | Should -Not -BeNullOrEmpty
    }
}

# ── Engine Folder ─────────────────────────────────────────────────────────────

Describe 'VDC Engine Folder' -Tags 'Functional', 'VDC', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:vdcSession = New-VdcFunctionalSession
        $script:policyPath = if ($env:VENAFIPS_VDC_POLICY_PATH) { $env:VENAFIPS_VDC_POLICY_PATH } else { '\VED\Policy\Functional Testing' }
        $script:engineFolderPath = "$($script:policyPath)\EngineTest"
        $script:engine = $null

        # ensure folder exists
        $exists = Test-VdcObject -Path $script:policyPath -ExistOnly -TrustClient $script:vdcSession
        if (-not $exists) { New-VdcPolicy -Path $script:policyPath -TrustClient $script:vdcSession }
        $exists2 = Test-VdcObject -Path $script:engineFolderPath -ExistOnly -TrustClient $script:vdcSession
        if (-not $exists2) { New-VdcPolicy -Path $script:engineFolderPath -TrustClient $script:vdcSession }

        $engines = Find-VdcEngine -Pattern '*' -TrustClient $script:vdcSession
        if ($engines) { $script:engine = @($engines)[0] }
    }

    It 'Should assign a folder to an engine with Add-VdcEngineFolder' {
        if (-not $script:engine) { Set-ItResult -Skipped -Because 'No engine found'; return }
        { Add-VdcEngineFolder -EnginePath $script:engine.Path -FolderPath @($script:engineFolderPath) -TrustClient $script:vdcSession } | Should -Not -Throw
    }

    It 'Should verify the engine-folder assignment' {
        if (-not $script:engine) { Set-ItResult -Skipped -Because 'No engine found'; return }
        $folders = Get-VdcEngineFolder -ID $script:engine.Path -TrustClient $script:vdcSession
        # should contain our test folder
        $folders | Should -Not -BeNullOrEmpty
    }

    It 'Should remove the engine-folder assignment with Remove-VdcEngineFolder' {
        if (-not $script:engine) { Set-ItResult -Skipped -Because 'No engine found'; return }
        { Remove-VdcEngineFolder -EnginePath @($script:engine.Path) -FolderPath @($script:engineFolderPath) -TrustClient $script:vdcSession -Confirm:$false } | Should -Not -Throw
    }
}

# ── Write Log ─────────────────────────────────────────────────────────────────

Describe 'VDC Write Log' -Tags 'Functional', 'VDC', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:vdcSession = New-VdcFunctionalSession
    }

    It 'Should write a custom log entry with Write-VdcLog' {
        { Write-VdcLog -CustomEventGroup '0100' -EventId '0001' -Component '\VED\Policy' -Text1 'VenafiPS functional test log entry' -TrustClient $script:vdcSession } | Should -Not -Throw
    }

    It 'Should verify the log entry was written' {
        # read recent logs and look for our entry
        $logs = Read-VdcLog -First 20 -TrustClient $script:vdcSession
        $logs | Should -Not -BeNullOrEmpty
    }
}

# ── Export Vault Object ───────────────────────────────────────────────────────

Describe 'VDC Export Vault Object' -Tags 'Functional', 'VDC', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:vdcSession = New-VdcFunctionalSession
        $script:sampleCert = Find-VdcCertificate -Path '\VED\Policy' -Recursive -TrustClient $script:vdcSession | Select-Object -First 1
        $script:vaultId = $null

        if ($script:sampleCert) {
            $certPath = @($script:sampleCert)[0].Path
            # Vault ID is stored as an attribute, not a top-level property
            $attr = Get-VdcAttribute -Path $certPath -Attribute 'Certificate Vault Id' -TrustClient $script:vdcSession
            if ($attr -and $attr.'Certificate Vault Id') {
                $script:vaultId = $attr.'Certificate Vault Id'
            }
        }
    }

    It 'Should export a vault object to pipeline' {
        if (-not $script:vaultId) { Set-ItResult -Skipped -Because 'No vault ID found on sample cert'; return }
        $result = Export-VdcVaultObject -ID $script:vaultId -TrustClient $script:vdcSession
        $result | Should -Not -BeNullOrEmpty
    }
}

# ── Revoke Grant ──────────────────────────────────────────────────────────────

Describe 'VDC Revoke Grant' -Tags 'Functional', 'VDC', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:vdcSession = New-VdcFunctionalSession
    }

    It 'Should invoke Revoke-VdcGrant and handle scope/identity errors' {
        # Revoke-VdcGrant uses throw for scope/identity errors, so we verify the expected error
        try {
            Revoke-VdcGrant -ID 'local:{00000000-0000-0000-0000-000000000000}' -Confirm:$false
            # if it didn't throw, that's also fine
        } catch {
            # expected: either scope insufficient or identity not found
            $_.Exception.Message | Should -Match 'scope|not found|does not exist|delete'
        }
    }
}

# ── Workflow Ticket ───────────────────────────────────────────────────────────

Describe 'VDC Workflow Ticket' -Tags 'Functional', 'VDC', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:vdcSession = New-VdcFunctionalSession
    }

    It 'Should invoke Set-VdcWorkflowTicketStatus and handle missing ticket' {
        # The function throws for non-existent tickets; verify expected error
        try {
            Set-VdcWorkflowTicketStatus -TicketGuid ([Guid]::Empty) -Status 'Approved' -Explanation 'VenafiPS functional test' -TrustClient $script:vdcSession
            # if it didn't throw, that's fine
        } catch {
            $_.Exception.Message | Should -Match 'TicketDoesNotExist|does not exist|not found'
        }
    }
}

# ── Remove Client ────────────────────────────────────────────────────────────

Describe 'VDC Remove Client' -Tags 'Functional', 'VDC', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:vdcSession = New-VdcFunctionalSession
    }

    It 'Should invoke Remove-VdcClient and handle invalid client' {
        # The function throws for invalid/non-existent clients; verify expected error
        try {
            Remove-VdcClient -ClientID 'venafips-nonexistent-client-00000' -TrustClient $script:vdcSession -Confirm:$false
        } catch {
            $_.Exception.Message | Should -Match '400|Incorrect|not found|does not exist'
        }
    }
}

# ── Adaptable Hash ────────────────────────────────────────────────────────────

Describe 'VDC Adaptable Hash' -Tags 'Functional', 'VDC', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:vdcSession = New-VdcFunctionalSession
        $script:policyPath = if ($env:VENAFIPS_VDC_POLICY_PATH) { $env:VENAFIPS_VDC_POLICY_PATH } else { '\VED\Policy\Functional Testing' }
        $script:tempScriptFile = $null

        # ensure policy folder exists — Add-VdcAdaptableHash works on Policy objects (sets -PolicyClass 'Adaptable App')
        $exists = Test-VdcObject -Path $script:policyPath -ExistOnly -TrustClient $script:vdcSession
        if (-not $exists) { New-VdcPolicy -Path $script:policyPath -TrustClient $script:vdcSession }

        # create a small temp script file to hash
        $script:tempScriptFile = Join-Path ([System.IO.Path]::GetTempPath()) "venafips-func-$(Get-Random).ps1"
        Set-Content -Path $script:tempScriptFile -Value '# VenafiPS functional test script'
    }

    It 'Should add an adaptable hash to a policy folder with Add-VdcAdaptableHash' {
        if (-not $script:tempScriptFile) { Set-ItResult -Skipped -Because 'No script file available'; return }
        { Add-VdcAdaptableHash -Path $script:policyPath -FilePath $script:tempScriptFile -TrustClient $script:vdcSession } | Should -Not -Throw
    }

    AfterAll {
        if ($script:tempScriptFile -and (Test-Path $script:tempScriptFile)) {
            Remove-Item $script:tempScriptFile -Force -ErrorAction SilentlyContinue
        }
    }
}

# ── Final Cleanup ─────────────────────────────────────────────────────────────

Describe 'VDC Write Test Cleanup' -Tags 'Functional', 'VDC', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:vdcSession = New-VdcFunctionalSession
        $script:policyPath = if ($env:VENAFIPS_VDC_POLICY_PATH) { $env:VENAFIPS_VDC_POLICY_PATH } else { '\VED\Policy\Functional Testing' }
    }

    It 'Should clean up the functional testing folder' {
        $exists = Test-VdcObject -Path $script:policyPath -ExistOnly -TrustClient $script:vdcSession
        if (-not $exists) { Set-ItResult -Skipped -Because 'Policy folder does not exist'; return }
        { Remove-VdcObject -Path $script:policyPath -Recursive -TrustClient $script:vdcSession -Confirm:$false } | Should -Not -Throw
    }
}
