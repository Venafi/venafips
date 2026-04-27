# Force TLS 1.2 if currently set lower
if ([Net.ServicePointManager]::SecurityProtocol.value__ -lt 3072) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

# the new version will be replaced below during deployment
$script:ModuleVersion = '((NEW_VERSION))'

$script:TrustClient = $null
# Don't check at load time, check when needed via Get-ThreadJobAvailability
$script:ThreadJobAvailable = $null
$script:ParallelImportPath = $PSCommandPath

# ModuleVersion will get updated during the build and this will not run
# this is only needed during development since all files will be merged into one psm1
if ( $script:ModuleVersion -like '*NEW_VERSION*' ) {
    $folders = @('Enum', 'Classes', 'Private', 'Public')
    $publicFunction = @()

    foreach ( $folder in $folders) {

        $files = Get-ChildItem -Path "$PSScriptRoot\$folder\*.ps1" -Recurse

        Foreach ( $thisFile in $files ) {
            Try {
                Write-Verbose ('dot sourcing {0}' -f $thisFile.FullName)
                . $thisFile.fullname
                Export-ModuleMember -Function $thisFile.Basename
                $publicFunction += $thisFile.BaseName
            }
            Catch {
                Write-Error ("Failed to import function {0}: {1}" -f $thisFile.fullname, $folder)
            }
        }
    }
}

Export-ModuleMember -Alias * -Variable TrustClient -Function *

# do not load if a bypass argument is passed in, eg. Invoke-TrustParallel
# the argument completers are not needed in this case
if (-not $args[0]) {

    # a wildcard for Register-ArgumentCompleter -CommandName doesn't work so we need to get the command names to register against
    $manifest = Import-PowerShellDataFile "$PSScriptRoot/VenafiPS.psd1"
    $vcCommands = $manifest.FunctionsToExport | Where-Object { $_ -like '*-Trust*' }
    $vdcCommands = $manifest.FunctionsToExport | Where-Object { $_ -like '*-Vdc*' }

    # define the argument completer details
    # d = description, required
    # l = lookup, required if lookup value is different than 'name'
    $vcCompletions = @{
        'CloudKeystore'   = @{
            'd' = { 'type: {0}, provider: {1}' -f $_.type, $_.cloudProvider.name }
        }
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
                    $script:vcMachineType = Invoke-TrustRestMethod -UriLeaf 'plugins?pluginTypes=MACHINE' |
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
                    Find-TrustCertificate -Name $wordToComplete | ForEach-Object { "'$($_.certificateName)'" }
                }
            }

            default {
                # catch all for $vcCompletions
                Get-TrustData -Type $parameterName | Where-Object $lookup -like ('{0}*' -f $wordToComplete.Trim("'")) | ForEach-Object {
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
    'Path', 'CertificateAuthorityPath', 'CredentialPath', 'CertificatePath', 'ApplicationPath', 'EnginePath', 'CertificateLinkPath', 'NewPath' | ForEach-Object {
        Register-ArgumentCompleter -CommandName $vdcCommands -ParameterName $_ -ScriptBlock $vdcPathArgCompleterSb
    }

    $vcLogArgCompleterSb = {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

        if ( -not $script:vcActivityType ) {
            $script:vcActivityType = Invoke-TrustRestMethod -UriLeaf 'activitytypes' |
                Select-Object -Property @{'n' = 'type'; 'e' = { $_.key } }, @{'n' = 'name'; 'e' = { $_.values.key } } -ExcludeProperty readableName |
                Sort-Object -Property type
        }

        switch ($parameterName) {
            'EventType' {
                $script:vcActivityType | Where-Object type -like ('{0}*' -f $wordToComplete.Trim("'")) | ForEach-Object {
                    $itemText = "'{0}'" -f $_.type
                    $itemDescription = 'activity names: {0}' -f ($_.name -join ', ')
                    [System.Management.Automation.CompletionResult]::new($itemText, $itemText, 'ParameterValue', $itemDescription)
                }
            }

            'EventName' {
                # If Type is provided, filter names for that type only
                if ($fakeBoundParameters.ContainsKey('EventType')) {
                    $typeValue = $fakeBoundParameters['EventType'].Trim("'")
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
    Register-ArgumentCompleter -CommandName 'Find-TrustLog', 'New-TrustWebhook' -ParameterName 'EventType' -ScriptBlock $vcLogArgCompleterSb
    Register-ArgumentCompleter -CommandName 'Find-TrustLog', 'New-TrustWebhook' -ParameterName 'EventName' -ScriptBlock $vcLogArgCompleterSb

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
}