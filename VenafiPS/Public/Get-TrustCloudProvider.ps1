function Get-TrustCloudProvider {
    <#
    .SYNOPSIS
    Get cloud provider info

    .DESCRIPTION
    Get 1 or more cloud providers

    .PARAMETER CloudProvider
    Cloud provider ID or name, tab completion supported

    .PARAMETER All
    Get all cloud providers

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.

    .INPUTS
    CloudProvider

    .EXAMPLE
    Get-TrustCloudProvider -CloudProvider 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2'

    cloudProviderId : ca7ff555-88d2-4bfc-9efa-2630ac44c1f2
    name            : MyGCP
    type            : GCP
    status          : VALIDATED
    statusDetails   :
    team            : @{teamId=ca7ff555-88d2-4bfc-9efa-2630ac44c1f2; name=Cloud Admin Team}
    authorizedTeam  : {@{teamId=ca7ff555-88d2-4bfc-9efa-2630ac44c1f2; name=Cloud App Team}}
    keystoresCount  : 1
    configuration   : @{accountId=077141312; externalId=ca7ff555-88d2-4bfc-9efa-2630ac44c1f2; role=ACMIntegrationRole; organizationId=}

    Get a single object by ID

    .EXAMPLE
    Get-TrustCloudProvider -CloudProvider 'GCP'

    Get a single object by name.  The name is case sensitive.

    .EXAMPLE
    Get-TrustCloudProvider -All

    Get all cloud providers

    #>

    [CmdletBinding(DefaultParameterSetName = 'ID')]
    [Alias('Get-VcCloudProvider')]

    param (

        [Parameter(Mandatory, ParameterSetName = 'ID', ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
        [Alias('cloudProviderId')]
        [string] $CloudProvider,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch] $All,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient
    )

    begin {
    }

    process {

        $query = 'query GetCloudConnectorsListData($first: Int, $after: String, $last: Int, $before: String, $orderBy: CloudProviderOrderInput) {
                    cloudProviders(
                        first: $first
                        after: $after
                        last: $last
                        before: $before
                        orderBy: $orderBy
                    ) {
                        pageInfo {
                        startCursor
                        endCursor
                        hasNextPage
                        hasPreviousPage
                        }
                        nodes {
                        ...AllCloudProviderData
                        }
                        totalCount
                    }
                    }

                    fragment AllCloudProviderData on CloudProvider {
                    cloudProviderId: id
                    name
                    type
                    status
                    statusDetails
                    team {
                        teamId: id
                        name
                    }
                    authorizedTeam: authorizedTeams {
                        teamId: id
                        name
                    }
                    keystoresCount
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
                    }
                '

        $response = Invoke-TrustGraphQL -Query $query

        if ( $PSBoundParameters.ContainsKey('CloudProvider') ) {
            $node = $response.cloudProviders.nodes | Where-Object { $CloudProvider -in $_.cloudProviderId, $_.name }
            return $node
        }

        return $response.cloudProviders.nodes

    }
}

