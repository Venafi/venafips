# Force TLS 1.2 if currently set lower
if ([Net.ServicePointManager]::SecurityProtocol.value__ -lt 3072) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

# the new version will be replaced below during deployment
$script:ModuleVersion = '((NEW_VERSION))'

$script:VcRegions = @{
    'us' = 'https://api.venafi.cloud'
    'eu' = 'https://api.eu.venafi.cloud'
    'au' = 'https://api.au.venafi.cloud'
    'uk' = 'https://api.uk.venafi.cloud'
    'sg' = 'https://api.sg.venafi.cloud'
    'ca' = 'https://api.ca.venafi.cloud'
}
$Script:VenafiSession = $null
$script:ThreadJobAvailable = ($null -ne (Get-Module -Name Microsoft.PowerShell.ThreadJob -ListAvailable))
$script:DevMode = $script:ModuleVersion -match 'NEW_VERSION'
$script:ParallelImportPath = $PSCommandPath

Export-ModuleMember -Alias * -Variable VenafiSession -Function *

# ModuleVersion will get updated during the build and this will not run
# this is only needed during development since all files will be merged into one psm1
if ( $script:DevMode ) {
    $folders = @('Enum', 'Classes', 'Public', 'Private')
    $publicFunction = @()

    foreach ( $folder in $folders) {

        $files = Get-ChildItem -Path "$PSScriptRoot\$folder\*.ps1" -Recurse

        Foreach ( $thisFile in $files ) {
            Try {
                Write-Verbose ('dot sourcing {0}' -f $thisFile.FullName)
                . $thisFile.fullname
                # if ( $folder -eq 'Public' ) {
                Export-ModuleMember -Function $thisFile.Basename
                $publicFunction += $thisFile.BaseName
                # }
            }
            Catch {
                Write-Error ("Failed to import function {0}: {1}" -f $thisFile.fullname, $folder)
            }
        }
    }
}

$moduleCommands = Get-Command -Module VenafiPS | Select-Object -ExpandProperty Name
$vdcCommands = $moduleCommands | Where-Object { $_ -like '*-Vdc*' }
$vcCommands = $moduleCommands | Where-Object { $_ -like '*-Vc*' }

# define the argument completer details
# d = description, required
# l = lookup, required if lookup value is different than 'name'
$vcCompletions = @{
    'CloudProvider'   = @{
        'd' = { 'type: {0}, status: {1}' -f $_.type, $_.status }
    }
    'Application'     = @{
        'd' = { if ( $_.description ) { $_.description } else { $itemText } }
    }
    'IssuingTemplate' = @{
        'd' = { 'product: {0}, validity: {1}' -f $_.product.productName, $_.product.validityPeriod }
    }
    'VSatellite'      = @{
        'd' = { 'status: {0}, version: {1}' -f $_.edgeStatus, $_.satelliteVersion }
    }
    'Credential'      = @{
        'd' = { 'type: {0}, authentication: {1}' -f $_.cmsType, $_.authType }
    }
    'Team'            = @{
        'd' = { 'role: {0}' -f $_.role }
    }
    'Tag'             = @{
        'l' = 'tagId'
        'd' = {
            if ($_.value) {
                'values: {0}' -f ($_.value -join ', ')
            }
            else {
                'no values set'
            }
        }
    }
    'User'            = @{
        'l' = 'username'
        'd' = { 'user type: {0}, system roles: {1}' -f $_.userType, $_.systemRoles -join ',' }
    }
}

$vcGenericArgCompleterSb = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    # $objectType = $parameterName
    if ( $parameterName -eq 'ID' ) {
        # figure out object type based on function name since 'ID' is used in many functions

    }

    $lookup = if ($vcCompletions.$parameterName.l) {
        $vcCompletions.$parameterName.l
    }
    else {
        'name'
    }

    switch ($parameterName) {

        'MachineType' {
            if ( -not $script:vcMachineType ) {
                $script:vcMachineType = Invoke-VenafiRestMethod -UriLeaf 'plugins?pluginTypes=MACHINE' |
                    Select-Object -ExpandProperty plugins |
                    Select-Object -Property @{'n' = 'machineTypeId'; 'e' = { $_.Id } }, * -ExcludeProperty id |
                    Sort-Object -Property name
            }
            $script:vcMachineType | Where-Object name -like ('{0}*' -f $wordToComplete.Trim("'")) | ForEach-Object {
                $itemText = "'{0}'" -f $_.name
                $itemDescription = 'supports: {0}' -f ($_.workTypes -join ', ')

                [System.Management.Automation.CompletionResult]::new($itemText, $itemText, 'ParameterValue', $itemDescription)
            }
        }

        'Certificate' {
            # there might be a ton of certs so ensure they provide at least 3 characters
            if ( $wordToComplete.Length -ge 3 ) {
                Find-VcCertificate -Name $wordToComplete | ForEach-Object { "'$($_.certificateName)'" }
            }
        }

        default {
            # catch all for $vcCompletions
            Get-VcData -Type $parameterName | Where-Object $lookup -like ('{0}*' -f $wordToComplete.Trim("'")) | ForEach-Object {
                $itemText = "'{0}'" -f $_.$lookup
                $itemDescription = & $vcCompletions.$parameterName.d
                [System.Management.Automation.CompletionResult]::new($itemText, $itemText, 'ParameterValue', $itemDescription)
            }
        }
    }
}

