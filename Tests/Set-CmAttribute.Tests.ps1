BeforeAll {
    . $PSScriptRoot/ModuleCommonCm.ps1

    $customFieldString = @{
        Label             = 'My String Field'
        Guid              = '11111111-1111-1111-1111-111111111111'
        Type              = 1
        RegularExpression = '^[a-z]+$'
    }
    $customFieldList = @{
        Label         = 'My List Field'
        Guid          = '22222222-2222-2222-2222-222222222222'
        Type          = 2
        AllowedValues = @('Red', 'Green', 'Blue')
    }
    $customFieldIdentity = @{
        Label = 'My Identity Field'
        Guid  = '33333333-3333-3333-3333-333333333333'
        Type  = 5
    }
    $customFieldDate = @{
        Label = 'My Date Field'
        Guid  = '44444444-4444-4444-4444-444444444444'
        Type  = 4
    }
    $customFieldUnknown = @{
        Label = 'My Unknown Field'
        Guid  = '55555555-5555-5555-5555-555555555555'
        Type  = 99
    }

    $fakeClient = & (Get-Module $ModuleName) ([scriptblock]::Create('[TrustClient]::new()'))
    $fakeClient.PlatformData.CustomField = @(
        $customFieldString
        $customFieldList
        $customFieldIdentity
        $customFieldDate
        $customFieldUnknown
    )
}

