function Get-TrustAcmeServer {
    <#
    .SYNOPSIS
    Get ACME server info

    .DESCRIPTION
    Get 1 or more ACMEv2 servers, which ACME clients connect to for certificates.
    These are the servers in Configurations > ACME Servers, not certificate authorities of type ACME, see Get-TrustCertificateAuthority for those.
    Supported on Certificate Manager SaaS and NGTS.

    .PARAMETER AcmeServer
    ACME server ID or name.  The name is not case sensitive.

    .PARAMETER All
    Get all ACME servers

    .PARAMETER Deactivated
    Only get servers which are deactivated, $true, or active, $false.
    Both are returned if not provided.

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.

    .INPUTS
    AcmeServer

    .EXAMPLE
    Get-TrustAcmeServer -AcmeServer 'My ACME server'

    acmeServerId            : ca7ff555-88d2-4bfc-9efa-2630ac44c1f2
    name                    : My ACME server
    deactivated             : False
    directoryUrl            : https://api.venafi.cloud/v1/acme/ca7ff555-88d2-4bfc-9efa-2630ac44c1f2/directory
    application             : @{id=ca7ff555-88d2-4bfc-9efa-2630ac44c1f2; name=My app}
    issuingTemplate         : @{id=ca7ff555-88d2-4bfc-9efa-2630ac44c1f2; name=My template}
    certificateTags         : {}
    totalAccounts           : 4
    totalOrders             : 20
    totalCertificatesIssued : 0
    createdOn               : 10/20/2026 1:02:03 PM
    lastModifiedOn          : 10/20/2026 1:02:03 PM
    workspaceId             :
    eabKID                  : 1a2b3c

    Get a single ACME server by name

    .EXAMPLE
    Get-TrustAcmeServer -All

    Get all ACME servers

    .EXAMPLE
    Get-TrustAcmeServer -All -Deactivated $true

    Get all deactivated ACME servers

    .LINK
    https://venafi.github.io/VenafiPS/functions/Get-TrustAcmeServer/

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Get-TrustAcmeServer.ps1
    #>

    [CmdletBinding(DefaultParameterSetName = 'ID')]

    param (

        [Parameter(Mandatory, ParameterSetName = 'ID', ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
        [Alias('acmeServerId')]
        [string] $AcmeServer,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch] $All,

        [Parameter()]
        [bool] $Deactivated,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient
    )

    begin {
        $query = 'query SearchACMEServers($filter: ACMEServerFilterInput, $first: Int, $after: String, $orderBy: ACMEServerOrderInput) {
                    searchACMEServers(filter: $filter, first: $first, after: $after, orderBy: $orderBy) {
                        pageInfo {
                            endCursor
                            hasNextPage
                        }
                        nodes {
                            id
                            workspaceId
                            name
                            createdOn
                            lastModifiedOn
                            directoryURL
                            deactivated
                            application {
                                id
                                name
                            }
                            issuingTemplate {
                                id
                                name
                            }
                            certificateTags {
                                name
                            }
                            eabKID
                            aggregates {
                                totalAccounts
                                totalOrders
                                totalCertificatesIssued
                            }
                        }
                    }
                }'
    }

    process {

        $searchAttributes = @{}

        if ( $PSCmdlet.ParameterSetName -eq 'ID' ) {
            if ( Test-IsGuid($AcmeServer) ) {
                $searchAttributes.id = @{ eq = $AcmeServer }
            }
            else {
                $searchAttributes.name = @{ eq = $AcmeServer }
            }
        }

        if ( $PSBoundParameters.ContainsKey('Deactivated') ) {
            $searchAttributes.deactivated = @{ eq = $Deactivated }
        }

        $variables = @{
            first   = 100
            orderBy = @{ field = 'NAME'; direction = 'ASC' }
        }
        if ( $searchAttributes.Count ) {
            $variables.filter = @{ and = $searchAttributes }
        }

        do {
            $response = Invoke-TrustGraphQL -Query $query -Variables $variables

            foreach ($node in $response.searchACMEServers.nodes) {
                [pscustomobject]@{
                    acmeServerId            = $node.id
                    name                    = $node.name
                    deactivated             = $node.deactivated
                    directoryUrl            = $node.directoryURL
                    application             = $node.application
                    issuingTemplate         = $node.issuingTemplate
                    certificateTags         = @($node.certificateTags.name)
                    totalAccounts           = $node.aggregates.totalAccounts
                    totalOrders             = $node.aggregates.totalOrders
                    totalCertificatesIssued = $node.aggregates.totalCertificatesIssued
                    createdOn               = $node.createdOn
                    lastModifiedOn          = $node.lastModifiedOn
                    workspaceId             = $node.workspaceId
                    eabKID                  = $node.eabKID
                }
            }

            $variables.after = $response.searchACMEServers.pageInfo.endCursor
        } while ( $response.searchACMEServers.pageInfo.hasNextPage )
    }
}
