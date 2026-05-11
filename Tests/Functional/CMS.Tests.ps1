BeforeDiscovery {
    . $PSScriptRoot/FunctionalCommon.ps1
    $skipAll = Skip-IfNoSession -Platform 'CMS' -RequiredEnvVars @('VENAFIPS_CMS_APIKEY')
}

BeforeAll {
    . $PSScriptRoot/FunctionalCommon.ps1
}

Describe 'CMSaaS Connection' -Tags 'Functional', 'CMS' -Skip:$skipAll {

    It 'Should create a session with API key' {
        $sess = New-CmsFunctionalSession
        $sess | Should -Not -BeNullOrEmpty
        $sess.Platform | Should -Be 'CMS'
        $sess.AuthType | Should -Be 'ApiKey'
        $sess.Server | Should -Not -BeNullOrEmpty
    }

    It 'Should set module-scoped session' {
        if (-not $env:VENAFIPS_CMS_APIKEY) {
            Set-ItResult -Skipped -Because 'VENAFIPS_CMS_APIKEY not set (using existing session)'
            return
        }
        $region = if ($env:VENAFIPS_CMS_REGION) { $env:VENAFIPS_CMS_REGION } else { 'us' }
        New-TrustClient -CmsKey $env:VENAFIPS_CMS_APIKEY -CmsRegion $region
        $moduleClient = InModuleScope 'VenafiPS' { $Script:TrustClient }
        $moduleClient | Should -Not -BeNullOrEmpty
        $moduleClient.Platform | Should -Be 'CMS'
    }
}

Describe 'CMSaaS Find Certificates' -Tags 'Functional', 'CMS' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-CmsFunctionalSession
    }

    It 'Should find certificates with -First' {
        $certs = Find-TrustCertificate -First 5 -TrustClient $script:vcSession
        $certs | Should -Not -BeNullOrEmpty
        @($certs).Count | Should -BeLessOrEqual 5
    }

    It 'Should return certificate objects with expected properties' {
        $certs = Find-TrustCertificate -First 1 -TrustClient $script:vcSession
        $cert = @($certs)[0]
        $cert.certificateId | Should -Not -BeNullOrEmpty
        $cert.certificateName | Should -Not -BeNullOrEmpty
    }

    It 'Should find by name filter' {
        # get a cert name first, then search for it
        $sample = Find-TrustCertificate -First 1 -TrustClient $script:vcSession
        if ($sample) {
            $name = @($sample)[0].certificateName
            $result = Find-TrustCertificate -Name $name -First 5 -TrustClient $script:vcSession
            $result | Should -Not -BeNullOrEmpty
        }
        else {
            Set-ItResult -Skipped -Because 'No certificates in environment'
        }
    }

    It 'Should find expired certificates' {
        $expired = Find-TrustCertificate -IsExpired -First 5 -TrustClient $script:vcSession
        # may be empty if none expired, that's ok
        if ($expired) {
            @($expired).Count | Should -BeGreaterThan 0
        }
    }
}

Describe 'CMSaaS Get Certificate' -Tags 'Functional', 'CMS' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-CmsFunctionalSession
        $script:sampleCert = Find-TrustCertificate -First 1 -TrustClient $script:vcSession
    }

    It 'Should get a certificate by ID' {
        if (-not $script:sampleCert) { Set-ItResult -Skipped -Because 'No sample certificate found'; return }
        $certId = @($script:sampleCert)[0].certificateId
        $cert = Get-TrustCertificate -Certificate $certId -TrustClient $script:vcSession
        $cert | Should -Not -BeNullOrEmpty
        $cert.certificateId | Should -Be $certId
    }
}

