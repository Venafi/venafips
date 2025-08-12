function New-VcCloudKeystore {
    <#
    .SYNOPSIS
    Create a new cloud provider

    .DESCRIPTION
    Create a new cloud provider for either AWS, Azure, or GCP

    .PARAMETER Name
    Cloud provider name

    .PARAMETER OwnerTeam
    ID or name of owning team.
    The Owning Team is responsible for the administration, management, and control of a designated cloud provider, with the authority to update, modify, and delete cloud provider resources.

    .PARAMETER AuthorizedTeam
    1 or more IDs or names of authorized teams.
    Authorized teams are granted permission to use specific resources of a cloud provider. Although team members can perform tasks like creating a keystore, their permissions may be limited regarding broader modifications to the provider's configuration. Unlike the Owning Team, users may not have the authority to update and delete Cloud Providers.

    .PARAMETER GCP
    Create a GCP cloud provider.
    Details can be found at https://docs.venafi.cloud/vaas/integrations/gcp/gcp/.

    .PARAMETER ServiceAccountEmail
    Service account email address.
    Provide for GCP connections with either Workload Identity Federation or Venafi Generated Key.
    Venafi Generated Key, https://docs.venafi.cloud/vaas/integrations/gcp/gcp-serviceaccount/
    Workload Identity Federation, https://docs.venafi.cloud/vaas/integrations/gcp/gcp-workload-identity/

    .PARAMETER ProjectNumber
    GCP project number, needed for WIF

    .PARAMETER PoolID
    Workload Identity Pool ID, located in the GCP Workload Identity Federation section
    This must be 4 to 32 lowercase letters, digits, or hyphens.

    .PARAMETER PoolProviderID
    Unique, meaningful name related to this specific cloud provider, such as venafi-provider.
    This will be created.
    This must be 4 to 32 lowercase letters, digits, or hyphens.

    .PARAMETER Azure
    Create a Azure cloud provider
    Details can be found at https://docs.venafi.cloud/vaas/integrations/azure/azure-key-vault/

    .PARAMETER ApplicationID
    Active Directory Application (client) Id. The client Id is the unique identifier of an application created in Active Directory. You can have many applications in an Active Directory and each application will have a different access levels.

    .PARAMETER DirectoryID
    Unique identifier of the Azure Active Directory instance. One subscription can have multiple tenants. Using this Tenant Id you register and manage your apps.

    .PARAMETER ClientSecret
    Credential that is used to authenticate and authorize a client application when it interacts with Azure services.

    .PARAMETER AWS
    Create a AWS cloud provider
    Details can be found at https://docs.venafi.cloud/vaas/integrations/Aws/aws-acm/

    .PARAMETER AccountID
    12 digit AWS Account ID

    .PARAMETER IamRoleName
    Role name, to be created, that carries significance and can be readily linked to this specific cloud provider

    .PARAMETER Validate
    Invoke cloud provider validation once created.
    If using -PassThru, the validation result will be provided with the new cloud provider details.

    .PARAMETER PassThru
    Return newly created cloud provider object

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A TLSPC key can also provided.

    .OUTPUTS
    PSCustomObject, if PassThru provided

    .EXAMPLE
    New-VcCloudProvider -Name 'MyGCP' -OwnerTeam 'SpecialTeam' -GCP -ServiceAccountEmail 'greg-brownstein@my-secret-project.iam.gserviceaccount.com'

    Create a new GCP Venafi Generated Key provider

    .EXAMPLE
    New-VcCloudProvider -Name 'MyGCP' -OwnerTeam 'SpecialTeam' -GCP -ServiceAccountEmail 'greg-brownstein@my-secret-project.iam.gserviceaccount.com' -ProjectNumber 12345 -PoolID hithere -PoolProviderID blahblah1

    Create a new GCP Workload Identity Foundation provider

    .EXAMPLE
    New-VcCloudProvider -Name 'MyAzure' -OwnerTeam 'SpecialTeam' -Azure -ApplicationID '5e256486-ef8f-443f-84ad-221a7ac1d52e' -DirectoryID '45f2133f-8317-44d5-9813-ed08bf92eb7b' -ClientSecret 'youllneverguess'

    Create a new Azure provider

    .EXAMPLE
    New-VcCloudProvider -Name 'MyAWS' -OwnerTeam 'SpecialTeam' -AWS -AccountID 123456789012 -IamRoleName 'TlspcIntegrationRole'

    Create a new AWS provider

    .EXAMPLE
    New-VcCloudProvider -Name 'MyAWS' -OwnerTeam 'SpecialTeam' -AWS -AccountID 123456789012 -IamRoleName 'TlspcIntegrationRole' -Validate

    Create a new provider and validate once created

    .EXAMPLE
    New-VcCloudProvider -Name 'MyAWS' -OwnerTeam 'SpecialTeam' -AWS -AccountID 123456789012 -IamRoleName 'TlspcIntegrationRole' -PassThru

    Create a new provider and provide the details of the new object

    #>

    [CmdletBinding(SupportsShouldProcess)]

    param (
        [Parameter(Mandatory, ParameterSetName = 'GCM')]
        [Parameter(Mandatory, ParameterSetName = 'AKV')]
        [Parameter(Mandatory, ParameterSetName = 'ACM')]
        [ValidateNotNullOrEmpty()]
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
                    scheduleSpecification      = $null
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

