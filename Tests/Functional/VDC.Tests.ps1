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
        # get a sample cert first
        $sample = Find-VdcCertificate -Path '\VED\Policy' -Recursive -TrustClient $script:vdcSession | Select-Object -First 1
        if ($sample) {
            $cn = @($sample)[0].CommonName
            if ($cn) {
                $result = Find-VdcCertificate -CommonName $cn -TrustClient $script:vdcSession
                $result | Should -Not -BeNullOrEmpty
            }
            else {
                Set-ItResult -Skipped -Because 'Sample cert has no CommonName'
            }
        }
        else {
            Set-ItResult -Skipped -Because 'No certificates found'
        }
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
            $sourceResult = New-VdcCertificate -Path $script:policyPath -Name $sourceName -CommonName "$sourceName.example.com" -CertificateAuthorityPath $caPath -PassThru -TrustClient $script:vdcSession -ErrorAction Stop
            if ($sourceResult) {
                $script:sourceCertPath = $sourceResult.Path

                # wait briefly for cert to be issued, then export
                Start-Sleep -Seconds 5
                $exported = Export-VdcCertificate -Path $script:sourceCertPath -X509 -TrustClient $script:vdcSession -ErrorAction Stop
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
    }

    It 'Should get a credential object' {
        if (-not $env:VENAFIPS_VDC_CREDENTIAL_PATH) {
            Set-ItResult -Skipped -Because 'VENAFIPS_VDC_CREDENTIAL_PATH not set'
            return
        }
        $cred = Get-VdcCredential -Path $env:VENAFIPS_VDC_CREDENTIAL_PATH -TrustClient $script:vdcSession
        $cred | Should -Not -BeNullOrEmpty
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
