function Get-VcMachineIdentity {
    <#
    .SYNOPSIS
    Get machine identities

    .DESCRIPTION
    Get 1 or all machine identities

    .PARAMETER ID
    Machine identity ID

    .PARAMETER All
    Get all machine identities

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, SaaS key can also provided.

    .INPUTS
    ID

    .EXAMPLE
    Get-VcMachineIdentity -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2'

    machineIdentityId : cc57e830-1a90-11ee-abe7-bda0c823b1ad
    companyId         : cc57e830-1a90-11ee-abe7-bda0c823b1ad
    machineId         : 5995ecf0-19ca-11ee-9386-3ba941243b67
    certificateId     : cc535450-1a90-11ee-8774-3d248c9b48c5
    status            : DISCOVERED
    creationDate      : 7/4/2023 1:32:50 PM
    lastSeenOn        : 7/4/2023 1:32:50 PM
    modificationDate  : 7/4/2023 1:32:50 PM
    keystore          : @{friendlyName=1.test.net; keystoreCapiStore=my; privateKeyIsExportable=False}
    binding           : @{createBinding=False; port=40112; siteName=domain.io}

    Get a single machine identity by ID

    .EXAMPLE
    Get-VcMachineIdentity -All

    Get all machine identities

    #>

    [CmdletBinding(DefaultParameterSetName = 'ID')]

    param (

        [Parameter(Mandatory, ParameterSetName = 'ID', ValueFromPipelineByPropertyName, Position = 0)]
        [Alias('machineIdentityId')]
        [ValidateScript(
            {
                if ( Test-IsGuid($_) ) { $true } else { throw '-ID must be a uuid/guid' }
            }
        )]
        [string] $ID,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch] $All,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession = (Get-VenafiSession)
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation
    }

    process {

        if ( $PSCmdlet.ParameterSetName -eq 'All' ) {

            $params = @{
                InputObject   = Find-VcObject -Type MachineIdentity -VenafiSession $VenafiSession
                ScriptBlock   = {
                    $PSItem | Get-VcMachineIdentity
                }
                VenafiSession = $VenafiSession
            }
            Invoke-VenafiParallel @params
        }
        else {
            try {
                $response = Invoke-VenafiRestMethod -UriLeaf ('machineidentities/{0}' -f $ID) -VenafiSession $VenafiSession
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

            if ( $response ) {
                $response | Select-Object @{ 'n' = 'machineIdentityId'; 'e' = { $_.Id } },
                @{
                    'n' = 'certificateValidityEnd'
                    'e' = { Get-VcCertificate -CertificateID $_.certificateId -VenafiSession $VenafiSession | Select-Object -ExpandProperty validityEnd }
                }, * -ExcludeProperty Id
            }
        }
    }
}


