function New-VcCloudProvider {
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
        [Parameter(Mandatory, ParameterSetName = 'GCP-Venafi')]
        [Parameter(Mandatory, ParameterSetName = 'GCP-WIF')]
        [Parameter(Mandatory, ParameterSetName = 'AZURE')]
        [Parameter(Mandatory, ParameterSetName = 'AWS')]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $OwnerTeam,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]] $AuthorizedTeam,

        [Parameter(Mandatory, ParameterSetName = 'GCP-Venafi')]
        [Parameter(Mandatory, ParameterSetName = 'GCP-WIF')]
        [switch] $GCP,

        [Parameter(Mandatory, ParameterSetName = 'GCP-Venafi')]
        [Parameter(Mandatory, ParameterSetName = 'GCP-WIF')]
        [ValidateNotNullOrEmpty()]
        [string] $ServiceAccountEmail,

        [Parameter(Mandatory, ParameterSetName = 'GCP-WIF')]
        [ValidateLength(4, 64)]
        [string] $ProjectNumber,

        [Parameter(Mandatory, ParameterSetName = 'GCP-WIF')]
        [ValidateScript(
            {
                if ( $_ -match '^[a-z0-9-]{4,32}$') {
                    $true
                }
                else {
                    throw 'PoolID can only have lowercase letters, digits, hyphens and must be between 4 - 32 characters'
                }
            }
        )]
        [string] $PoolID,

        [Parameter(Mandatory, ParameterSetName = 'GCP-WIF')]
        [ValidateScript(
            {
                if ( $_ -match '^[a-z0-9-]{4,32}$') {
                    $true
                }
                else {
                    throw 'PoolProviderID can only have lowercase letters, digits, hyphens and must be between 4 - 32 characters'
                }
            }
        )]
        [string] $PoolProviderID,

        [Parameter(Mandatory, ParameterSetName = 'AZURE')]
        [switch] $Azure,

        [Parameter(Mandatory, ParameterSetName = 'AZURE')]
        [ValidateScript(
            {
                if ( Test-IsGuid($_) ) { $true } else { throw '-ApplicationID must be a uuid/guid' }
            }
        )]
        [string] $ApplicationID,

        [Parameter(Mandatory, ParameterSetName = 'AZURE')]
        [ValidateScript(
            {
                if ( Test-IsGuid($_) ) { $true } else { throw '-DirectoryID must be a uuid/guid' }
            }
        )]
        [string] $DirectoryID,

        [Parameter(Mandatory, ParameterSetName = 'AZURE')]
        [string] $ClientSecret,

        [Parameter(Mandatory, ParameterSetName = 'AWS')]
        [switch] $AWS,

        [Parameter(Mandatory, ParameterSetName = 'AWS')]
        [ValidateLength(12, 12)]
        [string] $AccountID,

        [Parameter(Mandatory, ParameterSetName = 'AWS')]
        [string] $IamRoleName,

        [Parameter()]
        [switch] $Validate,

        [Parameter()]
        [switch] $PassThru,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {

        Test-VenafiSession $PSCmdlet.MyInvocation

        $ownerId = Get-VcData -Type Team -InputObject $OwnerTeam

        $query = 'mutation CreateNewCloudConnector($input: CloudProviderInput!) {
                createCloudProvider(input: $input) {
                    ...CloudConnectorsList_UpdateCloudConnectorWizardInput
                }
                }

                fragment CloudConnectorsList_UpdateCloudConnectorWizardInput on CloudProvider {
                cloudProviderId: id
                name
                team {
                    teamId: id
                    name
                }
                authorizedTeams {
                    teamId: id
                    name
                }
                configuration {
                    ...CloudConnectorsList_CloudProviderAWSConfigurationUpdateInput
                    ...CloudConnectorsList_CloudProviderAzureConfiguration
                    ...CloudConnectorList_CloudProviderGcpConfiguration
                    ...CloudConnectorsList_CloudProviderAkamaiConfiguration
                }
                }

                fragment CloudConnectorsList_CloudProviderAWSConfigurationUpdateInput on CloudProviderAWSConfiguration {
                role
                }

                fragment CloudConnectorsList_CloudProviderAzureConfiguration on CloudProviderAzureConfiguration {
                applicationId
                directoryId
                }

                fragment CloudConnectorList_CloudProviderGcpConfiguration on CloudProviderGCPConfiguration {
                serviceAccountEmail
                publicKey
                publicKeyNotAfter
                projectNumber
                workloadIdentityPoolId
                workloadIdentityPoolProviderId
                issuerUrl
                authorizationMethod
                azureWIFConfiguration {
                    applicationId
                    directoryId
                }
                }

                fragment CloudConnectorsList_CloudProviderAkamaiConfiguration on CloudProviderAkamaiConfiguration {
                contractIds
                host
                accessToken
                clientToken
                tokenExpiration
                }
            '

        $validateQuery = '
            mutation ValidateAwsCloudConnector($cloudProviderId: UUID!) {
                validateCloudProvider(cloudProviderId: $cloudProviderId) {
                    result
                    details
                }
                }
                '
    }

    process {


        $variables = @{
            'input' = @{
                name            = $Name
                teamId          = $ownerId
                type            = $PSCmdlet.ParameterSetName
                authorizedTeams = @($AuthorizedTeam | Get-VcData -Type Team)
            }
        }

        switch ($PSCmdlet.ParameterSetName) {
            'GCP-Venafi' {
                $variables.input.gcpConfiguration = @{
                    authorizationMethod = 'VENAFI_GENERATED_KEY'
                    serviceAccountEmail = $ServiceAccountEmail
                }
                $variables.input.type = 'GCP'
            }

            'GCP-WIF' {
                $variables.input.gcpConfiguration = @{
                    authorizationMethod            = 'WORKLOAD_IDENTITY_FEDERATION'
                    serviceAccountEmail            = $ServiceAccountEmail
                    projectNumber                  = $ProjectNumber
                    workloadIdentityPoolId         = $PoolID
                    workloadIdentityPoolProviderId = $PoolProviderID
                }
                $variables.input.type = 'GCP'
            }

            'AZURE' {
                $variables.input.azureConfiguration = @{
                    applicationId = $ApplicationID
                    directoryId   = $DirectoryID
                    secret        = $ClientSecret
                }
            }

            'AWS' {
                $variables.input.awsConfiguration = @{
                    accountId = $AccountID
                    role      = $IamRoleName
                }
            }
        }

        if ( $PSCmdlet.ShouldProcess($Name, 'Create cloud provider') ) {

            $response = Invoke-VcGraphQL -Query $query -Variables $variables | Select-Object -ExpandProperty createCloudProvider

            if ( $Validate ) {
                $validateResponse = Invoke-VcGraphQL -Query $validateQuery -Variables @{'cloudProviderId' = $response.cloudProviderId }
                $response | Add-Member @{
                    validate = $validateResponse.validateCloudProvider
                }
            }

            if ( $PassThru ) {
                $response
            }
        }
    }
}