Describe 'CMSaaS Export Certificate' -Tags 'Functional', 'CMS' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-CmsFunctionalSession
        $script:sampleCert = Find-TrustCertificate -First 1 -TrustClient $script:vcSession
        $script:exportDir = Join-Path ([System.IO.Path]::GetTempPath()) 'VenafiPS-Functional'
        if (-not (Test-Path $script:exportDir)) { New-Item -Path $script:exportDir -ItemType Directory | Out-Null }
    }

    It 'Should export certificate as PEM' {
        if (-not $script:sampleCert) { Set-ItResult -Skipped -Because 'No sample certificate found'; return }
        $certId = @($script:sampleCert)[0].certificateId
        $result = Export-TrustCertificate -ID $certId -OutPath $script:exportDir -TrustClient $script:vcSession
        $result | Should -Not -BeNullOrEmpty
    }

    AfterAll {
        if (Test-Path $script:exportDir) {
            Remove-Item -Path $script:exportDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# ── Team Lifecycle ────────────────────────────────────────────────────────────

Describe 'CMSaaS Team Lifecycle' -Tags 'Functional', 'CMS', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-CmsFunctionalSession
        $script:testTeamId = $null
        # get the current user GUID to use as owner and member
        $me = Get-CmsUser -Me -TrustClient $script:vcSession
        $script:myUserId = $me.userId
    }

    It 'Should create a new team' {
        $teamName = New-TestName -Prefix 'venafips-team'
        $team = New-CmsTeam -Name $teamName -Owner @($script:myUserId) -Member @($script:myUserId) -Role 'Resource Owner' -PassThru -TrustClient $script:vcSession
        $team | Should -Not -BeNullOrEmpty
        $script:testTeamId = $team.teamId
    }

    It 'Should get the created team' {
        if (-not $script:testTeamId) { Set-ItResult -Skipped -Because 'No test team created'; return }
        $team = Get-CmsTeam -Team $script:testTeamId -TrustClient $script:vcSession
        $team | Should -Not -BeNullOrEmpty
    }

    It 'Should update the team role' {
        if (-not $script:testTeamId) { Set-ItResult -Skipped -Because 'No test team created'; return }
        { Set-CmsTeam -Team $script:testTeamId -Role 'Guest' -TrustClient $script:vcSession } | Should -Not -Throw
    }

    It 'Should add a team member' {
        if (-not $script:testTeamId) { Set-ItResult -Skipped -Because 'No test team created'; return }
        # adding the same user again should be a no-op or succeed silently
        { Add-CmsTeamMember -Team $script:testTeamId -Member @($script:myUserId) -TrustClient $script:vcSession } | Should -Not -Throw
    }

    It 'Should remove a team member' {
        if (-not $script:testTeamId) { Set-ItResult -Skipped -Because 'No test team created'; return }
        { Remove-CmsTeamMember -ID $script:testTeamId -Member @($script:myUserId) -TrustClient $script:vcSession -Confirm:$false } | Should -Not -Throw
    }

    It 'Should add a team owner' {
        if (-not $script:testTeamId) { Set-ItResult -Skipped -Because 'No test team created'; return }
        # adding the same user again should be a no-op or succeed silently
        { Add-CmsTeamOwner -Team $script:testTeamId -Owner @($script:myUserId) -TrustClient $script:vcSession } | Should -Not -Throw
    }

    It 'Should throw when removing the only team owner' {
        if (-not $script:testTeamId) { Set-ItResult -Skipped -Because 'No test team created'; return }
        { Remove-CmsTeamOwner -ID $script:testTeamId -Owner @($script:myUserId) -TrustClient $script:vcSession -Confirm:$false } | Should -Throw
    }

    It 'Should delete the team' {
        if (-not $script:testTeamId) { Set-ItResult -Skipped -Because 'No test team created'; return }
        { Remove-CmsTeam -ID $script:testTeamId -TrustClient $script:vcSession -Confirm:$false } | Should -Not -Throw
    }
}

# ── Application Lifecycle ─────────────────────────────────────────────────────

