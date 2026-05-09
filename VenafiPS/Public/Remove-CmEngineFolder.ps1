function Remove-CmEngineFolder {
    <#
    .SYNOPSIS
    Remove Certificate Manager, Self-Hosted processing engine assignment(s) from policy folder(s)

    .DESCRIPTION
    Remove Certificate Manager, Self-Hosted processing engine assignment(s) from policy folder(s).

    If you do not supply a list of Certificate Manager, Self-Hosted processing engines, then all processing engines will be removed from the supplied list of policy folders.

    If you do not supply a list of policy folders, then all policy folder assignments will be removed from the supplied list of processing engines.

    Supplying both a list of policy folders and processing engines will result in the removal of the specified engines from the list of policy folders.

    Errors due to a policy engine not being assigned to the listed policy folder are ignored.

    .PARAMETER FolderPath
    The full DN path to one or more policy folders (string array).
    .PARAMETER EnginePath
    The full DN path to one or more Certificate Manager, Self-Hosted processing engines (string array).
    .PARAMETER Force
    Suppress the confirmation prompt before removing engine/folder assignments.
    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.
    .INPUTS
    FolderPath[], EnginePath[]
    .OUTPUTS
    None
    .EXAMPLE
    Remove-CmEngineFolder -FolderPath '\VED\Policy\Certificates\Web Team' -EnginePath @('\VED\Engines\MYVENAFI01','\VED\Engines\MYVENAFI02')
    Remove policy folder '\VED\Policy\Certificates\Web Team' from the processing engines MYVENAFI01 and MYVENAFI02.
    .EXAMPLE
    Remove-CmEngineFolder -FolderPath @('\VED\Policy\Certificates\Web Team','\VED\Policy\Certificates\Database Team')
    Remove all processing engine assignments for the policy folders '\VED\Policy\Certificates\Web Team' and '\VED\Policy\Certificates\Database Team'.
    .EXAMPLE
    Remove-CmEngineFolder -EnginePath @('\VED\Engines\MYVENAFI01','\VED\Engines\MYVENAFI02') -Confirm:$false
    Removed all policy folder assignments from the processing engines MYVENAFI01 and MYVENAFI02. Suppress the confirmation prompt.
    .LINK
    https://venafi.github.io/VenafiPS/functions/Remove-CmEngineFolder/
    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Remove-CmEngineFolder.ps1
    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-DELETE-ProcessingEngines-Folder-fguid.php
    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-DELETE-ProcessingEngines-Folder-fguid-eguid.php
    #>

    [Alias('Remove-VdcEngineFolder')]
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]

    param (
        [Parameter(Mandatory, ParameterSetName = 'AllEngines', ValueFromPipelineByPropertyName)]
        [Parameter(Mandatory, ParameterSetName = 'Matrix', ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if ( $_ | Test-CmDnPath ) { $true }
                else { throw "'$_' is not a valid DN path" }
            })]
        [Alias('FolderDN', 'Folder')]
        [String[]] $FolderPath,

        [Parameter(Mandatory, ParameterSetName = 'AllFolders', ValueFromPipelineByPropertyName)]
        [Parameter(Mandatory, ParameterSetName = 'Matrix', ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if ( $_ | Test-CmDnPath ) { $true }
                else { throw "'$_' is not a valid DN path" }
            })]
        [Alias('EngineDN', 'Engine')]
        [String[]] $EnginePath,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient
    )

    begin {

        $params = @{

            Method        = 'Delete'
        }

        $apiCall = "ProcessingEngines/Folder"
    }

    process {
        if ($FolderPath) {
            [CmObject[]] $FolderList = @()
            foreach ($path in $FolderPath) {
                try {
                    $folder = Get-CmObject -Path $path
                    if ($folder.TypeName -eq 'Policy') {
                        $FolderList += $folder
                    }
                    else {
                        Write-Warning ("Certificate Manager, Self-Hosted object '$($path)' is not a policy ($($folder.TypeName))")
                        Continue
                    }
                }
                catch {
                    Write-Warning ("Certificate Manager, Self-Hosted object '$($path)' does not exist")
                    Continue
                }
            }
            if ($FolderList.Count -eq 0) {
                Write-Warning "All supplied policy folders are invalid"
                Return
            }
        }

        if ($EnginePath) {
            [CmObject[]] $EngineList = @()
            foreach ($path in $EnginePath) {
                try {
                    $engine = Get-CmObject -Path $path
                    if ($engine.TypeName -eq 'Venafi Platform') {
                        $EngineList += $engine
                    }
                    else {
                        Write-Warning ("Certificate Manager, Self-Hosted object '$($path)' is not an engine ($($engine.TypeName))")
                        Continue
                    }
                }
                catch {
                    Write-Warning ("Certificate Manager, Self-Hosted object '$($path)' does not exist")
                    Continue
                }
            }
            if ($EngineList.Count -eq 0) {
                Write-Warning "All supplied processing engines are invalid"
                Return
            }
        }

        if ($PSCmdlet.ParameterSetName -eq 'AllEngines') {
            $shouldProcessAction = "Remove ALL processing engine assignments"
            if ($FolderList.Count -gt 1) { $shouldProcessTarget = "$($FolderList.Count) folders" }
            else { $shouldProcessTarget = "$($FolderList.Path)" }
            if ($PSCmdlet.ShouldProcess($shouldProcessTarget, $shouldProcessAction)) {
                foreach ($folder in $FolderList) {
                    $uriLeaf = "$($apiCall)/{$($folder.Guid)}"
                    try {
                        $null = Invoke-TrustRestMethod @params -UriLeaf $uriLeaf
                    }
                    catch {
                        $myError = $_.ToString() | ConvertFrom-Json
                        Write-Warning ("Error removing processing engines from folder policy '$($folder.Path)': $($myError.Error)")
                    }
                }
            }
        }
        else {
            if ($PSCmdlet.ParameterSetName -eq 'AllFolders') {
                $shouldProcessAction = "Remove ALL policy folder assignments"
                if ($EngineList.Count -gt 1) { $shouldProcessTarget = "$($EngineList.Count) processing engines" }
                else { $shouldProcessTarget = "$($EngineList.Name)" }
            }
            else {
                # ParameterSetName='Matrix'
                if ($FolderList.Count -gt 1) { $shouldProcessAction += "Remove $($FolderList.Count) folders" }
                else { $shouldProcessAction = "Remove $($FolderList.Path)" }
                if ($EngineList.Count -gt 1) { $shouldProcessTarget = "$($EngineList.Count) processing engines" }
                else { $shouldProcessTarget = "$($EngineList.Name)" }
            }
            if ($PSCmdlet.ShouldProcess($shouldProcessTarget, $shouldProcessAction)) {
                foreach ($engine in $EngineList) {
                    Write-Verbose ("Processing Engine: '$($engine.Path)'")
                    if ($PSCmdlet.ParameterSetName -eq 'AllFolders') {
                        [CmObject[]] $FolderList = @()
                        $FolderList += ($engine | Get-CmEngineFolder)
                        Switch ($FolderList.Count) {
                            0 { $countMessage = 'NO folders' }
                            1 { $countMessage = '1 folder' }
                            Default { $countMessage = "$($_) folders" }
                        }
                        Write-Verbose "Found $($countMessage) to remove from engine '$($engine.Name)'"
                    }
                    foreach ($folder in $FolderList) {
                        $uriLeaf = "$($apiCall)/{$($folder.Guid)}/{$($engine.Guid)}"
                        try {
                            $null = Invoke-TrustRestMethod @params -UriLeaf $uriLeaf
                        }
                        catch {
                            $myError = $_.ToString() | ConvertFrom-Json
                            Write-Warning ("Error removing engine '$($engine.Path)' from folder policy '$($folder.Path)': $($myError.Error)")
                        }
                    }
                }
            }
        }
    }
}


