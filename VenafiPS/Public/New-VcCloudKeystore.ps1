function New-VcCloudKeystore {
    <#
    .SYNOPSIS
    Create a new cloud keystore

    .DESCRIPTION
    Create a new cloud keystore

    .PARAMETER CloudProvider
    Cloud provider ID or name

    .PARAMETER Name
    Cloud keystore name

    .PARAMETER OwnerTeam
    ID or name of owning team.
    The Owning Team is responsible for the administration, management, and control of a designated cloud keystore, with the authority to update, modify, and delete cloud keystore resources.

    .PARAMETER AuthorizedTeam
    1 or more IDs or names of authorized teams.
    Authorized teams are granted permission to use specific resources of a cloud keystore.
    Although team members can perform tasks like creating a keystore, their permissions may be limited regarding broader modifications to the keystore's configuration.
    Unlike the Owning Team, users may not have the authority to update and delete Cloud Keystores.

    .PARAMETER GCM
    Create a GCM cloud keystore.
    Details can be found at https://docs.venafi.cloud/vaas/installations/cloud-keystores/add-cloud-keystore-google/

    .PARAMETER Location
    GCM region, default is 'global'

    .PARAMETER ProjectID
    GCM Project ID

    .PARAMETER AKV
    Create a Azure KeyVault keystore
    Details can be found at https://docs.venafi.cloud/vaas/installations/cloud-keystores/add-cloud-keystore-azure/

    .PARAMETER KeyVaultName
    Azure KeyVault name

    .PARAMETER ACM
    Create a ACM cloud keystore
    Details can be found at https://docs.venafi.cloud/vaas/installations/cloud-keystores/add-cloud-keystore-aws/

    .PARAMETER Region
    ACM region

    .PARAMETER IncludeExpiredCertificates
    Provide this switch to include expired certificates when discovery is run

    .PARAMETER DiscoverySchedule
    A crontab expression representing when the discovery will run, eg. 0 0 * * *, run daily at 12a

    .PARAMETER PassThru
    Return newly created cloud keystore object

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A TLSPC key can also provided.

    .OUTPUTS
    PSCustomObject, if PassThru provided

    .EXAMPLE
    New-VcCloudKeystore -CloudProvider 'MyGCP' -Name 'MyGCM' -OwnerTeam 'SpecialTeam' -GCM -ProjectID 'woot1'

    Create a new GCM keystore

    .EXAMPLE
    New-VcCloudKeystore -CloudProvider 'MyAzure' -Name 'MyAKV' -OwnerTeam 'SpecialTeam' -AKV -KeyVaultName 'thisisakeyvault'

    Create a new AKV keystore

    .EXAMPLE
    New-VcCloudKeystore -CloudProvider 'MyAWS' -Name 'MyACM' -OwnerTeam 'SpecialTeam' -ACM -Region 'us-east-1'

    Create a new ACM keystore

    .EXAMPLE
    New-VcCloudKeystore -CloudProvider 'MyAWS' -Name 'MyACM' -OwnerTeam 'SpecialTeam' -ACM -Region 'us-east-1' -IncludeExpiredCertificates

    Create a new keystore and include expired certificates during discovery

    .EXAMPLE
    New-VcCloudKeystore -CloudProvider 'MyAWS' -Name 'MyACM' -OwnerTeam 'SpecialTeam' -ACM -Region 'us-east-1' -PassThru

    Create a new keystore and provide the details of the new object

    #>

    [CmdletBinding(SupportsShouldProcess)]

    param (
        [Parameter(Mandatory, ParameterSetName = 'GCM')]
        [Parameter(Mandatory, ParameterSetName = 'AKV')]
        [Parameter(Mandatory, ParameterSetName = 'ACM')]
        [ValidateNotNullOrEmpty()]
        [Alias('cloudProviderId', 'cp')]
        [string] $CloudProvider,

        [Parameter(Mandatory, ParameterSetName = 'GCM')]
        [Parameter(Mandatory, ParameterSetName = 'AKV')]
        [Parameter(Mandatory, ParameterSetName = 'ACM')]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $OwnerTeam,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]] $AuthorizedTeam,

        [Parameter(Mandatory, ParameterSetName = 'GCM')]
        [switch] $GCM,

        [Parameter(ParameterSetName = 'GCM')]
        [ValidateNotNullOrEmpty()]
        [string] $Location = 'global',

        [Parameter(Mandatory, ParameterSetName = 'GCM')]
        [ValidateNotNullOrEmpty()]
        [string] $ProjectID,

        [Parameter(Mandatory, ParameterSetName = 'AKV')]
        [switch] $AKV,

        [Parameter(Mandatory, ParameterSetName = 'AKV')]
        [string] $KeyVaultName,

        [Parameter(Mandatory, ParameterSetName = 'ACM')]
        [switch] $ACM,

        [Parameter(Mandatory, ParameterSetName = 'ACM')]
        [string] $Region,

        [Parameter()]
        [switch] $IncludeExpiredCertificates,

        [Parameter()]
        [string] $DiscoverySchedule = $null,

        [Parameter()]
        [switch] $PassThru,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {

        Test-VenafiSession $PSCmdlet.MyInvocation

        $ownerId = Get-VcData -Type Team -InputObject $OwnerTeam

        $query = 'mutation CreateNewCloudKeystore($input: CloudKeystoreInput!) {
                    createCloudKeystore(input: $input) {
                        ...CloudKeystoresList_NewAcmCloudKeystoreWizard
                    }
                    }

                    fragment CloudKeystoresList_NewAcmCloudKeystoreWizard on CloudKeystore {
                    id
                    name
                    team {
                        id
                        name
                    }
                    authorizedTeams {
                        id
                        name
                    }
                    configuration {
                        ...CloudKeystoresList_CloudKeystoreACMConfiguration
                    }
                    discovery {
                        id
                        status
                        statusDetails
                        totalCertificatesCount
                        missingCertificatesCount
                        updatedCertificatesCount
                        newCertificatesCount
                        startedBy {
                        username
                        }
                        startTime
                        endTime
                    }
                    }

                    fragment CloudKeystoresList_CloudKeystoreACMConfiguration on CloudKeystoreACMConfiguration {
                    accountId
                    region
                    }
                '
    }

    process {

        $variables = @{
            'input' = @{
                name                   = $Name
                teamId                 = $ownerId
                type                   = $PSCmdlet.ParameterSetName
                authorizedTeams        = @()
                cloudProviderId        = $CloudProvider | Get-VcData -Type CloudProvider
                discoveryConfiguration = @{
                    includeExpiredCertificates = $IncludeExpiredCertificates.IsPresent
                    includeRevokedCertificates = $false
                    scheduleSpecification      = $DiscoverySchedule
                }
            }
        }

        if ( $PSBoundParameters.ContainsKey('AuthorizedTeam') ) {
            $variables.input.authorizedTeams = @($AuthorizedTeam | Get-VcData -Type Team)
        }

        switch ($PSCmdlet.ParameterSetName) {
            'GCM' {
                $variables.input.gcmConfiguration = @{
                    location  = $Location
                    projectId = $ProjectID

                }
            }

            'AKV' {
                $variables.input.akvConfiguration = @{
                    keyVaultName = $KeyVaultName
                }
            }

            'ACM' {
                $variables.input.acmConfiguration = @{
                    region = $Region
                }
            }
        }

        if ( $PSCmdlet.ShouldProcess($Name, ('Create {0} cloud keystore' -f $variables.input.type)) ) {

            $response = Invoke-VcGraphQL -Query $query -Variables $variables | Select-Object -ExpandProperty createCloudKeystore

            if ( $PassThru ) {
                $response
            }
        }
    }
}