Describe 'CMSaaS Application Lifecycle' -Tags 'Functional', 'CMS', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-CmsFunctionalSession
        $script:testAppId = $null
        $script:testAppName = $null
        $script:testTeamId = $null

        # create a temp team to own the application (Owner must be a team, not a user)
        $me = Get-CmsUser -Me -TrustClient $script:vcSession
        $teamName = New-TestName -Prefix 'venafips-appowner'
        New-CmsTeam -Name $teamName -Owner @($me.userId) -Member @($me.userId) -Role 'Resource Owner' -TrustClient $script:vcSession
        $team = Get-CmsTeam -All -TrustClient $script:vcSession | Where-Object { $_.name -eq $teamName }
        if ($team) { $script:testTeamId = $team.teamId }
    }

    It 'Should create a new application' {
        if (-not $script:testTeamId) { Set-ItResult -Skipped -Because 'Could not create owner team'; return }
        $script:testAppName = New-TestName -Prefix 'venafips-app'
        $result = New-CmsApplication -Name $script:testAppName -Owner $script:testTeamId -PassThru -TrustClient $script:vcSession
        $result | Should -Not -BeNullOrEmpty
        $script:testAppId = $result.applicationId
    }

    It 'Should get the created application' {
        if (-not $script:testAppId) { Set-ItResult -Skipped -Because 'No test application created'; return }
        $app = Get-CmsApplication -Application $script:testAppId -TrustClient $script:vcSession
        $app | Should -Not -BeNullOrEmpty
        $app.name | Should -Be $script:testAppName
    }

    It 'Should update the application name' {
        if (-not $script:testAppId) { Set-ItResult -Skipped -Because 'No test application created'; return }
        $newName = New-TestName -Prefix 'venafips-app-upd'
        { Set-CmsApplication -Application $script:testAppId -Name $newName -TrustClient $script:vcSession } | Should -Not -Throw
        $script:testAppName = $newName
    }

    It 'Should verify the name was updated' {
        if (-not $script:testAppId) { Set-ItResult -Skipped -Because 'No test application created'; return }
        $app = Get-CmsApplication -Application $script:testAppId -TrustClient $script:vcSession
        $app.name | Should -Be $script:testAppName
    }

    It 'Should delete the application' {
        if (-not $script:testAppId) { Set-ItResult -Skipped -Because 'No test application created'; return }
        { Remove-CmsApplication -ID $script:testAppId -TrustClient $script:vcSession -Confirm:$false } | Should -Not -Throw
    }

    AfterAll {
        if ($script:testTeamId) {
            Remove-CmsTeam -ID $script:testTeamId -TrustClient $script:vcSession -Confirm:$false -ErrorAction SilentlyContinue
        }
    }
}

# ── Certificate Lifecycle ─────────────────────────────────────────────────────

