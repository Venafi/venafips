
. $PSScriptRoot/ModuleCommon.ps1

Mock -CommandName 'Get-TrustClient' -MockWith {
    [pscustomobject]@{
        Platform             = 'VC'
        Server               = 'https://api.venafi.cloud'
        TimeoutSec           = 0
        SkipCertificateCheck = $false
        Key                  = New-Object System.Management.Automation.PSCredential('VcKey', ('c7afbda6-0ae4-43b2-b775-42ab2940ba9e' | ConvertTo-SecureString -AsPlainText -Force))
        User                 = @{
            userId                       = 'f6afeb44-3edc-435b-9c2a-da61524af8ed'
            username                     = 'greg.brownstein@cyberark.com'
            companyId                    = '810646a6-9600-4850-a89d-989ec69d9792'
            firstname                    = 'Greg'
            lastname                     = 'Brownstein'
            emailAddress                 = 'ggreg.brownstein@cyberark.com'
            userType                     = 'EXTERNAL'
            userAccountType              = 'WEB_UI'
            ssoStatus                    = 'INACTIVE'
            userStatus                   = 'ACTIVE'
            systemRoles                  = '{SYSTEM_ADMIN}'
            productRoles                 = $null
            localLoginDisabled           = $False
            hasPassword                  = $true
            forceLocalPasswordExpiration = $false
            firstLoginDate               = (Get-Date)
            creationDate                 = (Get-Date)
            ownedTeams                   = '{cd7650f5-f54b-473f-9aba-e6f769ad60b7}'
            memberedTeams                = '{cd7650f5-f54b-473f-9aba-e6f769ad60b7}'
            disabled                     = $false
            signupAttributes             = $null
        }
    }
} -ModuleName $ModuleName
