$script:CmsRegions = @{
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
    'Add-CmAdaptableHash'             = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'restricted=manage,delete'
    }
    'Add-CmCertificateAssociation'    = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'certificate=manage'
    }
    'Add-CmEngineFolder'              = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=manage'
    }
    'Add-CmTeamMember'                = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=manage'
    }
    'Add-CmTeamOwner'                 = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=manage'
    }
    'Convert-CmObject'                = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=manage'
    }
    'Export-CmCertificate'            = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'certificate=manage'
    }
    'Find-CmClient'                   = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'agent=$null'
    }
    'Find-CmEngine'                   = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=$null'
    }
    'Find-CmIdentity'                 = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=$null'
    }
    'Find-CmObject'                   = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=$null'
    }
    'Find-CmVaultId'                  = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'restricted=$null'
    }
    'Find-CmCertificate'              = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'certificate=$null'
    }
    'Get-CmAttribute'                 = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=$null'
    }
    'Get-CmClassAttribute'            = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'any scope'
    }
    'Get-CmCredential'                = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'security=manage'
    }
    'Get-CmCustomField'               = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'any scope'
    }
    'Get-CmEngineFolder'              = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=manage'
    }
    'Get-CmIdentityAttribute'         = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=$null'
    }
    'Get-CmObject'                    = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'any scope'
    }
    'Get-CmPermission'                = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'security=$null'
    }
    'Get-CmSystemStatus'              = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'any scope'
    }
    'Get-CmWorkflowTicket'            = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'any scope'
    }
    'Get-CmCertificate'               = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'certificate=$null'
    }
    'Get-CmIdentity'                  = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=$null'
    }
    'Get-CmTeam'                      = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=manage'
    }
    'Import-CmCertificate'            = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'certificate=discover'
    }
    'Import-TrustCertificate'             = @{
        'CmVersion'    = ''
        'CmTokenScope' = ''
    }
    'Invoke-CmCertificateAction'      = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'certificate=manage for Reset, Renew, Push, and Validate.  certificate=revoke for Revoke.  certificate=delete for Delete.'
    }
    'Move-CmObject'                   = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=manage'
    }
    'New-CmCapiApplication'           = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=manage'
    }
    'New-CmCertificate'               = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'certificate=manage'
    }
    'New-CmCustomField'               = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=manage'
    }
    'New-CmDevice'                    = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=manage'
    }
    'New-CmObject'                    = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=manage.  If a certificate is provided as an attribute, certificate=manage as well.'
    }
    'New-CmPolicy'                    = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=manage'
    }
    'New-CmToken'                     = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'any scope'
    }
    'Remove-CmCertificate'            = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'certificate=delete.  If using KeepAssociatedApps, configuration=$null,certificate=manage as well.'
    }
    'Remove-CmCertificateAssociation' = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'certificate=manage.  If using -All, configuration=$null as well.'
    }
    'Remove-CmClient'                 = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'agent=delete'
    }
    'Remove-CmEngineFolder'           = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=delete'
    }
    'Remove-CmObject'                 = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=delete'
    }
    'Remove-CmPermission'             = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'security=delete'
    }
    'Rename-CmObject'                 = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=manage'
    }
    'Revoke-CmGrant'                  = @{
        'CmVersion'    = '22.3'
        'CmTokenScope' = 'admin=delete'
    }
    'Set-CmAttribute'                 = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=manage'
    }
    'Set-CmCredential'                = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'security=manage'
    }
    'Set-CmPermission'                = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'security=manage'
    }
    'Set-CmWorkflowTicketStatus'      = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'approve with any scope'
    }
    'Test-CmIdentity'                 = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=$null'
    }
    'Test-CmObject'                   = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'configuration=$null'
    }
    'Write-CmLog'                     = @{
        'CmVersion'    = ''
        'CmTokenScope' = 'any scope'
    }
}