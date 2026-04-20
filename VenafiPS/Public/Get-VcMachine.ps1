function Get-VcMachine {
    <#
    .SYNOPSIS
    Get machine details

    .DESCRIPTION
    Get machine details for 1 or all.

    .PARAMETER Machine
    Machine ID or name

    .PARAMETER All
    Get all machines

    .PARAMETER IncludeConnectionDetail
    Getting all machines does not include connection details.
    Use -IncludeConnectionDetail to add this to the output, but note it will require an additional API call for each machine and can take some time.
    Execute with PowerShell v7+ to run in parallel and speed things up.

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.

    .INPUTS
    Machine

    .EXAMPLE
    Get-VcMachine -Machine 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2'

    machineId              : cf7cfdc0-2b2a-11ee-9546-5136c4b21504
    companyId              : cf7cfdc0-2b2a-11ee-9546-5136c4b21504
    machineTypeId          : fc569b60-cf24-11ed-bdc6-77a4bac4cb50
    pluginId               : ff645e14-bd1a-11ed-a009-ce063932f86d
    integrationId          : cf7c8014-2b2a-11ee-9a03-fa8930555887
    machineName            : MyCitrix
    status                 : VERIFIED
    machineType            : Citrix ADC
    creationDate           : 7/25/2023 4:35:36 PM
    modificationDate       : 7/25/2023 4:35:36 PM
    machineIdentitiesCount : 0
    owningTeam             : 59920180-a3e2-11ec-8dcd-3fcbf84c7db1
    ownership              : @{owningTeams=System.Object[]}
    connectionDetails      : @{hostnameOrAddress=1.2.3.4; password=uYroVBk/KtuuujEbfFC/06wtkIrOga7N96JdFSEQFhhn7KPUEWA=;
                             username=ZLQlnciWsVp+qIUJQ8nYcAuHh55FxKdFsWhHVp7LLU+0y8aDp1pw==}

    Get a single machine by ID

    .EXAMPLE
    Get-VcMachine -Machine 'MyCitrix'

    Get a single machine by name.  The name is case sensitive.

    .EXAMPLE
    Get-VcMachine -All

    machineId              : cf7cfdc0-2b2a-11ee-9546-5136c4b21504
    companyId              : cf7cfdc0-2b2a-11ee-9546-5136c4b21504
    machineTypeId          : fc569b60-cf24-11ed-bdc6-77a4bac4cb50
    pluginId               : ff645e14-bd1a-11ed-a009-ce063932f86d
    integrationId          : cf7c8014-2b2a-11ee-9a03-fa8930555887
    machineName            : MyCitrix
    status                 : VERIFIED
    machineType            : Citrix ADC
    creationDate           : 7/25/2023 4:35:36 PM
    modificationDate       : 7/25/2023 4:35:36 PM
    machineIdentitiesCount : 0
    owningTeam             : 59920180-a3e2-11ec-8dcd-3fcbf84c7db1
    ownership              : @{owningTeams=System.Object[]}

    Get all machines.  Note the connection details are not included by default with -All.
    See -IncludeConnectionDetails if this is needed.

    .EXAMPLE
    Get-VcMachine -All -IncludeConnectionDetails

    machineId              : cf7cfdc0-2b2a-11ee-9546-5136c4b21504
    companyId              : cf7cfdc0-2b2a-11ee-9546-5136c4b21504
    machineTypeId          : fc569b60-cf24-11ed-bdc6-77a4bac4cb50
    pluginId               : ff645e14-bd1a-11ed-a009-ce063932f86d
    integrationId          : cf7c8014-2b2a-11ee-9a03-fa8930555887
    machineName            : MyCitrix
    status                 : VERIFIED
    machineType            : Citrix ADC
    creationDate           : 7/25/2023 4:35:36 PM
    modificationDate       : 7/25/2023 4:35:36 PM
    machineIdentitiesCount : 0
    owningTeam             : 59920180-a3e2-11ec-8dcd-3fcbf84c7db1
    ownership              : @{owningTeams=System.Object[]}
    connectionDetails      : @{hostnameOrAddress=1.2.3.4; password=uYroVBk/KtuuujEbfFC/06wtkIrOga7N96JdFSEQFhhn7KPUEWA=;
                             username=ZLQlnciWsVp+qIUJQ8nYcAuHh55FxKdFsWhHVp7LLU+0y8aDp1pw==}

    Get all machines and include the connection details.
    Getting connection details will require an additional API call for each machine and can take some time.
    Use PowerShell v7+ to perform this in parallel and speed things up.

    #>

    [CmdletBinding(DefaultParameterSetName = 'ID')]

    param (

        [Parameter(Mandatory, ParameterSetName = 'ID', ValueFromPipelineByPropertyName, Position = 0)]
        [Alias('machineId', 'ID')]
        [string] $Machine,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch] $All,

        [Parameter(ParameterSetName = 'All')]
        [switch] $IncludeConnectionDetail,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient = (Get-TrustClient)
    )

    begin {
    }

    process {

        if ( $PSCmdlet.ParameterSetName -eq 'All' ) {

            $allMachines = Find-VcObject -Type Machine -TrustClient $TrustClient

            if ( $IncludeConnectionDetail ) {
                $params = @{
                    InputObject   = $allMachines
                    ScriptBlock   = { $PSItem | Get-VcMachine }
                    TrustClient = $TrustClient
                }
                return Invoke-TrustParallel @params
            }
            else {
                return $allMachines
            }
        }
        else {
            $mId = Get-VcData -Type Machine -InputObject $Machine
            if ( $mId ) {
                try {
                    $response = Invoke-TrustRestMethod -UriLeaf ('machines/{0}' -f $mId) -TrustClient $TrustClient
                    $response | Select-Object @{ 'n' = 'machineId'; 'e' = { $_.Id } }, * -ExcludeProperty Id
                }
                catch {
                    if ( $_.Exception.Response.StatusCode.value__ -eq 404 ) {
                        # not found, return nothing
                        return
                    }
                    else {
                        throw $_
                    }
                }
            }
        }
    }
}