Describe 'CMSaaS Certificate Lifecycle' -Tags 'Functional', 'CMS', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-CmsFunctionalSession
        $script:testCertId = $null
        $script:testTeamId = $null
        $script:testAppId = $null

        # create a temp team and application for certificate association
        $me = Get-CmsUser -Me -TrustClient $script:vcSession
        $teamName = New-TestName -Prefix 'venafips-certlife'
        New-CmsTeam -Name $teamName -Owner @($me.userId) -Member @($me.userId) -Role 'Resource Owner' -TrustClient $script:vcSession
        $team = Get-CmsTeam -All -TrustClient $script:vcSession | Where-Object { $_.name -eq $teamName }
        if ($team) {
            $script:testTeamId = $team.teamId
            if ($env:VENAFIPS_CMS_ISSUING_TEMPLATE) {
                $appName = New-TestName -Prefix 'venafips-certlife-app'
                $app = New-CmsApplication -Name $appName -Owner $script:testTeamId -IssuingTemplate $env:VENAFIPS_CMS_ISSUING_TEMPLATE -PassThru -TrustClient $script:vcSession
                $script:testAppId = $app.applicationId
            }
        }
    }

    It 'Should request a new certificate' {
        if (-not $env:VENAFIPS_CMS_ISSUING_TEMPLATE) {
            Set-ItResult -Skipped -Because 'VENAFIPS_CMS_ISSUING_TEMPLATE not set'
            return
        }

        if (-not $env:VENAFIPS_CMS_DOMAIN) {
            Set-ItResult -Skipped -Because 'VENAFIPS_CMS_DOMAIN not set'
            return
        }

        if (-not $script:testAppId) {
            Set-ItResult -Skipped -Because 'Could not create test application'
            return
        }

        $testName = New-TestName -Prefix 'venafips-func'
        $params = @{
            CommonName       = "$testName.$env:VENAFIPS_CMS_DOMAIN"
            IssuingTemplate  = $env:VENAFIPS_CMS_ISSUING_TEMPLATE
            Application      = $script:testAppId
            TrustClient      = $script:vcSession
            PassThru         = $true
            Wait             = $true
        }

        $result = New-TrustCertificate @params
        $result | Should -Not -BeNullOrEmpty
        $script:testCertId = $result.certificateId[0]
    }

    It 'Should validate the test certificate' {
        if (-not $script:testCertId) { Set-ItResult -Skipped -Because 'No test certificate created'; return }
        { Invoke-TrustCertificateAction -ID $script:testCertId -Validate -TrustClient $script:vcSession -Confirm:$false } |
            Should -Not -Throw
    }

    It 'Should retire the test certificate' {
        if (-not $script:testCertId) { Set-ItResult -Skipped -Because 'No test certificate created'; return }
        { Invoke-TrustCertificateAction -ID $script:testCertId -Retire -TrustClient $script:vcSession -Confirm:$false } |
            Should -Not -Throw
    }

    It 'Should recover the retired certificate' {
        if (-not $script:testCertId) { Set-ItResult -Skipped -Because 'No test certificate created'; return }
        { Invoke-TrustCertificateAction -ID $script:testCertId -Recover -TrustClient $script:vcSession -Confirm:$false } |
            Should -Not -Throw
    }

    It 'Should delete the test certificate' {
        if (-not $script:testCertId) { Set-ItResult -Skipped -Because 'No test certificate created'; return }
        { Invoke-TrustCertificateAction -ID $script:testCertId -Delete -TrustClient $script:vcSession -Confirm:$false } |
            Should -Not -Throw
    }

    AfterAll {
        if ($script:testAppId) {
            Remove-CmsApplication -ID $script:testAppId -TrustClient $script:vcSession -Confirm:$false -ErrorAction SilentlyContinue
        }
        if ($script:testTeamId) {
            Remove-CmsTeam -ID $script:testTeamId -TrustClient $script:vcSession -Confirm:$false -ErrorAction SilentlyContinue
        }
    }
}

# ── Webhook Lifecycle ─────────────────────────────────────────────────────────

Describe 'CMSaaS Webhook Lifecycle' -Tags 'Functional', 'CMS', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-CmsFunctionalSession
        $script:testWebhookId = $null
    }

    It 'Should create a new webhook' {
        if (-not $env:VENAFIPS_CMS_WEBHOOK_URL) {
            Set-ItResult -Skipped -Because 'VENAFIPS_CMS_WEBHOOK_URL not set'
            return
        }
        $webhookName = New-TestName -Prefix 'venafips-hook'
        # get a valid event type from the API
        $activityTypes = Invoke-TrustRestMethod -UriLeaf 'activitytypes' -TrustClient $script:vcSession
        $eventType = $activityTypes.readablename | Select-Object -First 1
        if (-not $eventType) { Set-ItResult -Skipped -Because 'No activity types available'; return }

        $result = New-TrustWebhook -Name $webhookName -Url $env:VENAFIPS_CMS_WEBHOOK_URL -EventType $eventType -PassThru -TrustClient $script:vcSession
        $result | Should -Not -BeNullOrEmpty
        $script:testWebhookId = $result.webhookId
    }

    It 'Should get the created webhook' {
        if (-not $script:testWebhookId) { Set-ItResult -Skipped -Because 'No test webhook created'; return }
        $webhook = Get-TrustWebhook -ID $script:testWebhookId -TrustClient $script:vcSession
        $webhook | Should -Not -BeNullOrEmpty
    }

    It 'Should delete the webhook' {
        if (-not $script:testWebhookId) { Set-ItResult -Skipped -Because 'No test webhook created'; return }
        { Remove-TrustWebhook -ID $script:testWebhookId -TrustClient $script:vcSession -Confirm:$false } | Should -Not -Throw
    }
}

# ── Certificate Tag/Application Assignment ────────────────────────────────────

