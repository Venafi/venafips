BeforeAll {
    . $PSScriptRoot/ModuleCommon.ps1

    function New-TestClient {
        param($Platform)
        & (Get-Module VenafiPS) {
            param($Platform)
            $tc = [TrustClient]::new()
            $tc.Platform = $Platform
            $tc.Server = 'https://venafi.company.com'
            $tc.AccessToken = [pscredential]::new('AccessToken', ('reallySecure!' | ConvertTo-SecureString -AsPlainText -Force))
            $tc.Expires = [datetime]::UtcNow.AddHours(1)
            $tc
        } $Platform
    }

    function Invoke-TestRequest {
        param([string] $Json, $Platform = 'CM')
        $client = New-TestClient $Platform
        InModuleScope $ModuleName -Parameters @{ Json = $Json; Client = $client } {
            $tools = @(Get-TrustMcpTool -Platform $Client.Platform)
            Invoke-TrustMcpRequest -Message ($Json | ConvertFrom-Json) -Tool $tools -TrustClient $Client
        }
    }
}

Describe 'Get-TrustMcpTool' -Tags 'Unit' {

    It 'Should have a unique tool name per platform' -ForEach @('CM', 'CMS', 'NGTS') {
        $platform = $_
        $names = InModuleScope $ModuleName -Parameters @{ Platform = $platform } { (Get-TrustMcpTool -Platform $Platform).name }
        $names | Should -Not -BeNullOrEmpty
        ($names | Group-Object | Where-Object Count -gt 1) | Should -BeNullOrEmpty
    }

    It 'Should add the required token scope to CM tools from the function config' {
        $tools = InModuleScope $ModuleName { Get-TrustMcpTool -Platform CM }
        foreach ( $t in $tools ) {
            $t.cmTokenScope | Should -Not -BeNullOrEmpty -Because $t.name
            $t.description | Should -Match ('Requires token scope: {0}\.$' -f [regex]::Escape($t.cmTokenScope)) -Because $t.name
        }
        ($tools | Where-Object name -eq 'find_certificates').cmTokenScope | Should -Be 'certificate'
        ($tools | Where-Object name -eq 'get_permissions').cmTokenScope | Should -Be 'security'
        ($tools | Where-Object name -eq 'search_logs').cmTokenScope | Should -Be 'any'
        # the chain is built from certificate details and AIA, retrieving the certificate would need certificate:manage
        ($tools | Where-Object name -eq 'get_certificate_chain').cmTokenScope | Should -Be 'certificate'
        # a tool's cmScope is included, the engine endpoints are called directly
        ($tools | Where-Object name -eq 'get_system_status').cmTokenScope | Should -Be 'configuration'
        # every tool works with the read-only scopes except get_permissions
        $tools | Where-Object { $_.cmTokenScope -match ':' } | Should -BeNullOrEmpty
    }

    It 'Should have a token scope in the function config for every CM function a CM tool calls' {
        $missing = InModuleScope $ModuleName {
            foreach ( $t in (Get-TrustMcpTool -Platform CM) ) {
                $t.handler.Ast.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true) |
                    ForEach-Object { $_.GetCommandName() } | Where-Object { $_ -cmatch '^\w+-Cm[A-Z]' } | Sort-Object -Unique |
                    Where-Object { -not $script:functionConfig.$_.CmTokenScope } | ForEach-Object { '{0} in {1}' -f $_, $t.name }
            }
        }
        $missing | Should -BeNullOrEmpty
    }

    It 'Should not add token scopes to SaaS tools' {
        $tools = InModuleScope $ModuleName { Get-TrustMcpTool -Platform CMS }
        $tools.description | Should -Not -Match 'Requires token scope'
    }

    It 'Should only offer CM specific tools to CM' {
        $cm = InModuleScope $ModuleName { (Get-TrustMcpTool -Platform CM).name }
        $cms = InModuleScope $ModuleName { (Get-TrustMcpTool -Platform CMS).name }
        $cm | Should -Contain 'browse_policy_tree'
        $cm | Should -Contain 'get_attributes'
        $cm | Should -Not -Contain 'find_machines'
        $cms | Should -Contain 'find_machines'
        $cms | Should -Not -Contain 'browse_policy_tree'
        $cms | Should -Not -Contain 'get_attributes'
        'list_ca_templates', 'find_workflow_tickets', 'get_certificate_consumers', 'get_certificate_chain', 'find_objects_by_attribute', 'list_class_attributes', 'get_system_status', 'get_permissions', 'certificate_inventory_summary' | ForEach-Object {
            $cm | Should -Contain $_
            $cms | Should -Not -Contain $_
        }
        'list_applications', 'find_certificate_requests', 'list_vsatellites', 'list_connectors', 'find_machine_identities', 'list_certificate_authorities', 'list_issuing_templates' | ForEach-Object {
            $cms | Should -Contain $_
            $cm | Should -Not -Contain $_
        }
        $cm | Should -Contain 'get_identity'
        $cms | Should -Contain 'get_identity'
    }
}

Describe 'Invoke-TrustMcpConnect' -Tags 'Unit' {

    It 'Should use a session returned by Connect, eg. New-TrustClient -PassThru' {
        InModuleScope $ModuleName {
            $returned = [TrustClient]::new()
            $returned.Server = 'https://returned'
            $out = Invoke-TrustMcpConnect -Connect { $returned }.GetNewClosure()
            $out.Server | Should -Be 'https://returned'
            $script:TrustClient.Server | Should -Be 'https://returned'
        }
    }

    It 'Should use a session stored but not returned by Connect, eg. New-TrustClient without -PassThru' {
        InModuleScope $ModuleName {
            $script:TrustClient = [TrustClient]::new()
            # what New-TrustClient does without -PassThru: store a new session and output nothing
            $out = Invoke-TrustMcpConnect -Connect { & (Get-Module VenafiPS) { $script:TrustClient = [TrustClient]::new(); $script:TrustClient.Server = 'https://stored' } }
            $out.Server | Should -Be 'https://stored'
        }
    }

    It 'Should update the existing session in place and make it the default' {
        InModuleScope $ModuleName {
            $existing = [TrustClient]::new()
            $existing.Server = 'https://old'
            $existing.ClientId = 'old'
            $script:TrustClient = $existing

            $out = Invoke-TrustMcpConnect -Session $existing -Connect { & (Get-Module VenafiPS) { $script:TrustClient = [TrustClient]::new(); $script:TrustClient.Server = 'https://new'; $script:TrustClient.ClientId = 'new' } }

            [object]::ReferenceEquals($out, $existing) | Should -BeTrue
            [object]::ReferenceEquals($script:TrustClient, $existing) | Should -BeTrue
            $existing.Server | Should -Be 'https://new'
            $existing.ClientId | Should -Be 'new'
        }
    }

    It 'Should return nothing, and not output messages, when Connect creates no session' {
        InModuleScope $ModuleName {
            $script:TrustClient = [TrustClient]::new()
            $out = @(Invoke-TrustMcpConnect -Connect { 'a message'; Write-Warning 'a warning' } 3>$null)
            $out.Count | Should -Be 0
        }
    }
}

