function Get-VcCloudKeystore {
    <#
    .SYNOPSIS
    Get cloud keystore info

    .DESCRIPTION
    Get 1 or more cloud keystores

    .PARAMETER CloudKeystore
    Cloud keystore ID or name, tab completion supported

    .PARAMETER CloudProvider
    Limit keystores to specific providers.
    Cloud provider ID or name, tab completion supported

    .PARAMETER All
    Get all cloud keystores

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A TLSPC key can also provided.

    .INPUTS
    CloudProvider, CloudKeystore

    .EXAMPLE
    Get-VcCloudKeystore -CloudProvider 'MyGCP'

    Get all keystores for a specific provider

    .EXAMPLE
    Get-VcCloudKeystore -CloudProvider 'MyGCP' -CloudKeystore 'CK'

    Get a specific keystore

    .EXAMPLE
    Get-VcCloudKeystore -All

    Get all cloud keystores across all providers

    #>

    [CmdletBinding()]

    param (

        [Parameter(Mandatory, ParameterSetName = 'CK', ValueFromPipelineByPropertyName)]
        [Alias('cloudKeystoreId', 'ck')]
        [string] $CloudKeystore,

        [Parameter(Mandatory, ParameterSetName = 'CP', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'CK', ValueFromPipelineByPropertyName)]
        [Alias('cloudProviderId', 'cp')]
        [string] $CloudProvider,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch] $All,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation
    }

    process {

        $query = 'query GetCloudKeystores($cloudProviderId: UUID, $cloudKeystoreId: UUID, $cloudProviderName: String, $cloudKeystoreName: String) {
                    cloudKeystores(
                        filter: {cloudProviderId: $cloudProviderId, cloudKeystoreId: $cloudKeystoreId, cloudProviderName: $cloudProviderName, cloudKeystoreName: $cloudKeystoreName}
                    ) {
                        nodes {
                        cloudKeystoreId: id
                        name
                        type
                        createdOn
                        machineIdentitiesCount
                        configuration {
                            ...CloudKeystoresList_CloudKeystoreACMConfiguration
                            ...CloudKeystoresList_CloudKeystoreAKVConfiguration
                            ...CloudKeystoreList_CloudKeystoreGCMConfiguration
                            ...CloudKeystoresList_CloudKeystoreAkamaiCDNConfiguration
                            __typename
                        }
                        cloudProvider {
                            ...CloudKeystoresList_CloudProvider
                        }
                        }
                    }
                    }

                    fragment CloudKeystoresList_CloudKeystoreACMConfiguration on CloudKeystoreACMConfiguration {
                    accountId
                    region
                    }

                    fragment CloudKeystoresList_CloudKeystoreAKVConfiguration on CloudKeystoreAKVConfiguration {
                    keyVaultName
                    }

                    fragment CloudKeystoreList_CloudKeystoreGCMConfiguration on CloudKeystoreGCMConfiguration {
                    location
                    projectId
                    }

                    fragment CloudKeystoresList_CloudKeystoreAkamaiCDNConfiguration on CloudKeystoreAkamaiCDNConfiguration {
                    contractId
                    }

                    fragment CloudKeystoresList_CloudProvider on CloudProvider {
                    id
                    name
                    configuration {
                        ...CloudConnectorsList_CloudProviderAWSConfiguration
                        ...CloudConnectorsList_CloudProviderAzureConfiguration
                        ...CloudConnectorList_CloudProviderGcpConfiguration
                        ...CloudConnectorsList_CloudProviderAkamaiConfiguration
                    }
                    }

                    fragment CloudConnectorsList_CloudProviderAWSConfiguration on CloudProviderAWSConfiguration {
                    accountId
                    externalId
                    role
                    organizationId
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

        $variables = @{}

        if ($CloudProvider) {
            if ( Test-IsGuid($CloudProvider) ) {
                $variables.cloudProviderId = $CloudProvider
            }
            else {
                $variables.cloudProviderName = $CloudProvider
            }
        }

        if ($CloudKeystore) {
            if ( Test-IsGuid($CloudKeystore) ) {
                $variables.cloudKeystoreId = $CloudKeystore
            }
            else {
                $variables.cloudKeystoreName = $CloudKeystore
            }
        }

        $response = Invoke-VcGraphQL -Query $query -Variables $variables

        return $response.cloudKeystores.nodes

    }
}