'MachineType', 'Certificate' + $vcCompletions.Keys | ForEach-Object {
    Register-ArgumentCompleter -CommandName $vcCommands -ParameterName $_ -ScriptBlock $vcGenericArgCompleterSb
}

$vdcPathArgCompleterSb = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    if ( -not $wordToComplete ) {
        # if no word provided, default to \ved\policy
        $wordToComplete = '\VED\Policy\'
    }

    # if the path starts with ' or ", that will come along for the ride so ensure we trim that first
    $fullWord = $wordToComplete.Trim("`"'") | ConvertTo-VdcFullPath
    $leaf = $fullWord.Split('\')[-1]
    $parent = $fullWord.Substring(0, $fullWord.LastIndexOf("\$leaf"))

    # get items in parent folder
    $objs = Find-VdcObject -Path $parent
    $objs | Where-Object { $_.name -like "$leaf*" } | ForEach-Object {
        $itemText = if ( $_.TypeName -eq 'Policy' ) {
            "'$($_.Path)\"
        }
        else {
            "'$($_.Path)"
        }
        [System.Management.Automation.CompletionResult]::new($itemText, $itemText, 'ParameterValue', $_.TypeName)

    }
}
Register-ArgumentCompleter -CommandName $vdcCommands -ParameterName 'Path' -ScriptBlock $vdcPathArgCompleterSb

$vcLogArgCompleterSb = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    if ( -not $script:vcActivityType ) {
        $script:vcActivityType = Invoke-VenafiRestMethod -UriLeaf 'activitytypes' |
            Select-Object -Property @{'n' = 'type'; 'e' = { $_.key } }, @{'n' = 'name'; 'e' = { $_.values.key } } -ExcludeProperty readableName |
            Sort-Object -Property type
    }

    switch ($parameterName) {
        'Type' {
            $script:vcActivityType | Where-Object type -like ('{0}*' -f $wordToComplete.Trim("'")) | ForEach-Object {
                $itemText = "'{0}'" -f $_.type
                $itemDescription = 'activity names: {0}' -f ($_.name -join ', ')
                [System.Management.Automation.CompletionResult]::new($itemText, $itemText, 'ParameterValue', $itemDescription)
            }
        }

        'Name' {
            # If Type is provided, filter names for that type only
            if ($fakeBoundParameters.ContainsKey('Type')) {
                $typeValue = $fakeBoundParameters['Type'].Trim("'")
                $names = $script:vcActivityType | Where-Object { $_.type -eq $typeValue } | Select-Object -ExpandProperty name
            }
            else {
                $names = $script:vcActivityType | Select-Object -ExpandProperty name
            }
            $names | Where-Object { $_ -like ('{0}*' -f $wordToComplete.Trim("'")) } | ForEach-Object {
                $itemText = "'{0}'" -f $_
                [System.Management.Automation.CompletionResult]::new($itemText)
            }
        }
    }
}
Register-ArgumentCompleter -CommandName 'Find-VcLog' -ParameterName 'Type' -ScriptBlock $vcLogArgCompleterSb
Register-ArgumentCompleter -CommandName 'Find-VcLog' -ParameterName 'Name' -ScriptBlock $vcLogArgCompleterSb

$vdcGenericArgCompleterSb = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    switch ($parameterName) {
        'Algorithm' {
            Get-VdcData -Type Algorithm | Where-Object Name -like ('{0}*' -f $wordToComplete.Trim("'")) | ForEach-Object {
                $alg = "'{0}'" -f $_.Name
                [System.Management.Automation.CompletionResult]::new($alg, $alg, 'ParameterValue', $_.Description)
            }
        }
    }
}