Describe 'Invoke-TrustMcpRequest' -Tags 'Unit' {

    Context 'Protocol' {

        It 'Should echo a supported protocol version on initialize' {
            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18"}}'
            $r.id | Should -Be 1
            $r.result.protocolVersion | Should -Be '2025-06-18'
            $r.result.serverInfo.name | Should -Be 'VenafiPS'
            $r.result.capabilities.tools | Should -Not -BeNullOrEmpty
        }

        It 'Should fall back to the newest version for an unknown protocol version' {
            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"1999-01-01"}}'
            $r.result.protocolVersion | Should -Be '2025-11-25'
        }

        It 'Should not respond to notifications' {
            Invoke-TestRequest '{"jsonrpc":"2.0","method":"notifications/initialized"}' | Should -BeNullOrEmpty
        }

        It 'Should return method not found' {
            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":"abc","method":"bogus"}'
            $r.id | Should -Be 'abc'
            $r.error.code | Should -Be -32601
        }

        It 'Should respond to ping' {
            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":2,"method":"ping"}'
            $r.Keys | Should -Contain 'result'
            $r.result | Should -BeOfType [hashtable]
            $r.result.Count | Should -Be 0
        }

        It 'Should list tools as read-only with input schemas' {
            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":3,"method":"tools/list"}'
            $r.result.tools.Count | Should -BeGreaterThan 1
            $r.result.tools | ForEach-Object {
                $_.inputSchema.type | Should -Be 'object'
                $_.annotations.readOnlyHint | Should -BeTrue
                $_.Keys | Should -Not -Contain 'handler'
            }
        }

        It 'Should return an invalid params error for an unknown tool' {
            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"find_machines"}}' -Platform CM
            $r.error.code | Should -Be -32602
        }
    }

    Context 'Reconnect' {

        BeforeAll {
            # fails with 401 until the session has been replaced by reconnect
            function Invoke-ReconnectRequest {
                param([scriptblock] $Reconnect, [string] $FailWith = 'Response status code does not indicate success: 401 (Unauthorized).')
                $client = New-TestClient 'CM'
                InModuleScope $ModuleName -Parameters @{ Client = $client; Reconnect = $Reconnect; FailWith = $FailWith } {
                    $tool = @{
                        name    = 'flaky'
                        handler = {
                            param($Arguments, $TrustClient)
                            $TrustClient.PlatformData.calls++
                            if ( -not $TrustClient.PlatformData.reconnected ) { throw $TrustClient.PlatformData.failWith }
                            @{ calls = $TrustClient.PlatformData.calls }
                        }
                    }
                    $Client.PlatformData.failWith = $FailWith
                    $r = Invoke-TrustMcpRequest -Message ('{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"flaky"}}' | ConvertFrom-Json) -Tool $tool -TrustClient $Client -Reconnect $Reconnect
                    [pscustomobject]@{ Response = $r; Client = $Client }
                }
            }
        }

        It 'Should reconnect and retry once on 401' {
            $r = Invoke-ReconnectRequest -Reconnect { param($Session) $Session.PlatformData.reconnected = $true }

            $r.Response.result.isError | Should -BeFalse
            ($r.Response.result.content[0].text | ConvertFrom-Json).calls | Should -Be 2
        }

        It 'Should not retry more than once' {
            $r = Invoke-ReconnectRequest -Reconnect { param($Session) $Session.PlatformData.reconnects++ }

            $r.Response.result.isError | Should -BeTrue
            $r.Response.result.content[0].text | Should -Match '401'
            $r.Client.PlatformData.calls | Should -Be 2
            $r.Client.PlatformData.reconnects | Should -Be 1
        }

        It 'Should not reconnect on other errors' {
            $r = Invoke-ReconnectRequest -Reconnect { param($Session) $Session.PlatformData.reconnected = $true } -FailWith 'Response status code does not indicate success: 404 (Not Found).'

            $r.Response.result.isError | Should -BeTrue
            $r.Client.PlatformData.calls | Should -Be 1
            $r.Client.PlatformData.reconnected | Should -BeNullOrEmpty
        }

        It 'Should report when reconnecting fails' {
            $r = Invoke-ReconnectRequest -Reconnect { throw 'vault entry not found' }

            $r.Response.result.isError | Should -BeTrue
            $r.Response.result.content[0].text | Should -Match '401.*Connecting again also failed: vault entry not found'
        }

        It 'Should not reconnect without a Connect scriptblock' {
            $r = Invoke-ReconnectRequest -Reconnect $null

            $r.Response.result.isError | Should -BeTrue
            $r.Client.PlatformData.calls | Should -Be 1
        }
    }

    Context 'Tool calls' {

        It 'Should not return secrets from whoami' {
            Mock -CommandName 'Get-CmIdentity' -ModuleName $ModuleName -MockWith { [pscustomobject]@{ Name = 'greg'; ID = 'AD+x:1'; FullName = 'AD+x:greg'; Path = 'CN=Greg' } }
            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"whoami"}}'
            $r.result.isError | Should -BeFalse
            $r.result.content[0].text | Should -Not -Match 'reallySecure'
            ($r.result.content[0].text | ConvertFrom-Json).platform | Should -Be 'CM'
        }

        It 'Should return the CM identity, client id, scope, and vault entry from whoami' {
            Mock -CommandName 'Get-CmIdentity' -ModuleName $ModuleName -MockWith { [pscustomobject]@{ Name = 'greg'; ID = 'AD+x:1'; FullName = 'AD+x:greg'; Path = 'CN=Greg' } }
            $client = New-TestClient 'CM'
            $client.ClientId = 'VenafiPS-MCP'
            $client.Scope = @{ certificate = $null; configuration = $null }
            $client.AuthServer = $client.Server
            $client.RefreshToken = [pscredential]::new('RefreshToken', ('refreshSecret!' | ConvertTo-SecureString -AsPlainText -Force))
            $client.VaultRefreshTokenName = 'venafips-mcp'

            $r = InModuleScope $ModuleName -Parameters @{ Client = $client } {
                Invoke-TrustMcpRequest -Message ('{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"whoami"}}' | ConvertFrom-Json) -Tool @(Get-TrustMcpTool -Platform CM) -TrustClient $Client
            }

            $r.result.isError | Should -BeFalse
            $r.result.content[0].text | Should -Not -Match 'refreshSecret'
            $out = $r.result.content[0].text | ConvertFrom-Json
            $out.identity.fullName | Should -Be 'AD+x:greg'
            $out.clientId | Should -Be 'VenafiPS-MCP'
            $out.scope.PSObject.Properties.Name | Should -Contain 'configuration'
            $out.vaultEntry | Should -Be 'venafips-mcp'
            $out.canRefresh | Should -BeTrue
            # same as the server, so not repeated
            $out.PSObject.Properties.Name | Should -Not -Contain 'authServer'
        }

        It 'Should return the SaaS user and roles from whoami' {
            Mock -CommandName 'Get-CmsUser' -ModuleName $ModuleName -MockWith {
                [pscustomobject]@{ userId = 'u1'; username = 'me@company.com'; firstname = 'Me'; lastname = 'User'; emailAddress = 'me@company.com'; userType = 'EXTERNAL'; userAccountType = 'API'; userStatus = 'ACTIVE'; systemRoles = @('RESOURCE_OWNER'); productRoles = @{}; ownedTeams = @(); memberedTeams = @('t1'); hasPassword = $true }
            }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"whoami"}}' -Platform CMS

            $r.result.isError | Should -BeFalse
            $out = $r.result.content[0].text | ConvertFrom-Json
            $out.identity.username | Should -Be 'me@company.com'
            $out.identity.name | Should -Be 'Me User'
            $out.identity.systemRoles | Should -Be @('RESOURCE_OWNER')
            $out.identity.PSObject.Properties.Name | Should -Not -Contain 'hasPassword'
            $out.PSObject.Properties.Name | Should -Not -Contain 'clientId'
        }

        It 'Should still return connection details when the identity lookup fails' {
            Mock -CommandName 'Get-CmIdentity' -ModuleName $ModuleName -MockWith { throw 'access denied' }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"whoami"}}'

            $r.result.isError | Should -BeFalse
            $out = $r.result.content[0].text | ConvertFrom-Json
            $out.server | Should -Be 'https://venafi.company.com'
            $out.identity | Should -BeNullOrEmpty
            $out.identityError | Should -Match 'access denied'
        }

        It 'Should map CM find_certificates arguments' {
            Mock -CommandName 'Find-CmCertificate' -ModuleName $ModuleName -MockWith {
                if ( $CountOnly ) { return 10 }
                [pscustomobject]@{ Name = 'c1'; Path = '\VED\Policy\c1'; Guid = [guid]::Empty; TypeName = 'X509 Certificate' }
            }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":6,"method":"tools/call","params":{"name":"find_certificates","arguments":{"path":"\\VED\\Policy","common_name":"www","expiring_within_days":30,"first":500}}}'

            $r.result.isError | Should -BeFalse
            $out = $r.result.content[0].text | ConvertFrom-Json
            $out.totalMatches | Should -Be 10
            $out.certificates[0].Path | Should -Be '\VED\Policy\c1'

            Should -Invoke -CommandName 'Find-CmCertificate' -ModuleName $ModuleName -Times 1 -ParameterFilter {
                $First -eq 200 -and $Path -eq '\VED\Policy' -and $Recursive -and $CommonName -eq 'www' -and $ExpireBefore -and $ExpireAfter
            }
        }

        It 'Should match a partial issuer locally for CM find_certificates' {
            Mock -CommandName 'Find-CmCertificate' -ModuleName $ModuleName -MockWith {
                if ( $CountOnly ) { return 3 }
                @(
                    @{ n = 'a'; i = 'CN=Company Issuing CA1, DC=corp, DC=company, DC=com' }
                    @{ n = 'b'; i = 'CN=issuing-ca-1, DC=other, DC=example, DC=com' }
                    @{ n = 'c'; i = 'CN=COMPANY ISSUING CA1, DC=corp, DC=company, DC=com' }
                ) | ForEach-Object {
                    [pscustomobject]@{ Name = $_.n; Path = "\VED\Policy\$($_.n)"; Guid = [guid]::Empty; X509 = [pscustomobject]@{ Issuer = $_.i } }
                }
            }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":30,"method":"tools/call","params":{"name":"find_certificates","arguments":{"issuer":"company issuing","path":"\\VED\\Policy"}}}'

            $r.result.isError | Should -BeFalse
            $out = $r.result.content[0].text | ConvertFrom-Json
            $out.totalMatches | Should -Be 2
            $out.scanned | Should -Be 3
            $out.truncated | Should -BeFalse
            # the api issuer filter is case-insensitive so case-only variants are one exact search
            @($out.matchedIssuers).Count | Should -Be 1
            $out.certificates.Name | Should -Be @('a', 'c')
            $out.certificates[0].PSObject.Properties.Name | Should -Not -Contain 'X509'

            Should -Invoke -CommandName 'Find-CmCertificate' -ModuleName $ModuleName -Times 1 -ParameterFilter {
                -not $CountOnly -and $First -eq 5000 -and $OptionalField -contains 'Issuer' -and -not $Issuer -and $Path -eq '\VED\Policy'
            }
        }

        It 'Should report truncation for a partial issuer scan' {
            Mock -CommandName 'Find-CmCertificate' -ModuleName $ModuleName -MockWith {
                if ( $CountOnly ) { return 12000 }
                [pscustomobject]@{ Name = 'a'; Path = '\VED\Policy\a'; Guid = [guid]::Empty; X509 = [pscustomobject]@{ Issuer = 'CN=Example CA' } }
            }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":33,"method":"tools/call","params":{"name":"find_certificates","arguments":{"issuer":"Example"}}}'

            $out = $r.result.content[0].text | ConvertFrom-Json
            $out.truncated | Should -BeTrue
            $out.scanned | Should -Be 5000
        }

        It 'Should pass a full issuer DN through for CM find_certificates' {
            Mock -CommandName 'Find-CmCertificate' -ModuleName $ModuleName -MockWith { if ( $CountOnly ) { 37 } }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":31,"method":"tools/call","params":{"name":"find_certificates","arguments":{"issuer":"CN=Company Issuing CA, DC=corp, DC=company, DC=com"}}}'

            $r.result.isError | Should -BeFalse
            ($r.result.content[0].text | ConvertFrom-Json).totalMatches | Should -Be 37
            Should -Invoke -CommandName 'Find-CmCertificate' -ModuleName $ModuleName -ParameterFilter { $Issuer -eq 'CN=Company Issuing CA, DC=corp, DC=company, DC=com' }
        }

        It 'Should include X509 details for CM find_certificates when requested' {
            Mock -CommandName 'Find-CmCertificate' -ModuleName $ModuleName -MockWith {
                if ( $CountOnly ) { return 1 }
                $c = [pscustomobject]@{ Name = 'c1'; Path = '\VED\Policy\c1'; Guid = [guid]::Empty; TypeName = 'X509 Certificate' }
                if ( $OptionalField ) { $c | Add-Member -NotePropertyName X509 -NotePropertyValue ([pscustomobject]@{ Issuer = 'CN=CA1, DC=lab' }) }
                $c
            }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":32,"method":"tools/call","params":{"name":"find_certificates","arguments":{"include_details":true}}}'

            $out = $r.result.content[0].text | ConvertFrom-Json
            $out.certificates[0].X509.Issuer | Should -Be 'CN=CA1, DC=lab'
            Should -Invoke -CommandName 'Find-CmCertificate' -ModuleName $ModuleName -Times 1 -ParameterFilter { $OptionalField -contains 'Issuer' -and -not $CountOnly }
            Should -Invoke -CommandName 'Find-CmCertificate' -ModuleName $ModuleName -Times 1 -ParameterFilter { -not $OptionalField -and $CountOnly }
        }

        It 'Should return tool errors as isError results' {
            Mock -CommandName 'Find-TrustCertificate' -ModuleName $ModuleName -MockWith { throw 'Request parsing failed' }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":7,"method":"tools/call","params":{"name":"find_certificates","arguments":{}}}' -Platform CMS

            $r.error | Should -BeNullOrEmpty
            $r.result.isError | Should -BeTrue
            $r.result.content[0].text | Should -Be 'Request parsing failed'
        }

        It 'Should reject expired with expiring_within_days' {
            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":8,"method":"tools/call","params":{"name":"find_certificates","arguments":{"expired":true,"expiring_within_days":5}}}' -Platform CMS
            $r.result.isError | Should -BeTrue
        }

        It 'Should require class and attributes for recursive get_attributes' {
            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":10,"method":"tools/call","params":{"name":"get_attributes","arguments":{"path":"\\VED\\Policy","recursive":true,"class":"X509 Certificate"}}}'
            $r.result.isError | Should -BeTrue
            $r.result.content[0].text | Should -Match 'requires class and attributes'
        }

        It 'Should get object attributes keyed by name' {
            Mock -CommandName 'Get-CmAttribute' -ModuleName $ModuleName -MockWith {
                [pscustomobject]@{
                    Path      = $Path
                    Attribute = @(
                        [pscustomobject]@{ Name = 'Contact'; Value = 'local:{abc}'; PolicyPath = '\VED\Policy'; Locked = $false; Overridden = $false }
                        [pscustomobject]@{ Name = 'Private Key Password'; Value = 'oops'; PolicyPath = ''; Locked = $false; Overridden = $false }
                    )
                }
            }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":11,"method":"tools/call","params":{"name":"get_attributes","arguments":{"path":"\\VED\\Policy\\c1"}}}'

            $r.result.isError | Should -BeFalse
            $r.result.content[0].text | Should -Not -Match 'oops'
            $out = $r.result.content[0].text | ConvertFrom-Json
            $out.path | Should -Be '\VED\Policy\c1'
            $out.attributes.Contact.value | Should -Be 'local:{abc}'
            $out.attributes.Contact.policyPath | Should -Be '\VED\Policy'

            Should -Invoke -CommandName 'Get-CmAttribute' -ModuleName $ModuleName -Times 1 -ParameterFilter { $All -and -not $Class }
        }

        It 'Should filter the policy tree by name' {
            Mock -CommandName 'Find-CmObject' -ModuleName $ModuleName -MockWith {
                [pscustomobject]@{ Name = 'test.company.com'; TypeName = 'X509 Server Certificate'; Path = '\VED\Policy\test.company.com'; Guid = [guid]::NewGuid() }
            }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":30,"method":"tools/call","params":{"name":"browse_policy_tree","arguments":{"name":"test","recursive":true}}}'
            $r.result.isError | Should -BeFalse
            ($r.result.content[0].text | ConvertFrom-Json).total | Should -Be 1
            Should -Invoke -CommandName 'Find-CmObject' -ModuleName $ModuleName -Times 1 -ParameterFilter { $Pattern -eq '*test*' -and $Recursive }

            $null = Invoke-TestRequest '{"jsonrpc":"2.0","id":31,"method":"tools/call","params":{"name":"browse_policy_tree","arguments":{"name":"test?.company.com"}}}'
            Should -Invoke -CommandName 'Find-CmObject' -ModuleName $ModuleName -Times 1 -ParameterFilter { $Pattern -eq 'test?.company.com' }
        }

        It 'Should decode log data and filter by event and text' {
            Mock -CommandName 'Read-CmLog' -ModuleName $ModuleName -MockWith {
                # IRS-Noop-AdaptableApp, and Software which is valid base64 but not text
                [pscustomobject]@{ ServerTimestamp = [datetime]::UtcNow; Severity = 'Info'; Name = 'Admin UI - Policy Configuration Changed'; Component = '\VED\Policy\a'; Text1 = 'AD+x:greg'; Text2 = 'Adaptable App:PowerShell Script'; Data = "\VED\Policy\a`r`n1`r`nSVJTLU5vb3AtQWRhcHRhYmxlQXBw`r`nSoftware`r`n(null)`r`n"; Value1 = 0; Value2 = 0; SourceIP = '10.0.0.1'; EventId = '000c001f'; Grouping = 1 }
                [pscustomobject]@{ ServerTimestamp = [datetime]::UtcNow; Severity = 'Info'; Name = 'Certificate Renewal'; Component = '\VED\Policy\a\c'; Text1 = 'x'; Text2 = 'y'; Data = $null; Value1 = 0; Value2 = 0; SourceIP = $null; EventId = '1'; Grouping = 2 }
            }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":41,"method":"tools/call","params":{"name":"search_logs","arguments":{"path":"\\VED\\Policy\\a"}}}'
            $r.result.isError | Should -BeFalse
            $out = $r.result.content[0].text | ConvertFrom-Json
            $out.returned | Should -Be 2
            $out.events[0].data | Should -Contain 'IRS-Noop-AdaptableApp'
            $out.events[0].data | Should -Contain 'Software'
            $out.events[0].data | Should -Contain '1'
            $out.events[0].PSObject.Properties.Name | Should -Not -Contain 'Grouping'
            Should -Invoke -CommandName 'Read-CmLog' -ModuleName $ModuleName -Times 1 -ParameterFilter { $First -eq 50 -and $Path -eq '\VED\Policy\a' }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":42,"method":"tools/call","params":{"name":"search_logs","arguments":{"text":"noop"}}}'
            $out = $r.result.content[0].text | ConvertFrom-Json
            $out.returned | Should -Be 1
            $out.events[0].name | Should -Be 'Admin UI - Policy Configuration Changed'
            Should -Invoke -CommandName 'Read-CmLog' -ModuleName $ModuleName -Times 1 -ParameterFilter { $First -eq 2000 }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":43,"method":"tools/call","params":{"name":"search_logs","arguments":{"event":"renewal"}}}'
            $out = $r.result.content[0].text | ConvertFrom-Json
            $out.returned | Should -Be 1
            $out.events[0].name | Should -Be 'Certificate Renewal'
        }

        It 'Should search event ids on the server and merge them newest first' {
            Mock -CommandName 'Read-CmLog' -ModuleName $ModuleName -MockWith {
                $t = if ( $EventId -eq '46680017' ) { [datetime]::UtcNow.AddHours(-1) } else { [datetime]::UtcNow }
                [pscustomobject]@{ ServerTimestamp = $t; Severity = 'Error'; Name = "event $EventId"; Component = '\VED\Policy\a'; Data = $null; EventId = $EventId }
            }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":47,"method":"tools/call","params":{"name":"search_logs","arguments":{"event_id":["46680017","46680026"],"since_hours":336}}}'
            $r.result.isError | Should -BeFalse
            $out = $r.result.content[0].text | ConvertFrom-Json
            $out.returned | Should -Be 2
            $out.events[0].name | Should -Be 'event 46680026'
            Should -Invoke -CommandName 'Read-CmLog' -ModuleName $ModuleName -Times 1 -ParameterFilter { $EventId -eq '46680017' }
            Should -Invoke -CommandName 'Read-CmLog' -ModuleName $ModuleName -Times 1 -ParameterFilter { $EventId -eq '46680026' }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":48,"method":"tools/call","params":{"name":"search_logs","arguments":{"event_id":["nope"]}}}'
            $r.result.isError | Should -BeTrue
            $r.result.content[0].text | Should -Match '8 hex digits'
        }

        It 'Should group log events and drop stack frames' {
            Mock -CommandName 'Read-CmLog' -ModuleName $ModuleName -MockWith {
                $e = { param($name, $component, $msg, $hoursAgo) [pscustomobject]@{ ServerTimestamp = [datetime]::UtcNow.AddHours(-$hoursAgo); Severity = 'Error'; Name = $name; Component = $component; Text2 = $msg; Data = "   at Venafi.Drivers.Applications.Adaptable.Validate(String PlatformDN)`r`n"; EventId = '46680017' } }
                & $e 'Validate Installation Failure' '\VED\Policy\app1' 'Result is empty' 1
                & $e 'Validate Installation Failure' '\VED\Policy\app1' 'Result is empty' 25
                & $e 'Validate Installation Failure' '\VED\Policy\app1' 'Other error' 49
                & $e 'Validate Installation Failure' '\VED\Policy\app2' 'Handshake failure' 2
                & $e 'Script Mismatch Detected' '\VED\Policy\app2' 'hash' 3
            }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":49,"method":"tools/call","params":{"name":"search_logs","arguments":{"event_id":["46680017"],"group_by":"event_and_component"}}}'
            $r.result.isError | Should -BeFalse
            $r.result.content[0].text | Should -Not -Match 'Venafi\.Drivers'
            $out = $r.result.content[0].text | ConvertFrom-Json
            $out.totalEvents | Should -Be 5
            $out.totalGroups | Should -Be 3
            $out.moreMayExist | Should -BeFalse
            $out.groups[0].component | Should -Be '\VED\Policy\app1'
            $out.groups[0].count | Should -Be 3
            $out.groups[0].message | Should -Be 'Result is empty'
            ([datetime]$out.groups[0].first) | Should -BeLessThan ([datetime]$out.groups[0].last)
            Should -Invoke -CommandName 'Read-CmLog' -ModuleName $ModuleName -Times 1 -ParameterFilter { $First -eq 2000 }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":50,"method":"tools/call","params":{"name":"search_logs","arguments":{"group_by":"component"}}}'
            $out = $r.result.content[0].text | ConvertFrom-Json
            $out.totalGroups | Should -Be 2
            ($out.groups | Where-Object component -eq '\VED\Policy\app2').events.Count | Should -Be 2
        }

        It 'Should report validity reduction readiness and crypto posture' {
            Mock -CommandName 'Find-CmCertificate' -ModuleName $ModuleName -MockWith {
                if ( $CountOnly ) {
                    # Unassigned is 0, so check the parameter was passed rather than its value
                    if ( $PesterBoundParameters.ContainsKey('ManagementType') ) { return @{ Provisioning = 5; Enrollment = 3; Monitoring = 7; Unassigned = 2 }["$($ManagementType[0])"] }
                    # 25.1 matches the long names only
                    if ( $SignatureAlgorithm ) { return @{ 'sha1WithRSAEncryption' = 4; 'ecdsa-with-SHA1' = 1; 'md5WithRSAEncryption' = 2 }[$SignatureAlgorithm] }
                    if ( $PesterBoundParameters.ContainsKey('IsWildcard') ) { return 6 }
                    if ( $PesterBoundParameters.ContainsKey('IsSelfSigned') ) { return 8 }
                    return 4
                }
                $now = Get-Date
                $c = { param($from, $to, $size, $sans) [pscustomobject]@{ Name = 'x'; TypeName = 'X509 Server Certificate'; ParentPath = '\VED\Policy\a'; X509 = [pscustomobject]@{ ValidFrom = $from; ValidTo = $to; Issuer = 'CN=CA'; KeyAlgorithm = 'RSA'; KeySize = $size; SANS = [pscustomobject]@{ DNS = $sans; IP = @() } } } }
                & $c $now.AddDays(-10) $now.AddDays(30) 2048 @('a.com')
                & $c $now.AddDays(-10) $now.AddDays(80) 2048 @('b.com')
                & $c $now.AddDays(-100) $now.AddDays(265) 1024 @()
                & $c $now.AddDays(-400) $now.AddDays(-1) 2048 @('d.com')
            }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":56,"method":"tools/call","params":{"name":"certificate_inventory_summary"}}'
            $r.result.isError | Should -BeFalse
            $out = $r.result.content[0].text | ConvertFrom-Json

            $out.byManagementType.Monitoring | Should -Be 7
            $out.validityReduction.currentlyValid | Should -Be 3
            $out.validityReduction.lifetimeOver200Days | Should -Be 1
            $out.validityReduction.lifetimeOver47Days | Should -Be 2
            $out.validityReduction.notAutomated | Should -Be 9
            $out.byLifetime.value | Should -Be @('47 days or less', '48-100 days', '201-398 days')
            $out.posture.rsaUnder2048Bits | Should -Be 1
            $out.posture.sha1Signed | Should -Be 5
            $out.posture.md5Signed | Should -Be 2
            $out.posture.wildcard | Should -Be 6
            $out.posture.selfSigned | Should -Be 8
            $out.posture.noSans | Should -Be 1
        }

        It 'Should map posture and management filters for CM find_certificates' {
            Mock -CommandName 'Find-CmCertificate' -ModuleName $ModuleName -MockWith { if ( $CountOnly ) { 0 } }

            $null = Invoke-TestRequest '{"jsonrpc":"2.0","id":57,"method":"tools/call","params":{"name":"find_certificates","arguments":{"management_type":["Monitoring","Unassigned"],"key_algorithm":"RSA","key_size_less_than":2048,"signature_algorithm":"sha1RSA","wildcard":false,"self_signed":true}}}'

            Should -Invoke -CommandName 'Find-CmCertificate' -ModuleName $ModuleName -ParameterFilter {
                $CountOnly -and $ManagementType.Count -eq 2 -and $KeyAlgorithm -eq 'RSA' -and $KeySizeLessThan -eq 2048 -and $SignatureAlgorithm -eq 'sha1RSA' -and
                $PesterBoundParameters.ContainsKey('IsWildcard') -and -not $IsWildcard -and $IsSelfSigned
            }
        }

        It 'Should find CM certificates by their issuer or a CA higher in the chain' {
            Mock -CommandName 'Find-CmCertificate' -ModuleName $ModuleName -MockWith {
                if ( $CountOnly ) { return 4 }
                $c = { param($name, $issuer) [pscustomobject]@{ Name = $name; Path = "\VED\Policy\$name"; Guid = [guid]::NewGuid(); X509 = [pscustomobject]@{ Issuer = $issuer; ValidTo = '2027-01-01T00:00:00Z' } } }
                & $c 'a' 'CN=EM DV TLS CA - G3B, O=eMudhra BV, C=NL'
                & $c 'b' 'CN=EM DV TLS CA - G3B, O=eMudhra BV, C=NL'
                & $c 'c' 'CN=Other Issuing CA'
                & $c 'd' 'CN=Unrelated CA'
                $self = & $c 'e' 'CN=device1'
                $self.X509 | Add-Member -NotePropertyName Subject -NotePropertyValue 'CN=device1'
                $self
            }
            Mock -CommandName 'Get-CmCertificate' -ModuleName $ModuleName -MockWith {
                [pscustomobject]@{ CertificateDetails = [pscustomobject]@{ Subject = 'CN=leaf'; Issuer = 'CN=x'; AIAKeyIdentifier = 'AA'; AIACAIssuerURL = @('http://ca.test/x.crt') } }
            }
            # Other Issuing CA chains to an emSign root, Unrelated CA doesn't
            $script:chainCall = 0
            Mock -CommandName 'Get-TrustMcpIssuerChain' -ModuleName $ModuleName -MockWith {
                $script:chainCall++
                $root = if ( $script:chainCall -eq 1 ) { 'CN=emSign Root TLS CA - G3, O=eMudhra Technologies Limited, C=IN' } else { 'CN=Some Root' }
                @{ chain = @(@{ subject = 'CN=issuing' }, @{ subject = $root }); complete = $true; warnings = @() }
            }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":58,"method":"tools/call","params":{"name":"find_certificates_by_ca","arguments":{"ca":"emudhra"}}}'
            $r.result.isError | Should -BeFalse
            $out = $r.result.content[0].text | ConvertFrom-Json
            $out.totalCertificates | Should -Be 3
            ($out.issuers | Where-Object matchedBy -eq 'issuer').count | Should -Be 2
            ($out.issuers | Where-Object matchedBy -eq 'chain').issuer | Should -Be 'CN=Other Issuing CA'
            ($out.issuers | Where-Object matchedBy -eq 'chain').chainAboveIssuer | Should -Match 'emSign Root'
            $out.issuersChecked | Should -Be 2
            $out.selfSignedIssuers | Should -Be 1
            $out.certificates.name | Should -Be @('a', 'b', 'c')
            Should -Invoke -CommandName 'Find-CmCertificate' -ModuleName $ModuleName -ParameterFilter { $OptionalField -contains 'Subject' }

            # without the chain only the issuer matches, and no chains are followed
            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":59,"method":"tools/call","params":{"name":"find_certificates_by_ca","arguments":{"ca":"emudhra","include_chain":false}}}'
            ($r.result.content[0].text | ConvertFrom-Json).totalCertificates | Should -Be 2
            Should -Invoke -CommandName 'Get-TrustMcpIssuerChain' -ModuleName $ModuleName -Times 2 -Exactly
        }

        It 'Should find SaaS certificates by their issuer or a CA in their chain' {
            Mock -CommandName 'Find-TrustCertificate' -ModuleName $ModuleName -MockWith {
                $c = { param($id, $issuer, $chain) [pscustomobject]@{ certificateId = $id; certificateName = $id; issuerDN = $issuer; issuerCertificateIds = $chain; validityEnd = '2027-01-01T00:00:00Z' } }
                & $c 'c1' 'cn=EM DV TLS CA - G3B,o=eMudhra BV,c=NL' @('ca1', 'root1')
                & $c 'c2' 'cn=Cross CA' @('ca2', 'root1')
                & $c 'c3' 'cn=Cross CA' @('ca2', 'root2')
                & $c 'c4' 'cn=Other CA' @('ca3')
            }
            # shared CA certificates can't be read by id, a certificate's details include its chain
            Mock -CommandName 'Get-TrustCertificate' -ModuleName $ModuleName -MockWith {
                $names = @{ ca1 = 'cn=EM DV TLS CA - G3B'; ca2 = 'cn=Cross CA'; ca3 = 'cn=Other CA'; root1 = 'cn=emSign Root TLS CA - G3,o=eMudhra Technologies Limited'; root2 = 'cn=Another Root' }
                $chains = @{ c1 = 'ca1', 'root1'; c2 = 'ca2', 'root1'; c3 = 'ca2', 'root2'; c4 = @('ca3') }
                # returned in a different order to the ids, to check the chain is put in order
                # Certificate is a string array
                [pscustomobject]@{ issuerCertificates = @($chains["$Certificate"] | Sort-Object -Descending | ForEach-Object { [pscustomobject]@{ id = $_; subjectDN = $names[$_] } }) }
            }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":60,"method":"tools/call","params":{"name":"find_certificates_by_ca","arguments":{"ca":"emudhra"}}}' -Platform CMS
            $r.result.isError | Should -BeFalse
            $out = $r.result.content[0].text | ConvertFrom-Json
            # c3 has the same issuer as c2 but a different chain, so only c2 matches
            $out.certificates.certificateId | Sort-Object | Should -Be @('c1', 'c2')
            ($out.issuers | Where-Object matchedBy -eq 'chain').count | Should -Be 1
            Should -Invoke -CommandName 'Find-TrustCertificate' -ModuleName $ModuleName -Times 1 -ParameterFilter { $Status -eq 'ACTIVE' }
            ($out.issuers | Where-Object matchedBy -eq 'chain').chainAboveIssuer | Should -Be 'cn=emSign Root TLS CA - G3,o=eMudhra Technologies Limited'
            # one certificate per distinct chain, c1 matched by issuer so its chain isn't needed
            Should -Invoke -CommandName 'Get-TrustCertificate' -ModuleName $ModuleName -Times 3 -Exactly
            $out.chainsChecked | Should -Be 3
        }

        It 'Should summarize certificate history most recent first' {
            Mock -CommandName 'Get-CmCertificate' -ModuleName $ModuleName -MockWith {
                $v = { param($s, $from) [pscustomobject]@{ VaultId = 1; CertificateDetails = [pscustomobject]@{ Serial = $s; Thumbprint = "t$s"; ValidFrom = $from; ValidTo = $from; Issuer = 'CN=CA'; KeyAlgorithm = 'RSA'; KeySize = 2048; SubjectAltNameDNS = @('a.com'); RevocationStatus = 'None'; PublicKeyHash = 'big' } } }
                [pscustomobject]@{ Name = 'c'; Path = '\VED\Policy\c'; PreviousVersions = @((& $v 'old' '2024-01-01T00:00:00Z'), (& $v 'new' '2025-01-01T00:00:00Z')) }
            }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":44,"method":"tools/call","params":{"name":"get_certificate","arguments":{"id":"\\VED\\Policy\\c","include_history":true}}}'
            $r.result.isError | Should -BeFalse
            $r.result.content[0].text | Should -Not -Match 'PublicKeyHash'
            $out = $r.result.content[0].text | ConvertFrom-Json
            $out.previousVersionCount | Should -Be 2
            $out.previousVersions[0].serial | Should -Be 'new'
            $out.previousVersions[0].key | Should -Be 'RSA 2048'
            Should -Invoke -CommandName 'Get-CmCertificate' -ModuleName $ModuleName -Times 1 -ParameterFilter { $IncludePreviousVersions }

            $null = Invoke-TestRequest '{"jsonrpc":"2.0","id":45,"method":"tools/call","params":{"name":"get_certificate","arguments":{"id":"\\VED\\Policy\\c"}}}'
            Should -Invoke -CommandName 'Get-CmCertificate' -ModuleName $ModuleName -Times 1 -ParameterFilter { -not $IncludePreviousVersions }
        }

        It 'Should summarize the certificate inventory' {
            Mock -CommandName 'Find-CmCertificate' -ModuleName $ModuleName -MockWith {
                if ( $CountOnly ) {
                    if ( $InError ) { return 1 }
                    if ( $PendingWorkflow ) { return 0 }
                    return 4
                }
                $c = { param($folder, $validTo, $issuer) [pscustomobject]@{ Name = 'x'; TypeName = 'X509 Server Certificate'; ParentPath = $folder; X509 = [pscustomobject]@{ ValidTo = $validTo; Issuer = $issuer; KeyAlgorithm = if ( $issuer ) { 'RSA' }; KeySize = if ( $issuer ) { 2048 } } } }
                & $c '\VED\Policy\a' (Get-Date).AddDays(-5) 'CN=CA1'
                & $c '\VED\Policy\a' (Get-Date).AddDays(10) 'CN=CA1'
                & $c '\VED\Policy\b' (Get-Date).AddDays(400) 'CN=CA2'
                & $c '\VED\Policy\b' $null $null
            }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":46,"method":"tools/call","params":{"name":"certificate_inventory_summary","arguments":{"path":"\\VED\\Policy","top":1}}}'
            $r.result.isError | Should -BeFalse
            $out = $r.result.content[0].text | ConvertFrom-Json
            $out.total | Should -Be 4
            $out.truncated | Should -BeFalse
            $out.inError | Should -Be 1
            $out.expired | Should -Be 1
            $out.neverIssued | Should -Be 1
            $out.byIssuer[0].value | Should -Be 'CN=CA1'
            $out.byIssuer[0].count | Should -Be 2
            $out.byIssuer[1].count | Should -Be 1
            $out.byKey[0].value | Should -Be 'RSA 2048'
            # expiry is in date order and never folded into other
            $out.byExpiry.value | Should -Be @('expired', '0-30 days', 'over 1 year', 'never issued')
            $r.result.content[0].text | Should -Not -Match '\.0[,}]'
            Should -Invoke -CommandName 'Find-CmCertificate' -ModuleName $ModuleName -Times 1 -ParameterFilter { $OptionalField -contains 'Issuer' -and $Recursive -and $Path -eq '\VED\Policy' }
        }

        Context 'get_certificate_chain' {

            BeforeAll {
                # a root and intermediate with the key id and AIA extensions real CAs use, the leaf is only details from Certificate Manager
                $script:testChain = InModuleScope $ModuleName {
                    $X = 'System.Security.Cryptography.X509Certificates'
                    $der = { param([byte] $Tag, [byte[]] $Content) , ([byte[]](@($Tag, $Content.Length) + $Content)) }
                    $hexToBytes = { param([string] $Hex) , ([byte[]] -split ($Hex -replace '..', '0x$& ')) }
                    $newCa = {
                        param($Subject, $Key, $Issuer, $IssuerKey, $AiaUrl)
                        $req = New-Object "$X.CertificateRequest" $Subject, $Key, 'SHA256', ([System.Security.Cryptography.RSASignaturePadding]::Pkcs1)
                        $req.CertificateExtensions.Add((New-Object "$X.X509BasicConstraintsExtension" $true, $false, 0, $true))
                        $ski = New-Object "$X.X509SubjectKeyIdentifierExtension" $req.PublicKey, $false
                        $req.CertificateExtensions.Add($ski)
                        if ( -not $Issuer ) {
                            return $req.CreateSelfSigned([datetimeoffset]::UtcNow.AddDays(-1), [datetimeoffset]::UtcNow.AddYears(5))
                        }
                        $issuerSki = ($Issuer.Extensions | Where-Object { $_ -is [System.Security.Cryptography.X509Certificates.X509SubjectKeyIdentifierExtension] }).SubjectKeyIdentifier
                        $aki = & $der 0x30 (& $der 0x80 (& $hexToBytes $issuerSki))
                        $req.CertificateExtensions.Add((New-Object "$X.X509Extension" '2.5.29.35', $aki, $false))
                        $caIssuers = [byte[]](0x06, 0x08, 0x2B, 0x06, 0x01, 0x05, 0x05, 0x07, 0x30, 0x02) + (& $der 0x86 ([System.Text.Encoding]::ASCII.GetBytes($AiaUrl)))
                        $aia = & $der 0x30 (& $der 0x30 $caIssuers)
                        $req.CertificateExtensions.Add((New-Object "$X.X509Extension" '1.3.6.1.5.5.7.1.1', $aia, $false))
                        $signer = [System.Security.Cryptography.X509Certificates.X509SignatureGenerator]::CreateForRSA($IssuerKey, [System.Security.Cryptography.RSASignaturePadding]::Pkcs1)
                        $req.Create($Issuer.SubjectName, $signer, [datetimeoffset]::UtcNow.AddDays(-1), [datetimeoffset]::UtcNow.AddYears(2), [byte[]](5, 6, 7, 8))
                    }
                    $rootKey = [System.Security.Cryptography.RSA]::Create(2048)
                    $root = & $newCa 'CN=Test Root' $rootKey
                    $intKey = [System.Security.Cryptography.RSA]::Create(2048)
                    $int = & $newCa 'CN=Test Issuing CA' $intKey $root $rootKey 'http://ca.test/root.crt'
                    @{
                        Root  = $root
                        Int   = $int
                        IntId = ($int.Extensions | Where-Object { $_ -is [System.Security.Cryptography.X509Certificates.X509SubjectKeyIdentifierExtension] }).SubjectKeyIdentifier
                    }
                }
                $script:leafDetails = {
                    param([string] $Thumbprint = 'AABB')
                    [pscustomobject]@{
                        Path               = '\VED\Policy\www.company.com'
                        CertificateDetails = [pscustomobject]@{
                            Subject = 'CN=www.company.com'; Issuer = 'CN=Test Issuing CA'; Serial = '01'; Thumbprint = $Thumbprint
                            ValidFrom = '2026-01-01T00:00:00Z'; ValidTo = '2027-01-01T00:00:00Z'; KeyAlgorithm = 'ECC'; KeySize = 256; SignatureAlgorithm = 'sha256RSA'
                            AIAKeyIdentifier = $script:testChain.IntId.ToLower(); AIACAIssuerURL = @('http://ca.test/int.crt')
                        }
                    }
                }
            }

            It 'Should follow AIA urls to the root without retrieving the certificate' {
                Mock -CommandName 'Get-CmCertificate' -ModuleName $ModuleName -MockWith { & $script:leafDetails }
                Mock -CommandName 'Get-TrustMcpAiaCertificate' -ModuleName $ModuleName -MockWith {
                    if ( $Uri -like '*int.crt' ) { $script:testChain.Int } else { $script:testChain.Root }
                }
                Mock -CommandName 'Export-CmCertificate' -ModuleName $ModuleName -MockWith {}

                $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":34,"method":"tools/call","params":{"name":"get_certificate_chain","arguments":{"id":"\\VED\\Policy\\www.company.com"}}}'

                $r.result.isError | Should -BeFalse
                $out = $r.result.content[0].text | ConvertFrom-Json
                $out.total | Should -Be 3
                $out.complete | Should -BeTrue
                @($out.warnings).Count | Should -Be 0
                $out.chain[0].subject | Should -Be 'CN=www.company.com'
                $out.chain[0].source | Should -Be 'Certificate Manager'
                $out.chain[1].subject | Should -Be 'CN=Test Issuing CA'
                $out.chain[1].matchesKeyId | Should -BeTrue
                $out.chain[1].isCA | Should -BeTrue
                $out.chain[1].thumbprintSha256 | Should -Match '^[0-9A-F]{64}$'
                $out.chain[1].source | Should -Be 'http://ca.test/int.crt'
                $out.chain[2].subject | Should -Be 'CN=Test Root'
                $out.chain[2].selfSigned | Should -BeTrue
                $out.chain[2].matchesKeyId | Should -BeTrue
                # the root url comes from the intermediate's own AIA extension
                Should -Invoke -CommandName 'Get-TrustMcpAiaCertificate' -ModuleName $ModuleName -Times 1 -ParameterFilter { $Uri -eq 'http://ca.test/root.crt' }
                Should -Invoke -CommandName 'Export-CmCertificate' -ModuleName $ModuleName -Times 0
            }

            It 'Should return a partial chain with a warning when an issuer cannot be downloaded' {
                Mock -CommandName 'Get-CmCertificate' -ModuleName $ModuleName -MockWith { & $script:leafDetails }
                Mock -CommandName 'Get-TrustMcpAiaCertificate' -ModuleName $ModuleName -MockWith {
                    if ( $Uri -like '*int.crt' ) { $script:testChain.Int } else { throw 'connection refused' }
                }

                $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":35,"method":"tools/call","params":{"name":"get_certificate_chain","arguments":{"id":"\\VED\\Policy\\www.company.com"}}}'

                $r.result.isError | Should -BeFalse
                $out = $r.result.content[0].text | ConvertFrom-Json
                $out.total | Should -Be 2
                $out.complete | Should -BeFalse
                $out.warnings | Should -Match "Unable to download 'http://ca.test/root.crt': connection refused"
            }

            It 'Should fail for a certificate which has not been issued' {
                Mock -CommandName 'Get-CmCertificate' -ModuleName $ModuleName -MockWith { & $script:leafDetails -Thumbprint '' }

                $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":36,"method":"tools/call","params":{"name":"get_certificate_chain","arguments":{"id":"\\VED\\Policy\\www.company.com"}}}'

                $r.result.isError | Should -BeTrue
                $r.result.content[0].text | Should -Match 'has not been issued'
            }
        }

        It 'Should find objects by attribute with a contains match' {
            Mock -CommandName 'Find-CmObject' -ModuleName $ModuleName -MockWith {
                [pscustomobject]@{ Name = 'app1'; TypeName = 'Adaptable App'; Path = '\VED\Policy\d\app1'; Guid = [guid]::NewGuid() }
            }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":35,"method":"tools/call","params":{"name":"find_objects_by_attribute","arguments":{"attribute":"PowerShell Script","value":"MyDriver","class":"Adaptable App"}}}'

            $r.result.isError | Should -BeFalse
            ($r.result.content[0].text | ConvertFrom-Json).total | Should -Be 1
            Should -Invoke -CommandName 'Find-CmObject' -ModuleName $ModuleName -Times 1 -ParameterFilter { $Attribute -eq 'PowerShell Script' -and $Pattern -eq '*MyDriver*' -and $Class -contains 'Adaptable App' }
        }

        It 'Should use the exact value for custom fields' {
            Mock -CommandName 'Find-CmObject' -ModuleName $ModuleName -MockWith {}
            $client = New-TestClient 'CM'
            $client.PlatformData.CustomField = @([pscustomobject]@{ Label = 'Environment'; Guid = '{2f04f078-046b-4ccb-9784-39e5127b588a}' })

            InModuleScope $ModuleName -Parameters @{ Client = $client } {
                $tools = @(Get-TrustMcpTool -Platform CM)
                $null = Invoke-TrustMcpRequest -Message ('{"jsonrpc":"2.0","id":36,"method":"tools/call","params":{"name":"find_objects_by_attribute","arguments":{"attribute":"Environment","value":"Production"}}}' | ConvertFrom-Json) -Tool $tools -TrustClient $Client
            }

            Should -Invoke -CommandName 'Find-CmObject' -ModuleName $ModuleName -Times 1 -ParameterFilter { $Pattern -eq 'Production' }
        }

        It 'Should list class attributes and custom fields' {
            Mock -CommandName 'Get-CmClassAttribute' -ModuleName $ModuleName -MockWith {
                [pscustomobject]@{ Name = 'Host'; Class = 'Device' }
                [pscustomobject]@{ Name = 'Contact'; Class = 'Top' }
                [pscustomobject]@{ Name = '{g}'; Class = 'Device' }
            }
            Mock -CommandName 'Get-CmCustomField' -ModuleName $ModuleName -MockWith {
                [pscustomobject]@{ Items = @([pscustomobject]@{ Label = 'Owner Team'; Guid = '{g}'; Type = 2; Mandatory = $true; Policyable = $false; AllowedValues = @('a', 'b'); DefaultValues = @() }) }
            }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":37,"method":"tools/call","params":{"name":"list_class_attributes","arguments":{"class":"Device"}}}'

            $r.result.isError | Should -BeFalse
            $out = $r.result.content[0].text | ConvertFrom-Json
            $out.attributes.name | Should -Be @('Contact', 'Host')
            $out.attributes[0].definedBy | Should -Be 'Top'
            $out.customFields[0].label | Should -Be 'Owner Team'
            $out.customFields[0].allowedValues.Count | Should -Be 2
        }

        It 'Should return engines with their folders even if the service status fails' {
            Mock -CommandName 'Get-CmSystemStatus' -ModuleName $ModuleName -MockWith { throw 'boom' }
            Mock -CommandName 'Invoke-TrustRestMethod' -ModuleName $ModuleName -ParameterFilter { $UriLeaf -eq 'ProcessingEngines/' } -MockWith {
                [pscustomobject]@{ Engines = @(
                        [pscustomobject]@{ EngineName = 'e1'; EngineDN = '\VED\Engines\e1'; EngineGuid = '{11111111-1111-1111-1111-111111111111}' }
                        [pscustomobject]@{ EngineName = 'e2'; EngineDN = '\VED\Engines\e2'; EngineGuid = '22222222-2222-2222-2222-222222222222' }
                    )
                }
            }
            Mock -CommandName 'Invoke-TrustRestMethod' -ModuleName $ModuleName -ParameterFilter { $UriLeaf -like 'ProcessingEngines/Engine/*' } -MockWith {
                if ( $UriLeaf -like '*11111111*' ) {
                    # the engine itself is returned as a folder
                    [pscustomobject]@{ Folders = @(
                            [pscustomobject]@{ FolderDN = '\VED\Engines\e1'; FolderGuid = '{11111111-1111-1111-1111-111111111111}' }
                            [pscustomobject]@{ FolderDN = '\VED\Policy\a'; FolderGuid = '{aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa}' }
                        )
                    }
                }
            }
            Mock -CommandName 'Get-CmEngineFolder' -ModuleName $ModuleName -MockWith {}

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":38,"method":"tools/call","params":{"name":"get_system_status"}}'

            $r.result.isError | Should -BeFalse
            $out = $r.result.content[0].text | ConvertFrom-Json
            $out.services | Should -Match 'boom'
            $out.engines.Count | Should -Be 2
            $out.engines[0].name | Should -Be 'e1'
            $out.engines[0].folders | Should -Be '\VED\Policy\a'
            @($out.engines[1].folders).Count | Should -Be 0
            # braces are added to a guid without them
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -ModuleName $ModuleName -Times 1 -ParameterFilter { $UriLeaf -eq 'ProcessingEngines/Engine/{22222222-2222-2222-2222-222222222222}' }
            # engines by folder needs configuration:manage
            Should -Invoke -CommandName 'Get-CmEngineFolder' -ModuleName $ModuleName -Times 0
        }

        It 'Should list allowed permissions by name, including private key permissions' {
            Mock -CommandName 'Get-CmPermission' -ModuleName $ModuleName -MockWith {
                $perm = [pscustomobject]@{ IsViewAllowed = $true; IsReadAllowed = $true; IsWriteAllowed = $false; IsPrivateKeyReadAllowed = $true; IsPrivateKeyWriteAllowed = $false }
                [pscustomobject]@{ Path = '\VED\Policy\a'; IdentityId = 'local:{u}'; IdentityName = 'user'; IdentityPath = 'CN=user'; EffectivePermissions = $perm; ExplicitPermissions = $perm; ImplicitPermissions = [pscustomobject]@{ IsViewAllowed = $true } }
            }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":39,"method":"tools/call","params":{"name":"get_permissions","arguments":{"path":"\\VED\\Policy\\a"}}}'

            $r.result.isError | Should -BeFalse
            $r.result.content[0].text | Should -Not -Match 'redacted'
            $out = $r.result.content[0].text | ConvertFrom-Json
            $out.permissions[0].effective | Should -Be @('view', 'read', 'privateKeyRead')
            Should -Invoke -CommandName 'Get-CmPermission' -ModuleName $ModuleName -Times 1 -ParameterFilter { $Path -eq '\VED\Policy\a' -and -not $Explicit }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":40,"method":"tools/call","params":{"name":"get_permissions","arguments":{"path":"\\VED\\Policy\\a","explicit":true}}}'
            $out = $r.result.content[0].text | ConvertFrom-Json
            $out.permissions[0].explicit | Should -Contain 'privateKeyRead'
            # a single permission must still be an array
            $r.result.content[0].text | Should -Match '"inherited":\["view"\]'
        }

        It 'Should filter the policy tree by one or more classes' {
            Mock -CommandName 'Find-CmObject' -ModuleName $ModuleName -MockWith {
                [pscustomobject]@{ Name = 'c1'; TypeName = 'X509 Server Certificate'; Path = '\VED\Policy\c1'; Guid = [guid]::NewGuid() }
            }

            $null = Invoke-TestRequest '{"jsonrpc":"2.0","id":32,"method":"tools/call","params":{"name":"browse_policy_tree","arguments":{"class":["X509 Server Certificate","X509 Device Certificate"]}}}'
            Should -Invoke -CommandName 'Find-CmObject' -ModuleName $ModuleName -Times 1 -ParameterFilter { $Class.Count -eq 2 -and $Class -contains 'X509 Device Certificate' }

            $null = Invoke-TestRequest '{"jsonrpc":"2.0","id":33,"method":"tools/call","params":{"name":"browse_policy_tree","arguments":{"class":"Policy"}}}'
            Should -Invoke -CommandName 'Find-CmObject' -ModuleName $ModuleName -Times 1 -ParameterFilter { $Class.Count -eq 1 -and $Class[0] -eq 'Policy' }
        }

        It 'Should search policy folders recursively and only return folders with a value' {
            Mock -CommandName 'Find-CmObject' -ModuleName $ModuleName -MockWith {
                '\VED\Policy\a', '\VED\Policy\b' | ForEach-Object { [pscustomobject]@{ Path = $_ } }
            }
            Mock -CommandName 'Get-CmAttribute' -ModuleName $ModuleName -MockWith {
                $value = if ( $Path -eq '\VED\Policy\b' ) { '\VED\Policy\Administration\CAs\DigiCert' } else { $null }
                [pscustomobject]@{
                    Path      = $Path
                    ClassName = $Class
                    Attribute = @([pscustomobject]@{ Name = 'Certificate Authority'; Value = $value; PolicyPath = $Path; Locked = $false })
                }
            }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":12,"method":"tools/call","params":{"name":"get_attributes","arguments":{"path":"\\VED\\Policy","class":"X509 Certificate","attributes":["Certificate Authority"],"recursive":true}}}'

            $r.result.isError | Should -BeFalse
            $out = $r.result.content[0].text | ConvertFrom-Json
            $out.totalFolders | Should -Be 3
            $out.truncated | Should -BeFalse
            @($out.policies).Count | Should -Be 1
            $out.policies[0].path | Should -Be '\VED\Policy\b'
            $out.policies[0].className | Should -Be 'X509 Certificate'
            $out.policies[0].attributes.'Certificate Authority'.value | Should -BeLike '*DigiCert'

            Should -Invoke -CommandName 'Get-CmAttribute' -ModuleName $ModuleName -Times 3 -ParameterFilter { $Class -eq 'X509 Certificate' -and $Attribute -contains 'Certificate Authority' }
        }

        It 'Should list CA templates with adaptable driver scripts' {
            Mock -CommandName 'Find-CmObject' -ModuleName $ModuleName -MockWith {
                [pscustomobject]@{ Name = 'sub'; TypeName = 'Policy'; Path = '\VED\Policy\Administration\CAs\sub'; Guid = [guid]::NewGuid() }
                [pscustomobject]@{ Name = 'DigiCert CC'; TypeName = 'Adaptable CA'; Path = '\VED\Policy\Administration\CAs\DigiCert CC'; Guid = [guid]::NewGuid() }
                [pscustomobject]@{ Name = 'msca'; TypeName = 'Microsoft CA'; Path = '\VED\Policy\Administration\CAs\msca'; Guid = [guid]::NewGuid() }
            }
            Mock -CommandName 'Get-CmAttribute' -ModuleName $ModuleName -MockWith {
                [pscustomobject]@{ Path = $Path; 'Interoperability Script' = 'DigiCert-CertCentral' }
            }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":20,"method":"tools/call","params":{"name":"list_ca_templates"}}'

            $r.result.isError | Should -BeFalse
            $out = $r.result.content[0].text | ConvertFrom-Json
            $out.total | Should -Be 2
            ($out.caTemplates | Where-Object name -eq 'DigiCert CC').driverScript | Should -Be 'DigiCert-CertCentral'
            ($out.caTemplates | Where-Object name -eq 'msca').PSObject.Properties.Name | Should -Not -Contain 'driverScript'
            Should -Invoke -CommandName 'Find-CmObject' -ModuleName $ModuleName -Times 1 -ParameterFilter { $Path -eq '\VED\Policy\Administration\CAs' -and $Recursive }
            Should -Invoke -CommandName 'Get-CmAttribute' -ModuleName $ModuleName -Times 1
        }

        It 'Should find workflow tickets for pending certificates in a folder' {
            Mock -CommandName 'Get-CmObject' -ModuleName $ModuleName -MockWith { [pscustomobject]@{ Path = $Path[0]; TypeName = 'Policy' } }
            Mock -CommandName 'Find-CmCertificate' -ModuleName $ModuleName -MockWith { [pscustomobject]@{ Path = '\VED\Policy\certs\c1' } }
            Mock -CommandName 'Get-CmWorkflowTicket' -ModuleName $ModuleName -MockWith { [pscustomobject]@{ Status = 'Pending'; Approvers = @('local:{abc}'); Result = 1 } }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":21,"method":"tools/call","params":{"name":"find_workflow_tickets","arguments":{"path":"\\VED\\Policy\\certs"}}}'

            $r.result.isError | Should -BeFalse
            $out = @($r.result.content[0].text | ConvertFrom-Json)
            $out[0].CertificatePath | Should -Be '\VED\Policy\certs\c1'
            $out[0].Status | Should -Be 'Pending'
            $out[0].PSObject.Properties.Name | Should -Not -Contain 'Result'
            Should -Invoke -CommandName 'Find-CmCertificate' -ModuleName $ModuleName -Times 1 -ParameterFilter { $PendingWorkflow -and $Recursive -and $Path -eq '\VED\Policy\certs' }
        }

        It 'Should get certificate consumers and their devices' {
            Mock -CommandName 'Get-CmAttribute' -ModuleName $ModuleName -MockWith { @('\VED\Policy\dev1\app1') }
            Mock -CommandName 'Get-CmObject' -ModuleName $ModuleName -MockWith {
                [pscustomobject]@{ Path = '\VED\Policy\dev1\app1'; TypeName = 'F5 LTM Advanced'; ParentPath = '\VED\Policy\dev1' }
            }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":22,"method":"tools/call","params":{"name":"get_certificate_consumers","arguments":{"id":"\\VED\\Policy\\c1"}}}'

            $r.result.isError | Should -BeFalse
            $out = $r.result.content[0].text | ConvertFrom-Json
            $out.total | Should -Be 1
            $out.consumers[0].device | Should -Be '\VED\Policy\dev1'
            $out.consumers[0].typeName | Should -Be 'F5 LTM Advanced'
            Should -Invoke -CommandName 'Get-CmAttribute' -ModuleName $ModuleName -Times 1 -ParameterFilter { $Attribute -contains 'Consumers' -and $AsValue }
        }

        It 'Should require id or name for CM get_identity' {
            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":23,"method":"tools/call","params":{"name":"get_identity","arguments":{}}}'
            $r.result.isError | Should -BeTrue
        }

        It 'Should fall back to a team for SaaS get_identity' {
            Mock -CommandName 'Get-CmsUser' -ModuleName $ModuleName -MockWith { throw 'not found' }
            Mock -CommandName 'Get-CmsTeam' -ModuleName $ModuleName -MockWith { [pscustomobject]@{ teamId = 't1'; name = 'PKI' } }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":24,"method":"tools/call","params":{"name":"get_identity","arguments":{"id":"PKI"}}}' -Platform CMS

            $r.result.isError | Should -BeFalse
            ($r.result.content[0].text | ConvertFrom-Json).teamId | Should -Be 't1'
        }

        It 'Should map find_certificate_requests arguments and drop the csr' {
            Mock -CommandName 'Find-TrustCertificateRequest' -ModuleName $ModuleName -MockWith {
                [pscustomobject]@{ id = 'r1'; status = 'FAILED'; certificateSigningRequest = '-----BEGIN CERTIFICATE REQUEST-----' }
            }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":25,"method":"tools/call","params":{"name":"find_certificate_requests","arguments":{"status":["FAILED","REJECTED"],"since_hours":24}}}' -Platform CMS

            $r.result.isError | Should -BeFalse
            $r.result.content[0].text | Should -Not -Match 'BEGIN CERTIFICATE REQUEST'
            ($r.result.content[0].text | ConvertFrom-Json).status | Should -Be 'FAILED'
            Should -Invoke -CommandName 'Find-TrustCertificateRequest' -ModuleName $ModuleName -Times 1 -ParameterFilter {
                $Status -contains 'FAILED' -and $Status -contains 'REJECTED' -and $CreateDateFrom -gt (Get-Date).AddHours(-25) -and $Order.creationDate -eq 'desc'
            }
        }

        It 'Should list applications' {
            Mock -CommandName 'Get-CmsApplication' -ModuleName $ModuleName -MockWith {
                1..3 | ForEach-Object { [pscustomobject]@{ applicationId = "a$_"; name = "app$_" } }
            }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":26,"method":"tools/call","params":{"name":"list_applications","arguments":{"first":2}}}' -Platform NGTS

            $out = $r.result.content[0].text | ConvertFrom-Json
            $out.total | Should -Be 3
            @($out.applications).Count | Should -Be 2
            Should -Invoke -CommandName 'Get-CmsApplication' -ModuleName $ModuleName -Times 1 -ParameterFilter { $All -and -not $IncludeConfig }
        }

        It 'Should list vsatellites with workers and without encryption keys' {
            Mock -CommandName 'Get-TrustSatellite' -ModuleName $ModuleName -MockWith {
                [pscustomobject]@{ vsatelliteId = 'v1'; name = 'vsat1'; status = 'ACTIVE'; encryptionKey = 'bigpublickey'; encryptionKeyId = 'k1' }
            }
            Mock -CommandName 'Get-TrustSatelliteWorker' -ModuleName $ModuleName -MockWith {
                [pscustomobject]@{ vsatelliteWorkerId = 'w1'; vsatelliteId = 'v1'; status = 'ONLINE'; pairingCode = 'pair-secret-1'; hiddenPairingCode = '****-1' }
            }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":27,"method":"tools/call","params":{"name":"list_vsatellites","arguments":{"include_workers":true}}}' -Platform CMS

            $r.result.isError | Should -BeFalse
            $r.result.content[0].text | Should -Not -Match 'bigpublickey'
            $r.result.content[0].text | Should -Not -Match 'pair-secret-1'
            $out = $r.result.content[0].text | ConvertFrom-Json
            $out.total | Should -Be 1
            $out.vsatellites[0].status | Should -Be 'ACTIVE'
            $out.vsatellites[0].workers[0].status | Should -Be 'ONLINE'
            Should -Invoke -CommandName 'Get-TrustSatelliteWorker' -ModuleName $ModuleName -Times 1 -ParameterFilter { $VSatellite -eq 'v1' }
        }

        It 'Should list connectors classified as global or custom without manifests' {
            Mock -CommandName 'Get-TrustConnector' -ModuleName $ModuleName -MockWith {
                [pscustomobject]@{ connectorId = 'c1'; name = 'F5 BIG-IP LTM'; connectorType = 'MACHINE'; maintainer = ''; manifest = @{ hooks = 'bighooks'; deployment = @{ executionTarget = 'vsat'; image = 'registry.venafi.cloud/public/venafi-vsatellite/f5@sha256:1' } } }
                [pscustomobject]@{ connectorId = 'c2'; name = 'GoDaddy CA Connector'; connectorType = 'CA'; maintainer = 'Extensions Team'; manifest = @{ deployment = @{ image = 'registry.venafi.cloud/public/godaddy' } } }
                [pscustomobject]@{ connectorId = 'c3'; name = 'Microsoft IIS (Debuggable)'; connectorType = 'MACHINE'; maintainer = $null; manifest = @{ deployment = @{ image = 'venafi.jfrog.io/dev/iis' } } }
            }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":28,"method":"tools/call","params":{"name":"list_connectors"}}' -Platform CMS

            $r.result.isError | Should -BeFalse
            $r.result.content[0].text | Should -Not -Match 'bighooks'
            $out = $r.result.content[0].text | ConvertFrom-Json
            $out.total | Should -Be 3
            ($out.connectors | Where-Object connectorId -eq 'c1').source | Should -Be 'GLOBAL'
            ($out.connectors | Where-Object connectorId -eq 'c1').executionTarget | Should -Be 'vsat'
            ($out.connectors | Where-Object connectorId -eq 'c2').source | Should -Be 'CUSTOM'
            ($out.connectors | Where-Object connectorId -eq 'c3').source | Should -Be 'CUSTOM'
            Should -Invoke -CommandName 'Get-TrustConnector' -ModuleName $ModuleName -Times 1 -ParameterFilter { $All }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":29,"method":"tools/call","params":{"name":"list_connectors","arguments":{"source":"CUSTOM","connector":"iis"}}}' -Platform CMS
            $out = $r.result.content[0].text | ConvertFrom-Json
            $out.total | Should -Be 1
            $out.connectors[0].connectorId | Should -Be 'c3'
        }

        It 'Should find machine identities with machine names and without secrets' {
            Mock -CommandName 'Find-TrustMachineIdentity' -ModuleName $ModuleName -MockWith {
                [pscustomobject]@{ machineIdentityId = 'mi1'; companyId = 'co'; machineId = 'm1'; certificateId = 'c1'; certificateName = 'www.company.com'; status = 'INSTALLED'; binding = @{ virtualServerName = 'vs1'; port = 443 }; keystore = @{ type = 'PKCS12'; password = 'ks-secret' } }
                [pscustomobject]@{ machineIdentityId = 'mi2'; companyId = 'co'; machineId = 'm1'; certificateId = 'c1'; certificateName = 'www.company.com'; status = 'DISCOVERED' }
            }
            Mock -CommandName 'Get-TrustData' -ModuleName $ModuleName -MockWith { 'f5-prod-01' }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":51,"method":"tools/call","params":{"name":"find_machine_identities","arguments":{"certificate":"www.company.com","status":"INSTALLED"}}}' -Platform CMS

            $r.result.isError | Should -BeFalse
            $r.result.content[0].text | Should -Not -Match 'ks-secret'
            $out = $r.result.content[0].text | ConvertFrom-Json
            $out.returned | Should -Be 2
            $out.identities[0].machineIdentityId | Should -Be 'mi1'
            $out.identities[0].certificateName | Should -Be 'www.company.com'
            $out.identities[0].machineName | Should -Be 'f5-prod-01'
            $out.identities[0].binding.virtualServerName | Should -Be 'vs1'
            $out.identities[0].PSObject.Properties.Name | Should -Not -Contain 'companyId'
            Should -Invoke -CommandName 'Find-TrustMachineIdentity' -ModuleName $ModuleName -Times 1 -ParameterFilter { $Certificate -eq 'www.company.com' -and $Status -eq 'INSTALLED' }
            # one lookup per machine, not per identity
            Should -Invoke -CommandName 'Get-TrustData' -ModuleName $ModuleName -Times 1 -ParameterFilter { $InputObject -eq 'm1' -and $Name }
        }

        It 'Should list certificate authorities' {
            Mock -CommandName 'Get-TrustCertificateAuthority' -ModuleName $ModuleName -MockWith {
                [pscustomobject]@{ certificateAuthorityId = 'ca1'; name = 'DigiCert'; type = 'DIGICERT'; companyId = 'co'; status = 'ACTIVE'; productOptions = @(@{ productName = 'ssl_plus' }) }
            }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":52,"method":"tools/call","params":{"name":"list_certificate_authorities"}}' -Platform CMS
            $out = $r.result.content[0].text | ConvertFrom-Json
            $out.total | Should -Be 1
            $out.certificateAuthorities[0].name | Should -Be 'DigiCert'
            $out.certificateAuthorities[0].PSObject.Properties.Name | Should -Not -Contain 'companyId'
            Should -Invoke -CommandName 'Get-TrustCertificateAuthority' -ModuleName $ModuleName -Times 1 -ParameterFilter { $All }

            $null = Invoke-TestRequest '{"jsonrpc":"2.0","id":53,"method":"tools/call","params":{"name":"list_certificate_authorities","arguments":{"certificate_authority":"DigiCert"}}}' -Platform CMS
            Should -Invoke -CommandName 'Get-TrustCertificateAuthority' -ModuleName $ModuleName -Times 1 -ParameterFilter { $CertificateAuthority -eq 'DigiCert' }
        }

        It 'Should list issuing templates, optionally for one CA' {
            Mock -CommandName 'Get-TrustIssuingTemplate' -ModuleName $ModuleName -MockWith {
                [pscustomobject]@{ issuingTemplateId = 't1'; name = 'Default'; companyId = 'co'; certificateAuthority = 'BUILTIN'; keyTypes = @(@{ keyType = 'RSA'; keyLengths = @(2048) }) }
            }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":54,"method":"tools/call","params":{"name":"list_issuing_templates","arguments":{"certificate_authority":"ca1"}}}' -Platform NGTS
            $r.result.isError | Should -BeFalse
            $out = $r.result.content[0].text | ConvertFrom-Json
            $out.issuingTemplates[0].name | Should -Be 'Default'
            Should -Invoke -CommandName 'Get-TrustIssuingTemplate' -ModuleName $ModuleName -Times 1 -ParameterFilter { $All -and $CertificateAuthority -eq 'ca1' }

            $null = Invoke-TestRequest '{"jsonrpc":"2.0","id":55,"method":"tools/call","params":{"name":"list_issuing_templates","arguments":{"issuing_template":"Default"}}}' -Platform CMS
            Should -Invoke -CommandName 'Get-TrustIssuingTemplate' -ModuleName $ModuleName -Times 1 -ParameterFilter { $IssuingTemplate -eq 'Default' }
        }

        It 'Should bucket SaaS expiry summary' {
            Mock -CommandName 'Find-TrustCertificate' -ModuleName $ModuleName -MockWith {
                -1, 3, 20, 60 | ForEach-Object { [pscustomobject]@{ validityEnd = (Get-Date).AddDays($_) } }
            }

            $r = Invoke-TestRequest '{"jsonrpc":"2.0","id":9,"method":"tools/call","params":{"name":"certificate_expiry_summary"}}' -Platform NGTS
            $out = $r.result.content[0].text | ConvertFrom-Json

            $out.expired | Should -Be 1
            $out.within7Days | Should -Be 1
            $out.within30Days | Should -Be 2
            $out.within90Days | Should -Be 3
            $out.truncated | Should -BeFalse
        }
    }
}

