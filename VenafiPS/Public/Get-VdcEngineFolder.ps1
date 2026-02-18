function Get-VdcEngineFolder {
    <#
    .SYNOPSIS
    Get Certificate Manager, Self-Hosted folder/engine assignments

    .DESCRIPTION
    When the input is a policy folder, retrieves an array of assigned Certificate Manager, Self-Hosted processing engines.
    When the input is a Certificate Manager, Self-Hosted engine, retrieves an array of assigned policy folders.
    If there are no matching assignments, nothing will be returned.

    .PARAMETER ID
    The full DN path or Guid to a Certificate Manager, Self-Hosted processing engine or policy folder.

    .PARAMETER All
    Get all engine/folder assignments

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, Self-Hosted token can also be provided, but this requires an environment variable VDC_SERVER to be set.

    .INPUTS
    ID

    .OUTPUTS
    PSCustomObject

    .EXAMPLE
    Get-VdcEngineFolder -Path '\VED\Engines\MYVENSERVER'

    Get an array of policy folders assigned to the Certificate Manager, Self-Hosted processing engine 'MYVENSERVER'.

    .EXAMPLE
    Get-VdcEngineFolder -Path '\VED\Policy\Certificates\Web Team'

    Get an array of Certificate Manager, Self-Hosted processing engines assigned to the policy folder '\VED\Policy\Certificates\Web Team'.

    .EXAMPLE
    [guid]'866e1d59-d5d2-482a-b9e6-7bb657e0f416' | Get-VdcEngineFolder

    When the GUID is assigned to a Certificate Manager, Self-Hosted processing engine, returns an array of assigned policy folders.
    When the GUID is assigned to a policy folder, returns an array of assigned Certificate Manager, Self-Hosted processing engines.
    Otherwise nothing will be returned.

    .LINK
    https://venafi.github.io/VenafiPS/functions/Get-VdcEngineFolder/

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Get-VdcEngineFolder.ps1

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-GET-ProcessingEngines-Engine-eguid.php

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-GET-ProcessingEngines-Folder-fguid.php
    #>
    [CmdletBinding(DefaultParameterSetName = 'ID')]

    param (
        [Parameter(Mandatory, ParameterSetName = 'ID', ValueFromPipelineByPropertyName, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [Alias('EngineGuid', 'Guid', 'EnginePath', 'Path')]
        [String] $ID,

        [Parameter(ParameterSetName = 'All', Mandatory)]
        [switch] $All,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation
    }

    process {

        if ( $PSCmdlet.ParameterSetName -eq 'All' ) {
            Invoke-VenafiRestMethod -UriLeaf 'ProcessingEngines/' | Select-Object -ExpandProperty Engines -ErrorAction SilentlyContinue | Get-VdcEngineFolder
        } else {

            if ( [guid]::TryParse($ID, $([ref][guid]::Empty)) ) {
                $thisObject = Get-VdcObject -Guid $ID
            } else {
                $thisObject = Get-VdcObject -Path $ID
            }

            $thisObjectGuid = '{{{0}}}' -f $thisObject.Guid

            if ( $thisObject.TypeName -eq 'Venafi Platform' ) {

                # engine

                $response = Invoke-VenafiRestMethod -UriLeaf "ProcessingEngines/Engine/$thisObjectGuid" | Select-Object -ExpandProperty Folders -ErrorAction SilentlyContinue

                $response | Where-Object { $_.FolderGuid -ne $thisObjectGuid } | Select-Object FolderName,
                @{ 'n' = 'FolderPath'; 'e' = { $_.FolderDN } },
                @{ 'n' = 'FolderGuid'; 'e' = { $_.FolderGuid.Trim('{}') } },
                @{ 'n' = 'EngineName'; 'e' = { $thisObject.Name } },
                @{ 'n' = 'EnginePath'; 'e' = { $thisObject.Path } },
                @{ 'n' = 'EngineGuid'; 'e' = { $thisObject.Guid } }

            } elseif ( $thisObject.TypeName -eq 'Policy' ) {

                # policy folder

                $response = Invoke-VenafiRestMethod -UriLeaf "ProcessingEngines/Folder/$thisObjectGuid" | Select-Object -ExpandProperty Engines -ErrorAction SilentlyContinue

                $response | Select-Object EngineName,
                @{ 'n' = 'EnginePath'; 'e' = { $_.EngineDN } },
                @{ 'n' = 'EngineGuid'; 'e' = { $_.EngineGuid.Trim('{}') } },
                @{ 'n' = 'FolderName'; 'e' = { $thisObject.Name } },
                @{ 'n' = 'FolderPath'; 'e' = { $thisObject.Path } },
                @{ 'n' = 'FolderGuid'; 'e' = { $thisObject.Guid } }

            } else {
                throw ('Unsupported object type, {0}' -f $thisObject.TypeName)
            }
        }
    }
}


