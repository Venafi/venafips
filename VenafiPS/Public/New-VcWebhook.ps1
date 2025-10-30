function New-VcWebhook {
    <#
    .SYNOPSIS
    Create a new webhook

    .DESCRIPTION
    Create a new webhook to forward logged events to another service such as Slack, Teams, or a SIEM

    .PARAMETER Name
    Webhook name

    .PARAMETER Type
    slack, teams, or generic (for SIEM, ServiceNow, etc).
    The default is generic.

    .PARAMETER Url
    Endpoint to be called when the event type/name is triggered.
    This should be the full url and will be validated during webhook creation.
    See https://developer.venafi.com/tlsprotectcloud/docs/control-plane-forwarding-logged-events for more details.

    .PARAMETER EventType
    One or more event types to trigger on.
    This property has tab ahead to provide you with a list of values

    .PARAMETER EventName
    One or more event names to trigger on.
    This property has tab ahead to provide you with a list of values

    .PARAMETER Secret
    Secret value used to calculate signature which will be sent to the endpoint in the header

    .PARAMETER CriticalOnly
    Only subscribe to log messages deemed as critical

    .PARAMETER PassThru
    Return newly created webhook object

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A TLSPC key can also provided.

    .OUTPUTS
    PSCustomObject, if PassThru provided

    .EXAMPLE
    New-VcWebhook -Name 'MyWebhook' -Url 'https://my.com/endpoint' -EventType 'Authentication'

    Create a new webhook for one event type

    .EXAMPLE
    New-VcWebhook -Name 'MyWebhook' -Url 'https://my.com/endpoint' -EventType 'Authentication' -Type slack

    Create a new webhook to send events to Slack

    .EXAMPLE
    New-VcWebhook -Name 'MyWebhook' -Url 'https://my.com/endpoint' -EventType 'Authentication', 'Certificates', 'Applications'

    Create a new webhook with multiple event types

    .EXAMPLE
    New-VcWebhook -Name 'MyWebhook' -Url 'https://my.com/endpoint' -EventName 'Certificate Validation Started'

    Create a new webhook with event names as opposed to event types.
    This will result in fewer messages received as opposed to subscribing at the event type level.

    .EXAMPLE
    New-VcWebhook -Name 'MyWebhook' -Url 'https://my.com/endpoint' -EventType 'Certificates' -CriticalOnly

    Subscribe to critical messages only for a specific event type

    .EXAMPLE
    New-VcWebhook -Name 'MyWebhook' -Url 'https://my.com/endpoint' -EventType 'Authentication' -Secret 'MySecret'

    Create a new webhook with optional secret

    .EXAMPLE
    New-VcWebhook -Name 'MyWebhook' -Url 'https://my.com/endpoint' -EventType 'Authentication' -PassThru

    Create a new webhook returning the newly created object

    .LINK
    https://api.venafi.cloud/webjars/swagger-ui/index.html?urls.primaryName=connectors-service#/Connectors/connectors_create

    .LINK
    https://developer.venafi.com/tlsprotectcloud/docs/control-plane-forwarding-logged-events
    #>

    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'EventName')]

    param (
        [Parameter(Mandatory)]
        [string] $Name,

        [Parameter()]
        [ValidateSet('generic', 'slack', 'teams')]
        [string] $Type = 'generic',

        [Parameter(Mandatory)]
        [string] $Url,

        [Parameter(Mandatory, ParameterSetName = 'EventType')]
        [String[]] $EventType,

        [Parameter(Mandatory, ParameterSetName = 'EventName')]
        [String[]] $EventName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Alias('token')]
        [string] $Secret,

        [Parameter()]
        [switch] $CriticalOnly,

        [Parameter()]
        [switch] $PassThru,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation

        # validate inputs
        $at = Invoke-VenafiRestMethod -UriLeaf 'activitytypes'

        if ( $PSBoundParameters.ContainsKey('EventType') ) {
            $compare = compare-object -ReferenceObject $EventType -DifferenceObject $at.readablename | Where-Object { $_.SideIndicator -eq '<=' }
            if ( $compare ) {
                throw ('{0} are not valid event types.  Valid values include {1}.' -f ($compare.InputObject -join ', '), ($at.readablename -join ', '))
            }
        }
        else {
            $compare = compare-object -ReferenceObject $EventName -DifferenceObject $at.values.readablename | Where-Object { $_.SideIndicator -eq '<=' }
            if ( $compare ) {
                throw ('{0} are not valid event names.  Valid values include {1}.' -f ($compare.InputObject -join ', '), ($at.values.readablename -join ', '))
            }
        }
    }

    process {

        $params = @{
            Method       = 'Post'
            UriRoot      = 'v1'
            UriLeaf      = 'connectors'
            Body         = @{
                name       = $Name
                properties = @{
                    'connectorKind' = 'WEBHOOK'
                    'target'        = @{
                        'type'       = $Type
                        'connection' = @{
                            'url' = $Url
                        }
                    }
                    'filter'        = @{
                        criticality = [int]$CriticalOnly.IsPresent
                    }
                }
            }
            FullResponse = $true
        }

        # either event type or name will be provided
        if ( $PSBoundParameters.ContainsKey('EventType') ) {
            $params.Body.properties.filter.activityTypes = @($EventType)
        }
        else {
            $params.Body.properties.filter.activities = @($EventName)
        }

        if ( $PSBoundParameters.ContainsKey('Secret') ) {
            $params.Body.properties.target.connection.secret = $Secret
        }

        if ( $PSCmdlet.ShouldProcess($Name, 'Create webhook') ) {

            try {
                $response = Invoke-VenafiRestMethod @params
                switch ( $response.StatusCode ) {

                    201 {
                        if ( $PassThru ) {
                            $response.Content | ConvertFrom-Json | Select-Object -Property @{'n' = 'webhookId'; 'e' = { $_.id } }, * -ExcludeProperty id
                        }
                    }

                    409 {
                        throw "Webhook '$Name' already exists"
                    }

                    default {
                        throw $response
                    }
                }
            }
            catch {
                $PSCmdlet.ThrowTerminatingError($PSItem)
            }
        }
    }
}