Describe 'ConvertTo-TrustMcpSafeObject' -Tags 'Unit' {

    It 'Should redact secrets and convert types' {
        $out = InModuleScope $ModuleName {
            $obj = [pscustomobject]@{
                Name               = 'x'
                PrivateKeyPassword = 'oops'
                connectionDetails  = @{ username = 'u' }
                Nested             = @{ apiKey = 'k'; When = [datetime]::new(2026, 1, 1, 0, 0, 0, [System.DateTimeKind]::Utc) }
                Stage              = [CmCertificateStage]::PostCSR
                Cred               = [pscredential]::new('u', ('p' | ConvertTo-SecureString -AsPlainText -Force))
            }
            ConvertTo-TrustMcpSafeObject -InputObject $obj
        }

        $out.Name | Should -Be 'x'
        $out.PrivateKeyPassword | Should -Be '[redacted]'
        $out.connectionDetails | Should -Be '[redacted]'
        $out.Nested.apiKey | Should -Be '[redacted]'
        $out.Nested.When | Should -Be '2026-01-01T00:00:00.0000000Z'
        $out.Stage | Should -Be 'PostCSR'
        $out.Cred | Should -Be '[redacted]'
    }

    It 'Should only redact names which hold a secret' {
        $out = InModuleScope $ModuleName {
            $obj = [ordered]@{
                'OAuth Token Application Id'             = 'VenafiPS'
                'OAuth Token Scope'                      = 'certificate'
                'apiKeyId'                               = 'k1'
                'tokenType'                              = 'Bearer'
                'Certificate Download: Pkcs12 Algorithm' = 'AES256'
                'Disable Password Complexity'            = '0'
                'accessToken'                            = 'secret1'
                'Token'                                  = 'secret2'
                'tokenid'                                = 'secret3'
                'Private Key Password'                   = 'secret4'
                'OAuth Token Credential'                 = 'secret5'
                'Client Secret Id'                       = 'secret6'
                'secretType'                             = 'secret7'
                'pairingCodeId'                          = 'id1'
                'pairingPublicKey'                       = 'pub1'
                'pairingCode'                            = 'secret8'
            }
            ConvertTo-TrustMcpSafeObject -InputObject $obj
        }

        'OAuth Token Application Id', 'OAuth Token Scope', 'apiKeyId', 'tokenType', 'Certificate Download: Pkcs12 Algorithm', 'Disable Password Complexity', 'pairingCodeId', 'pairingPublicKey' | ForEach-Object {
            $out[$_] | Should -Not -Be '[redacted]' -Because "$_ describes a secret but is not one"
        }
        'accessToken', 'Token', 'tokenid', 'Private Key Password', 'OAuth Token Credential', 'Client Secret Id', 'secretType', 'pairingCode' | ForEach-Object {
            $out[$_] | Should -Be '[redacted]' -Because "$_ may hold a secret"
        }
    }

    It 'Should truncate long strings and arrays' {
        $out = InModuleScope $ModuleName {
            ConvertTo-TrustMcpSafeObject -InputObject @{ s = ('a' * 50); a = @(1..10) } -MaxStringLength 10 -MaxArrayCount 3
        }

        $out.s | Should -BeLike 'aaaaaaaaaa...*truncated 40*'
        $out.a.Count | Should -Be 4
        $out.a[3] | Should -BeLike '*truncated 7 items*'
    }

    It 'Should keep single item arrays as arrays' {
        $json = InModuleScope $ModuleName {
            ConvertTo-Json -InputObject (ConvertTo-TrustMcpSafeObject -InputObject @{ a = @('one') }) -Compress
        }
        $json | Should -Be '{"a":["one"]}'
    }
}