Describe 'CMSaaS Set Certificate' -Tags 'Functional', 'CMS', 'Write' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-CmsFunctionalSession
        $script:sampleCert = Find-TrustCertificate -First 1 -TrustClient $script:vcSession
        $script:testAppId = $null
        $script:testTeamId = $null
    }

    It 'Should assign an application to a certificate' {
        if (-not $script:sampleCert) { Set-ItResult -Skipped -Because 'No sample certificate found'; return }

        # create a temp team, then a temp app owned by that team
        $me = Get-CmsUser -Me -TrustClient $script:vcSession
        $teamName = New-TestName -Prefix 'venafips-setcert'
        New-CmsTeam -Name $teamName -Owner @($me.userId) -Member @($me.userId) -Role 'Resource Owner' -TrustClient $script:vcSession
        $team = Get-CmsTeam -All -TrustClient $script:vcSession | Where-Object { $_.name -eq $teamName }
        if (-not $team) { Set-ItResult -Skipped -Because 'Could not create owner team'; return }
        $script:testTeamId = $team.teamId

        $appName = New-TestName -Prefix 'venafips-assign'
        $app = New-CmsApplication -Name $appName -Owner $script:testTeamId -PassThru -TrustClient $script:vcSession
        $script:testAppId = $app.applicationId

        $certId = @($script:sampleCert)[0].certificateId
        { Set-TrustCertificate -Certificate $certId -Application $script:testAppId -NoOverwrite -TrustClient $script:vcSession } | Should -Not -Throw
    }

    It 'Should assign a tag to a certificate' {
        if (-not $script:sampleCert) { Set-ItResult -Skipped -Because 'No sample certificate found'; return }
        $tags = Get-TrustTag -All -TrustClient $script:vcSession
        if (-not $tags) { Set-ItResult -Skipped -Because 'No tags in environment'; return }
        $tagName = @($tags)[0].tagId
        if (-not $tagName) { Set-ItResult -Skipped -Because 'Tag has no name'; return }
        $certId = @($script:sampleCert)[0].certificateId
        { Set-TrustCertificate -Certificate $certId -Tag $tagName -NoOverwrite -TrustClient $script:vcSession } | Should -Not -Throw
    }

    AfterAll {
        if ($script:testAppId) {
            Remove-CmsApplication -ID $script:testAppId -TrustClient $script:vcSession -Confirm:$false -ErrorAction SilentlyContinue
        }
        if ($script:testTeamId) {
            Remove-CmsTeam -ID $script:testTeamId -TrustClient $script:vcSession -Confirm:$false -ErrorAction SilentlyContinue
        }
    }
}

# ── Issuing Templates & CAs ──────────────────────────────────────────────────

Describe 'CMSaaS Issuing Templates' -Tags 'Functional', 'CMS' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-CmsFunctionalSession
    }

    It 'Should list all issuing templates' {
        $templates = Get-TrustIssuingTemplate -All -TrustClient $script:vcSession
        $templates | Should -Not -BeNullOrEmpty
    }

    It 'Should get a single issuing template by ID' {
        $all = Get-TrustIssuingTemplate -All -TrustClient $script:vcSession
        if (-not $all) { Set-ItResult -Skipped -Because 'No issuing templates found'; return }
        $first = @($all)[0]
        $single = Get-TrustIssuingTemplate -IssuingTemplate $first.issuingTemplateId -TrustClient $script:vcSession
        $single | Should -Not -BeNullOrEmpty
        $single.issuingTemplateId | Should -Be $first.issuingTemplateId
    }
}

Describe 'CMSaaS Certificate Authorities' -Tags 'Functional', 'CMS' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-CmsFunctionalSession
    }

    It 'Should list all certificate authorities' {
        $cas = Get-TrustCertificateAuthority -All -TrustClient $script:vcSession
        $cas | Should -Not -BeNullOrEmpty
    }

    It 'Should get a single certificate authority' {
        $all = Get-TrustCertificateAuthority -All -TrustClient $script:vcSession
        if (-not $all) { Set-ItResult -Skipped -Because 'No CAs found'; return }
        $first = @($all)[0]
        $single = Get-TrustCertificateAuthority -CertificateAuthority $first.certificateAuthorityId -TrustClient $script:vcSession
        $single | Should -Not -BeNullOrEmpty
    }
}

