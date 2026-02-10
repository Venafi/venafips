function Get-VcCloudProvider {
    <#
    .SYNOPSIS
    Get cloud provider info

    .DESCRIPTION
    Get 1 or more cloud providers

    .PARAMETER CloudProvider
    Cloud provider ID or name, tab completion supported

    .PARAMETER All
    Get all cloud providers

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, SaaS key can also provided.

    .INPUTS
    CloudProvider

    .EXAMPLE
    Get-VcCloudProvider -CloudProvider 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2'

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
    Get-VcCloudProvider -CloudProvider 'GCP'

    Get a single object by name.  The name is case sensitive.

    .EXAMPLE
    Get-VcCloudProvider -All

    Get all cloud providers

    #>

    [CmdletBinding(DefaultParameterSetName = 'ID')]

    param (

        [Parameter(Mandatory, ParameterSetName = 'ID', ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
        [Alias('cloudProviderId', 'ID', 'cp')]
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
                    tokenExpiration
                    }
                '

        $response = Invoke-VcGraphQL -Query $query

        if ( $PSBoundParameters.ContainsKey('CloudProvider') ) {
            $node = $response.cloudProviders.nodes | Where-Object { $CloudProvider -in $_.cloudProviderId, $_.name }
            return $node
        }

        return $response.cloudProviders.nodes

    }
}

