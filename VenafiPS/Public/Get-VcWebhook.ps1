function Get-VcWebhook {
    <#
    .SYNOPSIS
    Get webhook info

    .DESCRIPTION
    Get 1 or all webhooks

    .PARAMETER ID
    Webhook ID or name

    .PARAMETER All
    Get all webhooks

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, SaaS key can also provided.

    .INPUTS
    ID

    .EXAMPLE
    Get-VcWebhook -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' | ConvertTo-Json

    {
        "webhookId": "a7ddd210-0a39-11ee-8763-134b935c90aa",
        "name": "ServiceNow-expiry,
        "properties": {
            "connectorKind": "WEBHOOK",
            "filter": {
                "filterType": "EXPIRATION",
                "applicationIds": []
            },
            "target": {
                "type": "generic",
                "connection": {
                    "secret": "MySecret",
                    "url": "https://instance.service-now.com/api/company/endpoint"
                }
            }
        }
    }

    Get a single object by ID

    .EXAMPLE
    Get-VcWebhook -ID 'My Webhook'

    Get a single object by name.  The name is case sensitive.

    .EXAMPLE
    Get-VcWebhook -All

    Get all webhooks

    #>

    [CmdletBinding(DefaultParameterSetName = 'ID')]

    param (

        [Parameter(Mandatory, ParameterSetName = 'ID', ValueFromPipelineByPropertyName, Position = 0)]
        [Alias('webhookId')]
        [string] $ID,

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
            UriLeaf = 'connectors'
        }

        if ( $PSBoundParameters.ContainsKey('ID') ) {
            if ( Test-IsGuid($ID) ) {
                $params.UriLeaf += "/{0}" -f $ID
            }
            else {
                # search by name
                return Get-VcWebhook -All | Where-Object { $_.name -eq $ID }
            }
        }

        $response = Invoke-VenafiRestMethod @params

        if ( $response.PSObject.Properties.Name -contains 'connectors' ) {
            $connectors = $response | Select-Object -ExpandProperty 'connectors'
        }
        else {
            $connectors = $response
        }

        if ( $connectors ) {
            $connectors | Select-Object @{ 'n' = 'webhookId'; 'e' = { $_.Id } }, * -ExcludeProperty Id
        }
    }
}