# ── Machines ──────────────────────────────────────────────────────────────────

Describe 'CMSaaS Find Machines' -Tags 'Functional', 'CMS' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-CmsFunctionalSession
    }

    It 'Should find machines with -First' {
        $machines = Find-TrustMachine -First 5 -TrustClient $script:vcSession
        # may be empty if tenant has no machines
        if ($machines) {
            @($machines).Count | Should -BeLessOrEqual 5
        }
    }

    It 'Should return machine objects with expected properties' {
        $machines = Find-TrustMachine -First 1 -TrustClient $script:vcSession
        if (-not $machines) { Set-ItResult -Skipped -Because 'No machines in environment'; return }
        $m = @($machines)[0]
        $m.machineId | Should -Not -BeNullOrEmpty
    }
}

Describe 'CMSaaS Get Machine' -Tags 'Functional', 'CMS' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-CmsFunctionalSession
        $script:sampleMachine = Find-TrustMachine -First 1 -TrustClient $script:vcSession
    }

    It 'Should get a machine by ID' {
        if (-not $script:sampleMachine) { Set-ItResult -Skipped -Because 'No machines in environment'; return }
        $id = @($script:sampleMachine)[0].machineId
        $machine = Get-TrustMachine -Machine $id -TrustClient $script:vcSession
        $machine | Should -Not -BeNullOrEmpty
        $machine.machineId | Should -Be $id
    }

    It 'Should list all machines' {
        $all = Get-TrustMachine -All -TrustClient $script:vcSession
        # may be empty but should not throw
        { Get-TrustMachine -All -TrustClient $script:vcSession } | Should -Not -Throw
    }
}

# ── Machine Identities ───────────────────────────────────────────────────────

Describe 'CMSaaS Machine Identities' -Tags 'Functional', 'CMS' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-CmsFunctionalSession
        $script:sampleMI = Find-TrustMachineIdentity -First 1 -TrustClient $script:vcSession
    }

    It 'Should find machine identities with -First' {
        $mis = Find-TrustMachineIdentity -First 5 -TrustClient $script:vcSession
        if ($mis) {
            @($mis).Count | Should -BeLessOrEqual 5
        }
    }

    It 'Should get a machine identity by ID' {
        if (-not $script:sampleMI) { Set-ItResult -Skipped -Because 'No machine identities in environment'; return }
        $id = @($script:sampleMI)[0].machineIdentityId
        $mi = Get-TrustMachineIdentity -ID $id -TrustClient $script:vcSession
        $mi | Should -Not -BeNullOrEmpty
        $mi.machineIdentityId | Should -Be $id
    }
}

# ── Applications ──────────────────────────────────────────────────────────────

Describe 'CMSaaS Applications' -Tags 'Functional', 'CMS' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-CmsFunctionalSession
    }

    It 'Should list all applications' {
        $apps = Get-CmsApplication -All -TrustClient $script:vcSession
        $apps | Should -Not -BeNullOrEmpty
    }

    It 'Should get a single application by ID' {
        $all = Get-CmsApplication -All -TrustClient $script:vcSession
        if (-not $all) { Set-ItResult -Skipped -Because 'No applications found'; return }
        $first = @($all)[0]
        $single = Get-CmsApplication -Application $first.applicationId -TrustClient $script:vcSession
        $single | Should -Not -BeNullOrEmpty
        $single.applicationId | Should -Be $first.applicationId
    }

    It 'Should include config details with -IncludeConfig' {
        $all = Get-CmsApplication -All -TrustClient $script:vcSession
        if (-not $all) { Set-ItResult -Skipped -Because 'No applications found'; return }
        $first = @($all)[0]
        $app = Get-CmsApplication -Application $first.applicationId -IncludeConfig -TrustClient $script:vcSession
        $app | Should -Not -BeNullOrEmpty
    }
}

# ── Certificate Requests ──────────────────────────────────────────────────────

