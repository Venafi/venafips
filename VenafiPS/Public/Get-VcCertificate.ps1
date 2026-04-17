function Get-VcCertificate {
    <#
    .SYNOPSIS
    Get certificate information

    .DESCRIPTION
    Get certificate information, either all available to the api key provided or by id or zone.

    .PARAMETER Certificate
    Certificate identifier, the ID or certificate name.

    .PARAMETER All
    Retrieve all certificates

    .PARAMETER OwnerDetail
    Retrieve extended application owner info

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, SaaS key can also be provided.

    .INPUTS
    ID

    .OUTPUTS
    PSCustomObject

    .EXAMPLE
    Get-VdcCertificate -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2'

    Get certificate info for a specific cert

    .EXAMPLE
    Get-VdcCertificate -All

    Get certificate info for all certs
    #>

    [CmdletBinding(DefaultParameterSetName = 'Id')]

    param (

        [Parameter(ParameterSetName = 'Id', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
        [Alias('certificateId', 'certificateIds', 'ID')]
        [string] $Certificate,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [Switch] $All,

        [Parameter()]
        [switch] $OwnerDetail,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {

        Test-VenafiSession $PSCmdlet.MyInvocation

        $appOwners = [System.Collections.Generic.List[object]]::new()

    }

    process {

        if ( $All ) {
            return (Find-VcCertificate -IncludeVaasOwner:$OwnerDetail)
        }

        $params = @{
            UriRoot = 'outagedetection/v1'
            UriLeaf = "certificates/"
        }

        if ( Test-IsGuid($Certificate) ) {
            $params.UriLeaf += $Certificate
        }
        else {
            $findParams = @{
                Filter           = @('certificateName', 'eq', $Certificate)
                IncludeVaasOwner = $OwnerDetail
            }
            return (Find-VcCertificate @findParams | Get-VcCertificate)
        }

        $params.UriLeaf += "?ownershipTree=true"

        try {
            $response = Invoke-VenafiRestMethod @params
        }
        catch {
            $originalError = $_

            try {
                Write-Verbose "Initial request failed with error: $($_.ErrorDetails.Message). Attempting to determine if certificate is a trusted CA certificate."

                $message = $_.ErrorDetails.Message | ConvertFrom-Json
                if ( $message.errors.code -and $message.errors.code -eq 10051 ) {
                    # check if the certificate is a trusted ca certificate, as those are accessed via a different endpoint
                    $trustedCaCerts = Invoke-VenafiRestMethod -UriLeaf 'trustedcacertificates' | Select-Object -ExpandProperty certificates
                    $response = $trustedCaCerts | Where-Object { $Certificate -in $_.id, $_.subjectCN[0] }
                }
                else {
                    throw $originalError
                }
            }
            catch {
                throw $originalError
            }
        }

        if ( $response.PSObject.Properties.Name -contains 'certificates' ) {
            $certs = $response | Select-Object -ExpandProperty certificates
        }
        else {
            $certs = $response
        }

        $certs | Select-Object @{
            'n' = 'certificateId'
            'e' = {
                $_.Id
            }
        },
        @{
            'n' = 'application'
            'e' = {
                if ( $_.applicationIds ) {
                    $_.applicationIds | Get-VcApplication | Select-Object -Property * -ExcludeProperty ownerIdsAndTypes, ownership
                }
            }
        },
        @{
            'n' = 'owner'
            'e' = {
                if ( $OwnerDetail ) {

                    # this scriptblock requires ?ownershipTree=true be part of the url
                    foreach ( $thisOwner in $_.ownership.owningContainers.owningUsers ) {
                        $thisOwnerDetail = $appOwners | Where-Object { $_.id -eq $thisOwner }
                        if ( -not $thisOwnerDetail ) {
                            $thisOwnerDetail = Get-VcIdentity -ID $thisOwner | Select-Object firstName, lastName, emailAddress,
                            @{
                                'n' = 'status'
                                'e' = { $_.userStatus }
                            },
                            @{
                                'n' = 'role'
                                'e' = { $_.systemRoles }
                            },
                            @{
                                'n' = 'type'
                                'e' = { 'USER' }
                            },
                            @{
                                'n' = 'userId'
                                'e' = { $_.id }
                            }

                            $appOwners.Add($thisOwnerDetail)

                        }
                        $thisOwnerDetail
                    }

                    foreach ($thisOwner in $_.ownership.owningContainers.owningTeams) {
                        $thisOwnerDetail = $appOwners | Where-Object { $_.id -eq $thisOwner }
                        if ( -not $thisOwnerDetail ) {
                            $thisOwnerDetail = Get-VcTeam -ID $thisOwner | Select-Object name, role, members,
                            @{
                                'n' = 'type'
                                'e' = { 'TEAM' }
                            },
                            @{
                                'n' = 'teamId'
                                'e' = { $_.id }
                            }

                            $appOwners.Add($thisOwnerDetail)
                        }
                        $thisOwnerDetail
                    }
                }
                else {
                    $_.ownership.owningContainers | Select-Object owningUsers, owningTeams
                }
            }
        },
        @{
            'n' = 'instance'
            'e' = { $_.instances }
        },
        * -ExcludeProperty Id, applicationIds, instances, totalInstanceCount, ownership
    }
}