Describe 'Start-TrustMcpServer stdio' -Tags 'Unit' {

    It 'Should answer requests over stdin/stdout in a child process' {
        # use the same edition running the tests so CI covers both Windows PowerShell 5.1 and PowerShell 7
        $exe = (Get-Process -Id $PID).Path
        $launcher = Join-Path $TestDrive 'start-mcp.ps1'
        $modulePath = (Resolve-Path $ModulePath).Path
        @"
`$ErrorActionPreference = 'Stop'
Import-Module '$modulePath' -Force 3>`$null
`$tc = & (Get-Module VenafiPS) { `$t = [TrustClient]::new(); `$t.Platform = 'CM'; `$t.Server = 'https://cm.example.com'; `$t.AuthType = 'BearerToken'; `$t }
Start-TrustMcpServer -TrustClient `$tc
"@ | Set-Content -Path $launcher

        $requests = @(
            '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18"}}'
            '{"jsonrpc":"2.0","method":"notifications/initialized"}'
            'not json'
            '{"jsonrpc":"2.0","id":2,"method":"tools/list"}'
        )

        # Windows PowerShell turns native stderr into errors even when redirected, and Pester stops on errors
        $out = & {
            $ErrorActionPreference = 'Continue'
            @($requests | & $exe -NoLogo -NoProfile -NonInteractive -File $launcher 2>$null)
        }

        $LASTEXITCODE | Should -Be 0
        # one response per request with an id plus the parse error, nothing for the notification
        $out.Count | Should -Be 3
        $responses = $out | ForEach-Object { $_ | ConvertFrom-Json }
        $responses[0].id | Should -Be 1
        $responses[0].result.serverInfo.name | Should -Be 'VenafiPS'
        $responses[1].error.code | Should -Be -32700
        $responses[2].id | Should -Be 2
        $responses[2].result.tools.name | Should -Contain 'find_certificates'
    }
}