Describe 'CMSaaS Certificate Requests' -Tags 'Functional', 'CMS' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-CmsFunctionalSession
    }

    It 'Should find certificate requests with -First' {
        $reqs = Find-TrustCertificateRequest -First 5 -TrustClient $script:vcSession
        if ($reqs) {
            @($reqs).Count | Should -BeLessOrEqual 5
        }
    }

    It 'Should get a single certificate request by ID' {
        $reqs = Find-TrustCertificateRequest -First 1 -TrustClient $script:vcSession
        if (-not $reqs) { Set-ItResult -Skipped -Because 'No certificate requests found'; return }
        $first = @($reqs)[0]
        $single = Get-TrustCertificateRequest -CertificateRequest $first.certificateRequestId -TrustClient $script:vcSession
        $single | Should -Not -BeNullOrEmpty
        $single.certificateRequestId | Should -Be $first.certificateRequestId
    }
}

# ── Certificate Instances ─────────────────────────────────────────────────────

Describe 'CMSaaS Certificate Instances' -Tags 'Functional', 'CMS' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-CmsFunctionalSession
    }

    It 'Should find certificate instances with -First' {
        $instances = Find-TrustCertificateInstance -First 5 -TrustClient $script:vcSession
        if ($instances) {
            @($instances).Count | Should -BeLessOrEqual 5
        }
    }
}

# ── Teams ─────────────────────────────────────────────────────────────────────

Describe 'CMSaaS Teams' -Tags 'Functional', 'CMS' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-CmsFunctionalSession
    }

    It 'Should list all teams' {
        $teams = Get-CmsTeam -All -TrustClient $script:vcSession
        $teams | Should -Not -BeNullOrEmpty
    }

    It 'Should get a single team by ID' {
        $all = Get-CmsTeam -All -TrustClient $script:vcSession
        if (-not $all) { Set-ItResult -Skipped -Because 'No teams found'; return }
        $first = @($all)[0]
        $single = Get-CmsTeam -Team $first.teamId -TrustClient $script:vcSession
        $single | Should -Not -BeNullOrEmpty
        $single.teamId | Should -Be $first.teamId
    }
}

# ── Users ─────────────────────────────────────────────────────────────────────

Describe 'CMSaaS Users' -Tags 'Functional', 'CMS' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-CmsFunctionalSession
    }

    It 'Should get the current user with -Me' {
        $me = Get-CmsUser -Me -TrustClient $script:vcSession
        $me | Should -Not -BeNullOrEmpty
        $me.userId | Should -Not -BeNullOrEmpty
    }

    It 'Should list all users' {
        $users = Get-CmsUser -All -TrustClient $script:vcSession
        $users | Should -Not -BeNullOrEmpty
    }

    It 'Should get a user by ID' {
        $me = Get-CmsUser -Me -TrustClient $script:vcSession
        $user = Get-CmsUser -User $me.userId -TrustClient $script:vcSession
        $user | Should -Not -BeNullOrEmpty
        $user.userId | Should -Be $me.userId
    }
}

# ── Set User ──────────────────────────────────────────────────────────────────

# Describe 'CMSaaS Set User' -Tags 'Functional', 'CMS', 'Write' -Skip:$skipAll {

#     BeforeAll {
#         $script:vcSession = New-CmsFunctionalSession
#         $script:me = Get-CmsUser -Me -TrustClient $script:vcSession
#     }

#     It 'Should update account type to API' {
#         { Set-CmsUser -User $script:me.userId -AccountType 'API' -TrustClient $script:vcSession } | Should -Not -Throw
#     }

#     It 'Should update account type back to WEB_UI' {
#         { Set-CmsUser -User $script:me.userId -AccountType 'WEB_UI' -TrustClient $script:vcSession } | Should -Not -Throw
#     }

#     It 'Should return updated user with -PassThru' {
#         $updated = Set-CmsUser -User $script:me.userId -AccountType 'API' -PassThru -TrustClient $script:vcSession
#         $updated | Should -Not -BeNullOrEmpty
#         $updated.userId | Should -Be $script:me.userId

#         # restore
#         Set-CmsUser -User $script:me.userId -AccountType 'WEB_UI' -TrustClient $script:vcSession -ErrorAction SilentlyContinue
#     }
# }

