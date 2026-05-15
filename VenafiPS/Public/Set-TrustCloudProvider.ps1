function Set-TrustCloudProvider {
    <#
    .SYNOPSIS
    Update a cloud provider

    .DESCRIPTION
    Update an existing cloud provider for Akamai, AWS, Azure, or GCP.
    Only the parameters you provide will be updated; all other settings are preserved.
    The provider type is determined automatically from the existing provider.

    .PARAMETER CloudProvider
    ID or name of the cloud provider to update.

    .PARAMETER Name
    New name for the cloud provider.

    .PARAMETER OwnerTeam
    ID or name of owning team.
    The Owning Team is responsible for the administration, management, and control of a designated cloud provider, with the authority to update, modify, and delete cloud provider resources.

    .PARAMETER AuthorizedTeam
    1 or more IDs or names of authorized teams.
    Authorized teams are granted permission to use specific resources of a cloud provider. Although team members can perform tasks like creating a keystore, their permissions may be limited regarding broader modifications to the provider's configuration. Unlike the Owning Team, users may not have the authority to update and delete Cloud Providers.

    .PARAMETER ContractID
    1 or more Akamai contract IDs.
    Only valid for Akamai providers.

    .PARAMETER HostName
    Akamai API hostname (e.g., the host from your .edgerc credentials).
    Only valid for Akamai providers.

    .PARAMETER AccessToken
    Akamai access token. Accepts a string or SecureString.
    Only valid for Akamai providers.

    .PARAMETER ClientToken
    Akamai client token. Accepts a string or SecureString.
    Only valid for Akamai providers.

    .PARAMETER ClientSecret
    Client secret credential. Accepts a string or SecureString.
    Only valid for Akamai and Azure providers.
    Required when updating any Akamai or Azure configuration settings.

    .PARAMETER ApplicationID
    Active Directory Application (client) ID. Must be a valid GUID.
    Only valid for Azure providers.

    .PARAMETER DirectoryID
    Azure Active Directory tenant ID. Must be a valid GUID.
    Only valid for Azure providers.

    .PARAMETER AccountID
    12 digit AWS Account ID.
    Only valid for AWS providers.

    .PARAMETER IamRoleName
    IAM role name used for the integration.
    Only valid for AWS providers.

    .PARAMETER ServiceAccountEmail
    Service account email address.
    Provide for GCP connections with either Workload Identity Federation or Venafi Generated Key.
    Only valid for GCP providers.

    .PARAMETER ProjectNumber
    GCP project number, needed for Workload Identity Federation.
    Only valid for GCP providers.

    .PARAMETER PoolID
    Workload Identity Pool ID, located in the GCP Workload Identity Federation section.
    Must be 4 to 32 lowercase letters, digits, or hyphens.
    Only valid for GCP providers.

    .PARAMETER PoolProviderID
    Workload Identity Pool Provider ID.
    Must be 4 to 32 lowercase letters, digits, or hyphens.
    Only valid for GCP providers.

    .PARAMETER Validate
    Invoke cloud provider validation after the update.
    If using -PassThru, the validation result will be included with the provider details.

    .PARAMETER PassThru
    Return the updated cloud provider object.

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.

    .OUTPUTS
    PSCustomObject, if PassThru provided

    .EXAMPLE
    Set-TrustCloudProvider -CloudProvider 'MyAkamai' -HostName 'newhost.luna.akamaiapis.net' -ClientSecret $secret

    Update the host on an Akamai cloud provider

    .EXAMPLE
    Set-TrustCloudProvider -CloudProvider 'MyAzure' -ClientSecret $newSecret -Validate -PassThru

    Update the Azure client secret and validate the connection

    .EXAMPLE
    Set-TrustCloudProvider -CloudProvider 'MyAWS' -IamRoleName 'NewRoleName'

    Update the IAM role name on an AWS provider

    .EXAMPLE
    Set-TrustCloudProvider -CloudProvider 'MyGCP' -ServiceAccountEmail 'new-sa@project.iam.gserviceaccount.com'

    Update the service account email on a GCP provider

    .EXAMPLE
    Set-TrustCloudProvider -CloudProvider 'MyGCP' -ProjectNumber 98765 -PoolID 'new-pool' -PoolProviderID 'new-provider'

    Update GCP Workload Identity Federation settings

    .EXAMPLE
    Set-TrustCloudProvider -CloudProvider 'MyAkamai' -Name 'RenamedProvider' -OwnerTeam 'NewTeam'

    Rename a provider and change the owning team

    #>

    [CmdletBinding(SupportsShouldProcess)]

    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('cloudProviderId')]
        [string] $CloudProvider,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $OwnerTeam,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]] $AuthorizedTeam,

        # Akamai
        [Parameter()]
        [string[]] $ContractID,

        [Parameter()]
        [string] $HostName,

        [Parameter()]
        [psobject] $AccessToken,

        [Parameter()]
        [psobject] $ClientToken,

        # Akamai + Azure
        [Parameter()]
        [psobject] $ClientSecret,

        # Azure
        [Parameter()]
        [ValidateScript(
            {
                if ( Test-IsGuid($_) ) { $true } else { throw '-ApplicationID must be a uuid/guid' }
            }
        )]
        [string] $ApplicationID,

        [Parameter()]
        [ValidateScript(
            {
                if ( Test-IsGuid($_) ) { $true } else { throw '-DirectoryID must be a uuid/guid' }
            }
        )]
        [string] $DirectoryID,

        # AWS
        [Parameter()]
        [ValidateLength(12, 12)]
        [string] $AccountID,

        [Parameter()]
        [string] $IamRoleName,

        # GCP
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $ServiceAccountEmail,

        [Parameter()]
        [ValidateLength(4, 64)]
        [string] $ProjectNumber,

        [Parameter()]
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

        [Parameter()]
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

        [Parameter()]
        [switch] $Validate,

        [Parameter()]
        [switch] $PassThru,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient
    )

    begin {

        $query = 'mutation UpdateCloudProvider($input: CloudProviderUpdateInput!) {
                updateCloudProvider(input: $input) {
                    ...CloudConnectorsList_DrawerFields
                    __typename
                }
                }

                fragment CloudConnectorsList_DrawerFields on CloudProvider {
                id
                statusDetails
                ...CloudConnectorsList_PropertiesTabFields
                __typename
                }

                fragment CloudConnectorsList_PropertiesTabFields on CloudProvider {
                type
                status
                keystoresCount
                ...CloudConnectorsList_NewCloudConnectorWizard
                __typename
                }

                fragment CloudConnectorsList_NewCloudConnectorWizard on CloudProvider {
                name
                team {
                    id
                    name
                    __typename
                }
                authorizedTeams {
                    id
                    name
                    __typename
                }
                configuration {
                    ...CloudConnectorsList_CloudProviderAWSConfiguration
                    ...CloudConnectorsList_CloudProviderAzureConfiguration
                    ...CloudConnectorList_CloudProviderGcpConfiguration
                    ...CloudConnectorsList_CloudProviderAkamaiConfiguration
                    __typename
                }
                __typename
                }

                fragment CloudConnectorsList_CloudProviderAWSConfiguration on CloudProviderAWSConfiguration {
                accountId
                externalId
                role
                organizationId
                __typename
                }

                fragment CloudConnectorsList_CloudProviderAzureConfiguration on CloudProviderAzureConfiguration {
                applicationId
                directoryId
                __typename
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
                    __typename
                }
                __typename
                }

                fragment CloudConnectorsList_CloudProviderAkamaiConfiguration on CloudProviderAkamaiConfiguration {
                contractIds
                host
                accessToken
                clientToken
                __typename
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

        $existingProvider = Get-TrustCloudProvider -CloudProvider $CloudProvider -ErrorAction SilentlyContinue
        if ( -not $existingProvider ) {
            throw "Cloud provider '$CloudProvider' not found"
        }

        $providerType = $existingProvider.type

        # validate provider-specific params match the actual type
        $typeParamMap = @{
            AKAMAI = 'ContractID', 'HostName', 'AccessToken', 'ClientToken'
            AZURE  = 'ApplicationID', 'DirectoryID'
            AWS    = 'AccountID', 'IamRoleName'
            GCP    = 'ServiceAccountEmail', 'ProjectNumber', 'PoolID', 'PoolProviderID'
        }

        # ClientSecret is valid for both Akamai and Azure
        $clientSecretTypes = 'AKAMAI', 'AZURE'

        foreach ( $type in $typeParamMap.Keys ) {
            $invalidParams = $typeParamMap[$type] | Where-Object { $PSBoundParameters.ContainsKey($_) }
            if ( $invalidParams -and $providerType -ne $type ) {
                throw "Parameters $($invalidParams -join ', ') are only valid for $type providers, but '$CloudProvider' is $providerType"
            }
        }

        if ( $PSBoundParameters.ContainsKey('ClientSecret') -and $providerType -notin $clientSecretTypes ) {
            throw "Parameter ClientSecret is only valid for Akamai and Azure providers, but '$CloudProvider' is $providerType"
        }

        # ClientSecret is required when updating any Akamai or Azure configuration params
        if ( $providerType -in $clientSecretTypes -and -not $PSBoundParameters.ContainsKey('ClientSecret') ) {
            $configParams = $typeParamMap[$providerType] | Where-Object { $PSBoundParameters.ContainsKey($_) }
            if ( $configParams ) {
                throw "ClientSecret is required when updating $providerType configuration"
            }
        }

        $variables = @{
            'input' = @{
                id              = $existingProvider.cloudProviderId
                name            = $existingProvider.name
                teamId          = $existingProvider.team.teamId
                type            = $providerType
                authorizedTeams = $existingProvider.authorizedTeam.teamId
            }
        }

        # capture existing configuration and ensure converted to hashtable
        # values provided by user will overwrite
        $configKey = '{0}Configuration' -f $providerType.ToLower()
        $variables.input.$configKey = $existingProvider.configuration | ConvertTo-Hashtable -Recurse

        switch ($PSBoundParameters.Keys) {
            'Name' {
                $variables.input.name = $Name
            }

            'OwnerTeam' {
                $variables.input.teamId = $OwnerTeam | Get-TrustData -Type Team -FailOnNotFound
            }

            'AuthorizedTeam' {
                $variables.input.authorizedTeams = @($AuthorizedTeam | Get-TrustData -Type Team -FailOnNotFound)
            }

            # Akamai
            'ContractID' {
                $variables.input.akamaiConfiguration.contractIds = @($ContractID)
            }

            'HostName' {
                $variables.input.akamaiConfiguration.host = $HostName
            }

            'AccessToken' {
                $variables.input.akamaiConfiguration.accessToken = $AccessToken | ConvertTo-PlainTextString
            }

            'ClientToken' {
                $variables.input.akamaiConfiguration.clientToken = $ClientToken | ConvertTo-PlainTextString
            }

            'ClientSecret' {
                if ( $providerType -eq 'AZURE' ) {
                    $variables.input.azureConfiguration.secret = $ClientSecret | ConvertTo-PlainTextString
                }
                else {
                    $variables.input.akamaiConfiguration.clientSecret = $ClientSecret | ConvertTo-PlainTextString
                }
            }

            # Azure
            'ApplicationID' {
                $variables.input.azureConfiguration.applicationId = $ApplicationID
            }

            'DirectoryID' {
                $variables.input.azureConfiguration.directoryId = $DirectoryID
            }

            # AWS
            'AccountID' {
                $variables.input.awsConfiguration.accountId = $AccountID
            }

            'IamRoleName' {
                $variables.input.awsConfiguration.role = $IamRoleName
            }

            # GCP
            'ServiceAccountEmail' {
                $variables.input.gcpConfiguration.serviceAccountEmail = $ServiceAccountEmail
            }

            'ProjectNumber' {
                $variables.input.gcpConfiguration.projectNumber = $ProjectNumber
            }

            'PoolID' {
                $variables.input.gcpConfiguration.workloadIdentityPoolId = $PoolID
            }

            'PoolProviderID' {
                $variables.input.gcpConfiguration.workloadIdentityPoolProviderId = $PoolProviderID
            }
        }

        if ( $PSCmdlet.ShouldProcess($CloudProvider, ('Update {0} cloud provider' -f $variables.input.type)) ) {

            $response = Invoke-TrustGraphQL -Query $query -Variables $variables | Select-Object -ExpandProperty updateCloudProvider

            if ( $Validate ) {
                $validateResponse = Invoke-TrustGraphQL -Query $validateQuery -Variables @{'cloudProviderId' = $response.id }
                $response | Add-Member @{
                    validate = $validateResponse.validateCloudProvider
                }
            }

            if ( $PassThru -and $response ) {
                Get-TrustCloudProvider -CloudProvider $response.id
            }
        }
    }
}

