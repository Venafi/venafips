BeforeAll {
    . $PSScriptRoot/ModuleCommonCm.ps1

    # an error record like Invoke-RestMethod throws for a 403, on both PowerShell 5.1 and 7
    function New-ForbiddenError {
        param ([string] $Body)
        $ex = [System.Exception]::new('Response status code does not indicate success: 403 (Forbidden).')
        $ex | Add-Member -NotePropertyName 'Response' -NotePropertyValue ([pscustomobject]@{ StatusCode = 403 })
        $er = [System.Management.Automation.ErrorRecord]::new($ex, 'WebCmdletWebResponseException', 'InvalidOperation', $null)
        if ( $Body ) { $er.ErrorDetails = [System.Management.Automation.ErrorDetails]::new($Body) }
        $er
    }
}

Describe 'Invoke-TrustRestMethod' -Tags 'Unit' {

    Context 'Self-Hosted 403' {

        BeforeEach {
            Mock -CommandName 'Invoke-SessionRefresh' -ModuleName $ModuleName -MockWith {}
        }

        It 'Should report the token scope when the server rejected it' {
            $er = New-ForbiddenError '{"error":"insufficient_scope","error_description":"Grant rejected scope \u0027configuration\u0027. Call POST Authorize/OAuth with the correct scope and restriction."}'
            Mock -CommandName 'Invoke-RestMethod' -ModuleName $ModuleName -MockWith { throw $er }.GetNewClosure()

            { Read-CmLog -First 1 } | Should -Throw "Read-CmLog requires a token scope of 'any scope'.  The current scope of 'configuration' is insufficient.  Call New-TrustClient with the correct scope."
        }

        It 'Should report the reason from the server for a permission error' {
            $er = New-ForbiddenError '{"Error":"No permission to read default SQL channel (\\VED\\Logging\\Channels\\Default SQL Channel).","LogEvents":null}'
            Mock -CommandName 'Invoke-RestMethod' -ModuleName $ModuleName -MockWith { throw $er }.GetNewClosure()

            { Read-CmLog -First 1 } | Should -Throw 'Permission denied: No permission to read default SQL channel (\VED\Logging\Channels\Default SQL Channel).'
        }

        It 'Should report a permission error when the server did not give a reason' {
            $er = New-ForbiddenError
            Mock -CommandName 'Invoke-RestMethod' -ModuleName $ModuleName -MockWith { throw $er }.GetNewClosure()

            { Read-CmLog -First 1 } | Should -Throw 'Permission denied.  Check the account has permission to the object.'
        }

        It 'Should report a non-json reason from the server as is' {
            $er = New-ForbiddenError 'Access is denied'
            Mock -CommandName 'Invoke-RestMethod' -ModuleName $ModuleName -MockWith { throw $er }.GetNewClosure()

            { Read-CmLog -First 1 } | Should -Throw 'Permission denied: Access is denied'
        }
    }
}