# ── Tags ──────────────────────────────────────────────────────────────────────

Describe 'CMSaaS Tags' -Tags 'Functional', 'CMS' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-CmsFunctionalSession
    }

    It 'Should list all tags' {
        $tags = Get-TrustTag -All -TrustClient $script:vcSession
        # may be empty but should not throw
        { Get-TrustTag -All -TrustClient $script:vcSession } | Should -Not -Throw
    }
}

# ── Connectors ────────────────────────────────────────────────────────────────

Describe 'CMSaaS Connectors' -Tags 'Functional', 'CMS' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-CmsFunctionalSession
    }

    It 'Should list all connectors' {
        $connectors = Get-TrustConnector -All -TrustClient $script:vcSession
        # may be empty but should not throw
        { Get-TrustConnector -All -TrustClient $script:vcSession } | Should -Not -Throw
    }

    It 'Should get a single connector by ID' {
        $all = Get-TrustConnector -All -TrustClient $script:vcSession
        if (-not $all) { Set-ItResult -Skipped -Because 'No connectors found'; return }
        $first = @($all)[0]
        $single = Get-TrustConnector -Connector $first.connectorId -TrustClient $script:vcSession
        $single | Should -Not -BeNullOrEmpty
    }
}

# ── Webhooks ──────────────────────────────────────────────────────────────────

Describe 'CMSaaS Webhooks' -Tags 'Functional', 'CMS' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-CmsFunctionalSession
    }

    It 'Should list all webhooks' {
        { Get-TrustWebhook -All -TrustClient $script:vcSession } | Should -Not -Throw
    }
}

# ── Satellites ────────────────────────────────────────────────────────────────

Describe 'CMSaaS Satellites' -Tags 'Functional', 'CMS' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-CmsFunctionalSession
    }

    It 'Should list all satellites' {
        { Get-TrustSatellite -All -TrustClient $script:vcSession } | Should -Not -Throw
    }

    It 'Should get a satellite with workers' {
        $all = Get-TrustSatellite -All -TrustClient $script:vcSession
        if (-not $all) { Set-ItResult -Skipped -Because 'No satellites found'; return }
        $first = @($all)[0]
        $sat = Get-TrustSatellite -VSatellite $first.vsatelliteId -IncludeWorkers -TrustClient $script:vcSession
        $sat | Should -Not -BeNullOrEmpty
    }
}

# ── Cloud Keystores & Providers ───────────────────────────────────────────────

Describe 'CMSaaS Cloud Providers' -Tags 'Functional', 'CMS' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-CmsFunctionalSession
    }

    It 'Should list all cloud providers' {
        { Get-TrustCloudProvider -All -TrustClient $script:vcSession } | Should -Not -Throw
    }

    It 'Should get a single cloud provider by ID' {
        $all = Get-TrustCloudProvider -All -TrustClient $script:vcSession
        if (-not $all) { Set-ItResult -Skipped -Because 'No cloud providers found'; return }
        $first = @($all)[0]
        $single = Get-TrustCloudProvider -CloudProvider $first.cloudProviderId -TrustClient $script:vcSession
        $single | Should -Not -BeNullOrEmpty
    }
}

Describe 'CMSaaS Cloud Keystores' -Tags 'Functional', 'CMS' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-CmsFunctionalSession
    }

    It 'Should list all cloud keystores' {
        { Get-TrustCloudKeystore -All -TrustClient $script:vcSession } | Should -Not -Throw
    }
}

# ── Logs ──────────────────────────────────────────────────────────────────────

Describe 'CMSaaS Activity Log' -Tags 'Functional', 'CMS' -Skip:$skipAll {

    BeforeAll {
        $script:vcSession = New-CmsFunctionalSession
    }

    It 'Should find recent log entries' {
        $logs = Find-TrustLog -First 5 -TrustClient $script:vcSession
        $logs | Should -Not -BeNullOrEmpty
    }

    It 'Should filter critical log entries' {
        { Find-TrustLog -Critical -First 5 -TrustClient $script:vcSession } | Should -Not -Throw
    }
}
