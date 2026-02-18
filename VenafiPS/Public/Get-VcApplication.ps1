function Get-VcApplication {
    <#
    .SYNOPSIS
    Get application info

    .DESCRIPTION
    Get 1 or more applications.
    Application level renewal configurations are included.

    .PARAMETER Application
    Application ID or name, tab completion supported

    .PARAMETER IncludeConfig
    Include autorenewal configuration

    .PARAMETER All
    Get all applications

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, SaaS key can also provided.

    .INPUTS
    ID

    .EXAMPLE
    Get-VcApplication -Application 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2'

    applicationId              : 96fc9310-67ec-11eb-a8a7-794fe75a8e6f
    issuingTemplate            : @{Name=MyTemplate; id=7fb6af20-b22e-11ea-9a24-930fb5d2b247}
    autoRenew                  : True
    autoProvision              : True
    renewalWindowInherit       : False
    renewalWindowDays          : 15
    companyId                  : 09b24f81-b22b-11ea-91f3-ebd6dea5452e
    name                       : myapp
    description                :
    ownerIdsAndTypes           : {@{ownerId=0a2adae0-b22b-11ea-91f3-ebd6dea5452f; ownerType=TEAM}}
    fullyQualifiedDomainNames  : {}
    ipRanges                   : {}
    ports                      : {}
    modificationDate           : 6/8/2023 11:06:43 AM
    creationDate               : 2/5/2021 2:59:00 PM
    ownership                  : @{owningUsers=System.Object[]}

    Get a single object by ID

    .EXAMPLE
    Get-VcApplication -Application 'My Awesome App'

    Get a single object by name.  The name is case sensitive.

    .EXAMPLE
    Get-VcApplication -All

    Get all applications

    #>

    [CmdletBinding(DefaultParameterSetName = 'ID')]
    [Alias('Get-VaasApplication')]

    param (

        [Parameter(Mandatory, ParameterSetName = 'ID', ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
        [Alias('applicationId', 'ID')]
        [string] $Application,

        [Parameter()]
        [switch] $IncludeConfig,

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

        $params = @{
            UriRoot = 'outagedetection/v1'
            UriLeaf = 'applications'
        }

        if ( $PSBoundParameters.ContainsKey('Application') ) {
            if ( Test-IsGuid($Application) ) {
                $params.UriLeaf += "/{0}" -f $Application
            }
            else {
                # search by name
                $params.UriLeaf += "/name/$Application"
            }
        }

        try {
            $response = Invoke-VenafiRestMethod @params
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

        $applications = if ( $response.PSObject.Properties.Name -contains 'applications' ) {
            $response | Select-Object -ExpandProperty applications
        }
        else {
            $response
        }

        if ( $IncludeConfig ) {

            foreach ($app in $applications) {
                $thisConfig = Invoke-VenafiRestMethod -UriLeaf ('autorenewal/{0}/configuration' -f $app.id)
                $app | Select-Object @{'n' = 'applicationId'; 'e' = { $_.Id } },
                @{
                    'n' = 'issuingTemplate'
                    'e' = {
                        $_.certificateIssuingTemplateAliasIdMap.psobject.Properties | Select-Object @{'n' = 'name'; 'e' = { $_.Name } }, @{'n' = 'issuingTemplateId'; 'e' = { $_.Value } }
                    }
                },
                @{
                    'n' = 'autoRenew'
                    'e' = {
                        $thisConfig.renewalActions.renew
                    }
                },
                @{
                    'n' = 'autoProvision'
                    'e' = {
                        $thisConfig.renewalActions.provision
                    }
                },
                @{
                    'n' = 'renewalWindowInherit'
                    'e' = {
                        $thisConfig.renewalWindow.inherit
                    }
                },
                @{
                    'n' = 'renewalWindowDays'
                    'e' = {
                        $thisConfig.renewalWindow.days
                    }
                }, * -ExcludeProperty Id, certificateIssuingTemplateAliasIdMap
            }
        }
        else {
            $applications | Select-Object @{'n' = 'applicationId'; 'e' = { $_.Id } },
            @{
                'n' = 'issuingTemplate'
                'e' = {
                    $_.certificateIssuingTemplateAliasIdMap.psobject.Properties | Select-Object @{'n' = 'name'; 'e' = { $_.Name } }, @{'n' = 'issuingTemplateId'; 'e' = { $_.Value } }
                }
            }, * -ExcludeProperty Id, certificateIssuingTemplateAliasIdMap

        }
    }
}

