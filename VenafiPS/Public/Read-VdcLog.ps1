function Read-VdcLog {
    <#
    .SYNOPSIS
    Read entries from the Certificate Manager, Self-Hosted log

    .DESCRIPTION
    Read entries from the Certificate Manager, Self-Hosted log.

    .PARAMETER Path
    Path to search for related records

    .PARAMETER EventId
    Event ID as found in Logging->Event Definitions

    .PARAMETER Severity
    Filter records by severity

    .PARAMETER StartTime
    Start time of events

    .PARAMETER EndTime
    End time of events

    .PARAMETER Text1
    Filter matching results of Text1

    .PARAMETER Text2
    Filter matching results of Text2

    .PARAMETER Value1
    Filter matching results of Value1

    .PARAMETER Value2
    Filter matching results of Value2

    .PARAMETER First
    Return only these number of records

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, Self-Hosted token can also provided.
    If providing a Certificate Manager, Self-Hosted token, an environment variable named VDC_SERVER must also be set.

    .INPUTS
    Path

    .OUTPUTS
    PSCustomObject
        EventId
        ClientTimestamp
        Component
        ComponentId
        ComponentSubsystem
        Data
        Grouping
        Id
        Name
        ServerTimestamp
        Severity
        SourceIP
        Text1
        Text2
        Value1
        Value2

    .EXAMPLE
    Read-VdcLog -First 10

    Get the most recent 10 log items

    .EXAMPLE
    $capiObject | Read-VdcLog

    Find all events for a specific object

    .EXAMPLE
    Read-VdcLog -EventId '00130003'

    Find all events with event ID '00130003', Certificate Monitor - Certificate Expiration Notice

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-GET-Log.php

    #>

    [CmdletBinding()]

    param (

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript( {
                if ( $_ | Test-TppDnPath ) {
                    $true
                }
                else {
                    throw "'$_' is not a valid DN path"
                }
            })]
        [Alias('DN')]
        [string] $Path,

        [Parameter()]
        [string] $EventId,

        [Parameter()]
        [TppEventSeverity] $Severity,

        [Parameter()]
        [DateTime] $StartTime,

        [Parameter()]
        [DateTime] $EndTime,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $Text1,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $Text2,

        [Parameter()]
        [int] $Value1,

        [Parameter()]
        [int] $Value2,

        [Parameter()]
        [int] $First,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {

        Test-VenafiSession $PSCmdlet.MyInvocation

        $params = @{
            Method        = 'Get'
            UriLeaf       = 'Log/'
            Body          = @{ }
        }

        switch ($PSBoundParameters.Keys) {

            'EventId' {
                $params.Body.Add('Id', [uint32]('0x{0}' -f $EventId))
            }

            'Severity' {
                $params.Body.Add('Severity', $Severity)
            }

            'StartTime' {
                $params.Body.Add('FromTime', ($StartTime | ConvertTo-UtcIso8601) )
            }

            'EndTime' {
                $params.Body.Add('ToTime', ($EndTime | ConvertTo-UtcIso8601) )
            }

            'Text1' {
                $params.Body.Add('Text1', $Text1)
            }

            'Text2' {
                $params.Body.Add('Text2', $Text2)
            }

            'Value1' {
                $params.Body.Add('Value1', $Value1)
            }

            'Value2' {
                $params.Body.Add('Value2', $Value2)
            }

            'First' {
                $params.Body.Add('Limit', $First)
            }
        }
    }

    process {

        if ( $PSBoundParameters.ContainsKey('Path') ) {
            $params.Body.Component = $Path
        }

        Invoke-VenafiRestMethod @params |
        Select-Object -ExpandProperty LogEvents |
        Select-Object -Property @{'n' = 'EventId'; 'e' = { '{0:x8}' -f $_.Id } }, *
    }
}

