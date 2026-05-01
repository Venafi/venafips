function Set-TrustMachine {
    <#
    .SYNOPSIS
    Update an existing machine settings

    .DESCRIPTION
    Update an existing machine settings, including name, connection details, and satellite.

    .PARAMETER Machine
    Machine ID or name

    .PARAMETER Name
    New machine name to update to

    .PARAMETER ConnectionDetail
    Connection details to update.  This should be a hashtable with the same structure as the connectionDetails object returned by Get-TrustMachine.  You can provide a partial hashtable with just
    the values you want to update.  See the example below for details.

    .PARAMETER Satellite
    New Satellite name or ID

    .PARAMETER PassThru
    Return the updated machine object

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.

    .INPUTS
    Machine

    .EXAMPLE
    Set-TrustMachine -Machine GregIIS -Name GregIIS2

    Update the name of a machine

    .EXAMPLE
    Set-TrustMachine -Machine GregIIS -Satellite 'My New Satellite'

    Update the satellite of a machine

    .EXAMPLE
    Get-TrustMachine -Machine GregIIS | Select-Object -ExpandProperty connectionDetails

    The current connection details of a machine will be shown.  For example, let's say it shows the following:
        authenticationType : kerberos
        credentialType     : local
        hostnameOrAddress  : greg.paloaltonetworks.com
        https              : False
        kerberos           : @{domain=mydomain.paloaltonetworks.com; keyDistributionCenter=ad.mydomain.paloaltonetworks.com; servicePrincipalName=WSMAN/greg.paloaltonetworks.com}

    If you want to update the key distribution center, you can run the following command:

    Set-TrustMachine -Machine GregIIS -ConnectionDetail @{ 'kerberos' = @{ 'keyDistributionCenter' = 'new value' } }

    This will update just the key distribution center value while leaving the rest of the connection details the same.

    .EXAMPLE
    Set-TrustMachine -Machine GregIIS -ConnectionDetail @{ 'kerberos' = @{ 'keyDistributionCenter' = 'new value' } } -PassThru

    Update a machine and return the updated machine object with the new connection details

    .EXAMPLE
    Set-TrustMachine -Machine GregIIS -ConnectionDetail @{ 'kerberos' = @{ 'keyDistributionCenter' = 'new value' } } | Invoke-TrustWorkflow -Workflow 'Test'

    Update a machine connection detail and then test the connection with the Test workflow.  Note that the workflow will use the updated connection details.
    #>

    [CmdletBinding(SupportsShouldProcess)]
    [Alias('Set-VcMachine')]

    param (

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('machineId')]
        [string] $Machine,

        [Parameter()]
        [string] $Name,

        [Parameter()]
        [hashtable] $ConnectionDetail,

        [Parameter()]
        [string] $Satellite,

        [Parameter()]
        [switch] $PassThru,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient
    )

    begin {

        if ( $Satellite ) {
            $satelliteId = Get-TrustData -Type VSatellite -InputObject $Satellite -FailOnNotFound
        }
    }

    process {

        # use Get-TrustMachine as opposed to Get-TrustData as the latter doesn't return all machine details, eg. connection details
        $thisMachine = Get-TrustMachine -Machine $Machine

        if ( -not $thisMachine ) {
            Write-Error "Machine '$Machine' not found."
            return
        }

        $params = @{
            Method  = 'Patch'
            UriLeaf = "machines/$($thisMachine.machineId)"
        }

        $body = @{}

        switch ($PSBoundParameters.Keys) {
            'Name' {
                $body.name = $Name
            }

            'ConnectionDetail' {
                $currentDetail = @{}

                # get existing connection details and update with provided values as opposed to requiring the whole object be provided
                if ( $thisMachine.connectionDetails ) {
                    $thisMachine.connectionDetails.PSObject.Properties | ForEach-Object {
                        if ( $_.Value -is [System.Management.Automation.PSCustomObject] ) {
                            $nested = @{}
                            $_.Value.PSObject.Properties | ForEach-Object {
                                $nested[$_.Name] = $_.Value
                            }
                            $currentDetail[$_.Name] = $nested
                        }
                        else {
                            $currentDetail[$_.Name] = $_.Value
                        }
                    }
                }

                foreach ( $key in $ConnectionDetail.Keys ) {
                    if ( $ConnectionDetail[$key] -is [hashtable] -and $currentDetail.ContainsKey($key) -and $currentDetail[$key] -is [hashtable] ) {
                        foreach ( $nestedKey in $ConnectionDetail[$key].Keys ) {
                            $currentDetail[$key][$nestedKey] = $ConnectionDetail[$key][$nestedKey]
                        }
                    }
                    else {
                        $currentDetail[$key] = $ConnectionDetail[$key]
                    }
                }

                $body.connectionDetails = $currentDetail
            }

            'Satellite' {
                if ( $satelliteId ) {
                    $body.edgeInstanceId = $satelliteId
                }
            }
        }

        if ( $body.Count -eq 0 ) {
            Write-Error "No updates provided. Please specify at least one property to update."
            return
        }

        $params.Body = $body

        if ( $PSCmdlet.ShouldProcess($thisMachine.name, 'Update machine') ) {
            $response = Invoke-TrustRestMethod @params

            if ( $PassThru -and $response ) {
                $response | Get-TrustMachine
            }
        }
    }
}