Describe 'Set-CmAttribute' -Tags 'Unit' {

    BeforeEach {
        Mock -CommandName 'Invoke-TrustRestMethod' -MockWith {
            if ( $UriLeaf -like 'Metadata/*' ) {
                # CmMetadataResult.Success = 0
                [pscustomobject]@{ Result = 0 }
            }
            else {
                [pscustomobject]@{ Result = 1 }
            }
        } -ModuleName $ModuleName
        Mock -CommandName 'Test-CmIdentity' -MockWith { $true } -ModuleName $ModuleName
    }

    Context 'Parameter validation' {

        It 'Should throw for an invalid DN path' {
            { Set-CmAttribute -Path 'not-a-valid-path' -Attribute @{ 'Foo' = 'bar' } -TrustClient $fakeClient -Confirm:$false } | Should -Throw
        }

        It 'Should require Attribute' {
            (Get-Command Set-CmAttribute).Parameters['Attribute'].Attributes.Mandatory | Should -Contain $true
        }

        It 'Should require Class in the Policy parameter set' {
            (Get-Command Set-CmAttribute).Parameters['Class'].Attributes.Mandatory | Should -Contain $true
        }

        It 'Should not call Invoke-TrustRestMethod with -WhatIf' {
            Set-CmAttribute -Path '\VED\Policy\test.company.com' -Attribute @{ 'Log Debug' = '1' } -TrustClient $fakeClient -WhatIf
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 0 -ModuleName $ModuleName
        }
    }

    Context 'Base field - set a value' {

        It 'Should call config/Write with the attribute name and value' {
            Set-CmAttribute -Path '\VED\Policy\test.company.com' -Attribute @{ 'Log Debug' = '1' } -TrustClient $fakeClient -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Method -eq 'Post' -and
                $UriLeaf -eq 'config/Write' -and
                $Body.ObjectDN -eq '\VED\Policy\test.company.com' -and
                $Body.AttributeData[0].Name -eq 'Log Debug' -and
                $Body.AttributeData[0].Value -eq '1'
            }
        }

        It 'Should stringify a non-string, non-array value' {
            Set-CmAttribute -Path '\VED\Policy\test.company.com' -Attribute @{ 'Log Debug' = 1 } -TrustClient $fakeClient -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.AttributeData[0].Value -eq '1' -and $Body.AttributeData[0].Value -is [string]
            }
        }

        It 'Should preserve an array value' {
            Set-CmAttribute -Path '\VED\Policy\test.company.com' -Attribute @{ 'X509 SubjectAltName DNS' = @('a.company.com', 'b.company.com') } -TrustClient $fakeClient -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                @($Body.AttributeData[0].Value).Count -eq 2
            }
        }

        It 'Should combine multiple base fields into a single config/Write call' {
            Set-CmAttribute -Path '\VED\Policy\test.company.com' -Attribute @{ 'Log Debug' = '1'; 'Notification Disabled' = '0' } -TrustClient $fakeClient -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $UriLeaf -eq 'config/Write' -and $Body.AttributeData.Count -eq 2
            }
        }

        It 'Should write an error when the API result is not successful' {
            Mock -CommandName 'Invoke-TrustRestMethod' -MockWith { [pscustomobject]@{ Result = 0; Error = 'boom' } } -ModuleName $ModuleName
            Set-CmAttribute -Path '\VED\Policy\test.company.com' -Attribute @{ 'Log Debug' = '1' } -TrustClient $fakeClient -Confirm:$false -ErrorVariable err -ErrorAction SilentlyContinue
            $err | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Base field - set a value with -NoOverwrite' {

        It 'Should call config/AddValue instead of config/Write' {
            Set-CmAttribute -Path '\VED\Policy\test.company.com' -Attribute @{ 'X509 SubjectAltName DNS' = 'a.company.com' } -NoOverwrite -TrustClient $fakeClient -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $UriLeaf -eq 'config/AddValue' -and
                $Body.AttributeName -eq 'X509 SubjectAltName DNS' -and
                $Body.Value -eq 'a.company.com'
            }
        }

        It 'Should call config/AddValue once per base field' {
            Set-CmAttribute -Path '\VED\Policy\test.company.com' -Attribute @{ 'Foo' = '1'; 'Bar' = '2' } -NoOverwrite -TrustClient $fakeClient -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 2 -ModuleName $ModuleName -ParameterFilter {
                $UriLeaf -eq 'config/AddValue'
            }
        }
    }

    Context 'Base field - clear a value with $null' {

        It 'Should call config/ClearAttribute' {
            Set-CmAttribute -Path '\VED\Policy\test.company.com' -Attribute @{ 'Log Debug' = $null } -TrustClient $fakeClient -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Method -eq 'Post' -and
                $UriLeaf -eq 'config/ClearAttribute' -and
                $Body.ObjectDN -eq '\VED\Policy\test.company.com' -and
                $Body.AttributeName -eq 'Log Debug'
            }
        }

        It 'Should not include a Class key in the body' {
            Set-CmAttribute -Path '\VED\Policy\test.company.com' -Attribute @{ 'Log Debug' = $null } -TrustClient $fakeClient -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                -not $Body.ContainsKey('Class')
            }
        }

        It 'Should not call config/Write when clearing' {
            Set-CmAttribute -Path '\VED\Policy\test.company.com' -Attribute @{ 'Log Debug' = $null } -TrustClient $fakeClient -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 0 -ModuleName $ModuleName -ParameterFilter {
                $UriLeaf -eq 'config/Write'
            }
        }

        It 'Should call config/ClearAttribute once per null base field' {
            Set-CmAttribute -Path '\VED\Policy\test.company.com' -Attribute @{ 'Foo' = $null; 'Bar' = $null } -TrustClient $fakeClient -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 2 -ModuleName $ModuleName -ParameterFilter {
                $UriLeaf -eq 'config/ClearAttribute'
            }
        }

        It 'Should ignore -NoOverwrite when the value is null' {
            Set-CmAttribute -Path '\VED\Policy\test.company.com' -Attribute @{ 'Log Debug' = $null } -NoOverwrite -TrustClient $fakeClient -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $UriLeaf -eq 'config/ClearAttribute'
            }
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 0 -ModuleName $ModuleName -ParameterFilter {
                $UriLeaf -eq 'config/AddValue'
            }
        }

        It 'Should handle a mix of null and non-null base fields with separate API calls' {
            Set-CmAttribute -Path '\VED\Policy\test.company.com' -Attribute @{ 'Log Debug' = $null; 'Notification Disabled' = '0' } -TrustClient $fakeClient -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $UriLeaf -eq 'config/ClearAttribute' -and $Body.AttributeName -eq 'Log Debug'
            }
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $UriLeaf -eq 'config/Write' -and $Body.AttributeData[0].Name -eq 'Notification Disabled'
            }
        }

        It 'Should write an error when the API result is not successful' {
            Mock -CommandName 'Invoke-TrustRestMethod' -MockWith { [pscustomobject]@{ Result = 0; Error = 'boom' } } -ModuleName $ModuleName
            Set-CmAttribute -Path '\VED\Policy\test.company.com' -Attribute @{ 'Log Debug' = $null } -TrustClient $fakeClient -Confirm:$false -ErrorVariable err -ErrorAction SilentlyContinue
            $err | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Policy attribute - set a value' {

        It 'Should call config/WritePolicy with Class, AttributeName, and Values' {
            Set-CmAttribute -Path '\VED\Policy\test folder' -Class 'X509 Certificate' -Attribute @{ 'Notification Disabled' = '0' } -TrustClient $fakeClient -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $UriLeaf -eq 'config/WritePolicy' -and
                $Body.ObjectDN -eq '\VED\Policy\test folder' -and
                $Body.Class -eq 'X509 Certificate' -and
                $Body.AttributeName -eq 'Notification Disabled' -and
                $Body.Values[0] -eq '0' -and
                $Body.Locked -eq 0
            }
        }

        It 'Should set Locked to 1 with -Lock' {
            Set-CmAttribute -Path '\VED\Policy\test folder' -Class 'X509 Certificate' -Attribute @{ 'Notification Disabled' = '0' } -Lock -TrustClient $fakeClient -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.Locked -eq 1
            }
        }

        It 'Should call config/WritePolicy once per base field since only 1 key/value is allowed per call' {
            Set-CmAttribute -Path '\VED\Policy\test folder' -Class 'X509 Certificate' -Attribute @{ 'Foo' = '1'; 'Bar' = '2' } -TrustClient $fakeClient -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 2 -ModuleName $ModuleName -ParameterFilter {
                $UriLeaf -eq 'config/WritePolicy'
            }
        }
    }

    Context 'Policy attribute - set a value with -NoOverwrite' {

        It 'Should call config/AddPolicyValue instead of config/WritePolicy' {
            Set-CmAttribute -Path '\VED\Policy\test folder' -Class 'X509 Certificate' -Attribute @{ 'Notification Disabled' = '0' } -NoOverwrite -TrustClient $fakeClient -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $UriLeaf -eq 'config/AddPolicyValue' -and
                $Body.Value -eq '0'
            }
        }
    }

    Context 'Policy attribute - clear a value with $null' {

        It 'Should call config/ClearPolicyAttribute with Class and AttributeName' {
            Set-CmAttribute -Path '\VED\Policy\test folder' -Class 'X509 Certificate' -Attribute @{ 'Notification Disabled' = $null } -TrustClient $fakeClient -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $UriLeaf -eq 'config/ClearPolicyAttribute' -and
                $Body.ObjectDN -eq '\VED\Policy\test folder' -and
                $Body.Class -eq 'X509 Certificate' -and
                $Body.AttributeName -eq 'Notification Disabled'
            }
        }

        It 'Should not call config/WritePolicy when clearing' {
            Set-CmAttribute -Path '\VED\Policy\test folder' -Class 'X509 Certificate' -Attribute @{ 'Notification Disabled' = $null } -TrustClient $fakeClient -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 0 -ModuleName $ModuleName -ParameterFilter {
                $UriLeaf -eq 'config/WritePolicy'
            }
        }
    }

    Context 'Custom field - string type' {

        It 'Should call Metadata/Set with the guid and value' {
            Set-CmAttribute -Path '\VED\Policy\test.company.com' -Attribute @{ 'My String Field' = 'abc' } -TrustClient $fakeClient -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $UriLeaf -eq 'Metadata/Set' -and
                $Body.DN -eq '\VED\Policy\test.company.com' -and
                $Body.GuidData[0].ItemGuid -eq $customFieldString.Guid -and
                $Body.GuidData[0].List[0] -eq 'abc' -and
                $Body.KeepExisting -eq $true
            }
        }

        It 'Should allow lookup by guid instead of label' {
            Set-CmAttribute -Path '\VED\Policy\test.company.com' -Attribute @{ ($customFieldString.Guid) = 'abc' } -TrustClient $fakeClient -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $UriLeaf -eq 'Metadata/Set' -and $Body.GuidData[0].ItemGuid -eq $customFieldString.Guid
            }
        }

        It 'Should write an error when the regular expression does not match' {
            Set-CmAttribute -Path '\VED\Policy\test.company.com' -Attribute @{ 'My String Field' = '123' } -TrustClient $fakeClient -Confirm:$false -ErrorVariable err -ErrorAction SilentlyContinue
            $err | Should -Not -BeNullOrEmpty
        }

        It 'Should not call Invoke-TrustRestMethod when validation fails' {
            Set-CmAttribute -Path '\VED\Policy\test.company.com' -Attribute @{ 'My String Field' = '123' } -TrustClient $fakeClient -Confirm:$false -ErrorAction SilentlyContinue
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 0 -ModuleName $ModuleName
        }

        It 'Should bypass regular expression validation with -BypassValidation' {
            Set-CmAttribute -Path '\VED\Policy\test.company.com' -Attribute @{ 'My String Field' = '123' } -BypassValidation -TrustClient $fakeClient -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $UriLeaf -eq 'Metadata/Set'
            }
        }

        It 'Should write an error when the metadata result is not successful' {
            Mock -CommandName 'Invoke-TrustRestMethod' -MockWith { [pscustomobject]@{ Result = 1; Error = 'boom' } } -ModuleName $ModuleName
            Set-CmAttribute -Path '\VED\Policy\test.company.com' -Attribute @{ 'My String Field' = 'abc' } -TrustClient $fakeClient -Confirm:$false -ErrorVariable err -ErrorAction SilentlyContinue
            $err | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Custom field - list type' {

        It 'Should succeed when the value is in the allowed list' {
            Set-CmAttribute -Path '\VED\Policy\test.company.com' -Attribute @{ 'My List Field' = 'Red' } -TrustClient $fakeClient -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.GuidData[0].ItemGuid -eq $customFieldList.Guid
            }
        }

        It 'Should write an error when the value is not in the allowed list' {
            Set-CmAttribute -Path '\VED\Policy\test.company.com' -Attribute @{ 'My List Field' = 'Purple' } -TrustClient $fakeClient -Confirm:$false -ErrorVariable err -ErrorAction SilentlyContinue
            $err | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Custom field - identity type' {

        It 'Should succeed when the identity exists' {
            Set-CmAttribute -Path '\VED\Policy\test.company.com' -Attribute @{ 'My Identity Field' = 'local:abc123' } -TrustClient $fakeClient -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.GuidData[0].ItemGuid -eq $customFieldIdentity.Guid
            }
        }

        It 'Should write an error when the identity does not exist' {
            Mock -CommandName 'Test-CmIdentity' -MockWith { $false } -ModuleName $ModuleName
            Set-CmAttribute -Path '\VED\Policy\test.company.com' -Attribute @{ 'My Identity Field' = 'local:missing' } -TrustClient $fakeClient -Confirm:$false -ErrorVariable err -ErrorAction SilentlyContinue
            $err | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Custom field - date type' {

        It 'Should succeed with a valid date string' {
            Set-CmAttribute -Path '\VED\Policy\test.company.com' -Attribute @{ 'My Date Field' = '2024-01-01' } -TrustClient $fakeClient -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.GuidData[0].ItemGuid -eq $customFieldDate.Guid
            }
        }

        It 'Should write an error with an invalid date string' {
            Set-CmAttribute -Path '\VED\Policy\test.company.com' -Attribute @{ 'My Date Field' = 'not-a-date' } -TrustClient $fakeClient -Confirm:$false -ErrorVariable err -ErrorAction SilentlyContinue
            $err | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Custom field - unknown type' {

        It 'Should write an error for an unrecognized custom field type' {
            Set-CmAttribute -Path '\VED\Policy\test.company.com' -Attribute @{ 'My Unknown Field' = 'abc' } -TrustClient $fakeClient -Confirm:$false -ErrorVariable err -ErrorAction SilentlyContinue
            $err | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Custom field - clear a value with $null' {

        It 'Should call Metadata/Set with an empty List' {
            Set-CmAttribute -Path '\VED\Policy\test.company.com' -Attribute @{ 'My String Field' = $null } -TrustClient $fakeClient -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $UriLeaf -eq 'Metadata/Set' -and
                $Body.GuidData[0].ItemGuid -eq $customFieldString.Guid -and
                @($Body.GuidData[0].List).Count -eq 0
            }
        }

        It 'Should bypass validation automatically when clearing' {
            Set-CmAttribute -Path '\VED\Policy\test.company.com' -Attribute @{ 'My List Field' = $null } -TrustClient $fakeClient -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $UriLeaf -eq 'Metadata/Set'
            }
        }
    }

    Context 'Custom field - policy (Class specified)' {

        It 'Should call Metadata/SetPolicy with ConfigClass and Locked' {
            Set-CmAttribute -Path '\VED\Policy\test folder' -Class 'X509 Certificate' -Attribute @{ 'My String Field' = 'abc' } -TrustClient $fakeClient -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $UriLeaf -eq 'Metadata/SetPolicy' -and
                $Body.DN -eq '\VED\Policy\test folder' -and
                $Body.ConfigClass -eq 'X509 Certificate' -and
                $Body.GuidData[0].ItemGuid -eq $customFieldString.Guid -and
                $Body.Locked -eq 0
            }
        }

        It 'Should set Locked to 1 with -Lock' {
            Set-CmAttribute -Path '\VED\Policy\test folder' -Class 'X509 Certificate' -Attribute @{ 'My String Field' = 'abc' } -Lock -TrustClient $fakeClient -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.Locked -eq 1
            }
        }
    }

    Context 'Mixed base fields and custom fields' {

        It 'Should call both config/Write and Metadata/Set' {
            Set-CmAttribute -Path '\VED\Policy\test.company.com' -Attribute @{ 'Log Debug' = '1'; 'My String Field' = 'abc' } -TrustClient $fakeClient -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter { $UriLeaf -eq 'config/Write' }
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter { $UriLeaf -eq 'Metadata/Set' }
        }

        It 'Should call config/ClearAttribute, config/Write, and Metadata/Set independently' {
            Set-CmAttribute -Path '\VED\Policy\test.company.com' -Attribute @{ 'Log Debug' = $null; 'Notification Disabled' = '1'; 'My String Field' = 'abc' } -TrustClient $fakeClient -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter { $UriLeaf -eq 'config/ClearAttribute' }
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter { $UriLeaf -eq 'config/Write' }
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter { $UriLeaf -eq 'Metadata/Set' }
        }
    }

    Context 'Pipeline input' {

        It 'Should accept Path from the pipeline by property name' {
            [pscustomobject]@{ Path = '\VED\Policy\test.company.com' } | Set-CmAttribute -Attribute @{ 'Log Debug' = '1' } -TrustClient $fakeClient -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.ObjectDN -eq '\VED\Policy\test.company.com'
            }
        }

        It 'Should accept DN alias from the pipeline by property name' {
            [pscustomobject]@{ DN = '\VED\Policy\test.company.com' } | Set-CmAttribute -Attribute @{ 'Log Debug' = '1' } -TrustClient $fakeClient -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $Body.ObjectDN -eq '\VED\Policy\test.company.com'
            }
        }
    }

    Context 'Set-VdcAttribute alias' {

        It 'Should be registered as an alias for Set-CmAttribute' {
            Get-Alias -Name 'Set-VdcAttribute' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ResolvedCommandName | Should -Be 'Set-CmAttribute'
        }

        It 'Should behave identically when invoked via the alias' {
            Set-VdcAttribute -Path '\VED\Policy\test.company.com' -Attribute @{ 'Log Debug' = $null } -TrustClient $fakeClient -Confirm:$false
            Should -Invoke -CommandName 'Invoke-TrustRestMethod' -Times 1 -ModuleName $ModuleName -ParameterFilter {
                $UriLeaf -eq 'config/ClearAttribute'
            }
        }
    }
}
