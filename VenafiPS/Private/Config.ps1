$script:VcRegions = @{
    'us' = 'https://api.venafi.cloud'
    'eu' = 'https://api.eu.venafi.cloud'
    'au' = 'https://api.au.venafi.cloud'
    'uk' = 'https://api.uk.venafi.cloud'
    'sg' = 'https://api.sg.venafi.cloud'
    'ca' = 'https://api.ca.venafi.cloud'
}

# vaas fields to ensure the values are upper case
$script:vaasValuesToUpper = 'certificateStatus', 'signatureAlgorithm', 'signatureHashAlgorithm', 'encryptionType', 'versionType', 'certificateSource', 'deploymentStatus'

# vaas fields proper case
$script:vaasFields = @(
    'certificateId',
    'applicationIds',
    'companyId',
    'managedCertificateId',
    'fingerprint',
    'certificateName',
    'issuerCertificateIds',
    'certificateStatus',
    'statusModificationUserId',
    'modificationDate',
    'statusModificationDate',
    'validityStart',
    'validityEnd',
    'selfSigned',
    'signatureAlgorithm',
    'signatureHashAlgorithm',
    'encryptionType',
    'keyCurve',
    'subjectKeyIdentifierHash',
    'authorityKeyIdentifierHash',
    'serialNumber',
    'subjectDN',
    'subjectCN',
    'subjectO',
    'subjectST',
    'subjectC',
    'subjectAlternativeNamesByType',
    'subjectAlternativeNameDns',
    'issuerDN',
    'issuerCN',
    'issuerST',
    'issuerL',
    'issuerC',
    'keyUsage',
    'extendedKeyUsage',
    'ocspNoCheck',
    'versionType',
    'activityDate',
    'activityType',
    'activityName',
    'criticality'
)

$script:functionConfig = @{
    'Add-VdcAdaptableHash'             = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'restricted=manage,delete'
    }
    'Add-VdcCertificateAssociation'    = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'certificate=manage'
    }
    'Add-VdcEngineFolder'              = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'configuration=manage'
    }
    'Add-VdcTeamMember'                = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'configuration=manage'
    }
    'Add-VdcTeamOwner'                 = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'configuration=manage'
    }
    'Convert-VdcObject'                = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'configuration=manage'
    }
    'Export-VdcCertificate'            = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'certificate=manage'
    }
    'Find-VdcClient'                   = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'agent=$null'
    }
    'Find-VdcEngine'                   = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'configuration=$null'
    }
    'Find-VdcIdentity'                 = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'configuration=$null'
    }
    'Find-VdcObject'                   = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'configuration=$null'
    }
    'Find-VdcVaultId'                  = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'restricted=$null'
    }
    'Find-VdcCertificate'              = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'certificate=$null'
    }
    'Get-VdcAttribute'                 = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'configuration=$null'
    }
    'Get-VdcClassAttribute'            = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'any scope'
    }
    'Get-VdcCredential'                = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'security=manage'
    }
    'Get-VdcCustomField'               = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'any scope'
    }
    'Get-VdcEngineFolder'              = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'configuration=manage'
    }
    'Get-VdcIdentityAttribute'         = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'configuration=$null'
    }
    'Get-VdcObject'                    = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'any scope'
    }
    'Get-VdcPermission'                = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'security=$null'
    }
    'Get-VdcSystemStatus'              = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'any scope'
    }
    'Get-VdcWorkflowTicket'            = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'any scope'
    }
    'Get-VdcCertificate'               = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'certificate=$null'
    }
    'Get-VdcIdentity'                  = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'configuration=$null'
    }
    'Get-VdcTeam'                      = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'configuration=manage'
    }
    'Import-VdcCertificate'            = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'certificate=discover'
    }
    'Import-VcCertificate'             = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = ''
    }
    'Invoke-VdcCertificateAction'      = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'certificate=manage for Reset, Renew, Push, and Validate.  certificate=revoke for Revoke.  certificate=delete for Delete.'
    }
    'Move-VdcObject'                   = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'configuration=manage'
    }
    'New-VdcCapiApplication'           = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'configuration=manage'
    }
    'New-VdcCertificate'               = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'certificate=manage'
    }
    'New-VdcCustomField'               = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'configuration=manage'
    }
    'New-VdcDevice'                    = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'configuration=manage'
    }
    'New-VdcObject'                    = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'configuration=manage.  If a certificate is provided as an attribute, certificate=manage as well.'
    }
    'New-VdcPolicy'                    = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'configuration=manage'
    }
    'New-VdcToken'                     = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'any scope'
    }
    'New-VcCertificate'                = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = ''
    }
    'New-VcConnector'                  = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = ''
    }
    'New-TrustClient'                = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = ''
    }
    'Remove-VdcCertificate'            = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'certificate=delete.  If using KeepAssociatedApps, configuration=$null,certificate=manage as well.'
    }
    'Remove-VdcCertificateAssociation' = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'certificate=manage.  If using -All, configuration=$null as well.'
    }
    'Remove-VdcClient'                 = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'agent=delete'
    }
    'Remove-VdcEngineFolder'           = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'configuration=delete'
    }
    'Remove-VdcObject'                 = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'configuration=delete'
    }
    'Remove-VdcPermission'             = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'security=delete'
    }
    'Rename-VdcObject'                 = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'configuration=manage'
    }
    'Revoke-VdcGrant'                  = @{
        'VdcVersion'    = '22.3'
        'VdcTokenScope' = 'admin=delete'
    }
    'Set-VdcAttribute'                 = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'configuration=manage'
    }
    'Set-VdcCredential'                = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'security=manage'
    }
    'Set-VdcPermission'                = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'security=manage'
    }
    'Set-VdcWorkflowTicketStatus'      = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'approve with any scope'
    }
    'Test-VdcIdentity'                 = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'configuration=$null'
    }
    'Test-VdcObject'                   = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'configuration=$null'
    }
    'Write-VdcLog'                     = @{
        'VdcVersion'    = ''
        'VdcTokenScope' = 'any scope'
    }
}