'Algorithm' | ForEach-Object {
    Register-ArgumentCompleter -CommandName $vdcCommands -ParameterName $_ -ScriptBlock $vdcGenericArgCompleterSb
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
        'TppVersion'    = ''
        'TppTokenScope' = 'restricted=manage,delete'
    }
    'Add-VdcCertificateAssociation'    = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'certificate=manage'
    }
    'Add-VdcEngineFolder'              = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=manage'
    }
    'Add-VdcTeamMember'                = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=manage'
    }
    'Add-VdcTeamOwner'                 = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=manage'
    }
    'Convert-VdcObject'                = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=manage'
    }
    'ConvertTo-VdcGuid'                = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'any scope'
    }
    'ConvertTo-VdcPath'                = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'any scope'
    }
    'Export-VdcCertificate'            = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'certificate=manage'
    }
    'Find-VdcClient'                   = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'agent=$null'
    }
    'Find-VdcEngine'                   = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=$null'
    }
    'Find-VdcIdentity'                 = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=$null'
    }
    'Find-VdcObject'                   = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=$null'
    }
    'Find-VdcVaultId'                  = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'restricted=$null'
    }
    'Find-VcObject'                    = @{
        'TppVersion'    = ''
        'TppTokenScope' = ''
    }
    'Find-VdcCertificate'              = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'certificate=$null'
    }
    'Get-VdcAttribute'                 = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=$null'
    }
    'Get-VdcClassAttribute'            = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'any scope'
    }
    'Get-VdcCredential'                = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'security=manage'
    }
    'Get-VdcCustomField'               = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'any scope'
    }
    'Get-VdcEngineFolder'              = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=manage'
    }
    'Get-VdcIdentityAttribute'         = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=$null'
    }
    'Get-VdcObject'                    = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'any scope'
    }
    'Get-VdcPermission'                = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'security=$null'
    }
    'Get-VdcSystemStatus'              = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'any scope'
    }
    'Get-VdcVersion'                   = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'any scope'
    }
    'Get-VdcWorkflowTicket'            = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'any scope'
    }
    'Get-VdcCertificate'               = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'certificate=$null'
    }
    'Get-VdcIdentity'                  = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=$null'
    }
    'Get-VdcTeam'                      = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=manage'
    }
    'Import-VdcCertificate'            = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'certificate=discover'
    }
    'Import-VcCertificate'             = @{
        'TppVersion'    = ''
        'TppTokenScope' = ''
    }
    'Invoke-VdcCertificateAction'      = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'certificate=manage for Reset, Renew, Push, and Validate.  certificate=revoke for Revoke.  certificate=delete for Delete.'
    }
    'Move-VdcObject'                   = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=manage'
    }
    'New-VdcCapiApplication'           = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=manage'
    }
    'New-VdcCertificate'               = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'certificate=manage'
    }
    'New-VdcCustomField'               = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=manage'
    }
    'New-VdcDevice'                    = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=manage'
    }
    'New-VdcObject'                    = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=manage.  If a certificate is provided as an attribute, certificate=manage as well.'
    }
    'New-VdcPolicy'                    = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=manage'
    }
    'New-VdcToken'                     = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'any scope'
    }
    'New-VcCertificate'                = @{
        'TppVersion'    = ''
        'TppTokenScope' = ''
    }
    'New-VcConnector'                  = @{
        'TppVersion'    = ''
        'TppTokenScope' = ''
    }
    'New-VenafiSession'                = @{
        'TppVersion'    = ''
        'TppTokenScope' = ''
    }
    'New-VenafiTeam'                   = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=manage'
    }
    'Read-VenafiLog'                   = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'any scope'
    }
    'Remove-VdcCertificate'            = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'certificate=delete.  If using KeepAssociatedApps, configuration=$null,certificate=manage as well.'
    }
    'Remove-VdcCertificateAssociation' = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'certificate=manage.  If using -All, configuration=$null as well.'
    }
    'Remove-VdcClient'                 = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'agent=delete'
    }
    'Remove-VdcEngineFolder'           = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=delete'
    }
    'Remove-VdcObject'                 = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=delete'
    }
    'Remove-VdcPermission'             = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'security=delete'
    }
    'Remove-VenafiTeam'                = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=delete'
    }
    'Remove-VenafiTeamMember'          = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=manage'
    }
    'Remove-VenafiTeamOwner'           = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=manage'
    }
    'Rename-VdcObject'                 = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=manage'
    }
    'Revoke-VdcCertificate'            = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'certificate=revoke'
    }
    'Revoke-VdcGrant'                  = @{
        'TppVersion'    = '22.3'
        'TppTokenScope' = 'admin=delete'
    }
    'Revoke-VdcToken'                  = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'any scope'
    }
    'Search-VdcHistory'                = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'restricted=$null, certificate=$null'
    }
    'Set-VdcAttribute'                 = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=manage'
    }
    'Set-VdcCredential'                = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'security=manage'
    }
    'Set-VdcPermission'                = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'security=manage'
    }
    'Set-VdcWorkflowTicketStatus'      = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'approve with any scope'
    }
    'Test-VdcIdentity'                 = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=$null'
    }
    'Test-VdcObject'                   = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'configuration=$null'
    }
    'Test-VdcToken'                    = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'any scope'
    }
    'Write-VdcLog'                     = @{
        'TppVersion'    = ''
        'TppTokenScope' = 'any scope'
    }
}

