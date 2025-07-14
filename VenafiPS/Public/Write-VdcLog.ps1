function Write-VdcLog {
    <#
    .SYNOPSIS
    Write entries to the TLSPDC log

    .DESCRIPTION
    Write entries to the log for custom event groups.
    It is not permitted to write to the default log.
    Ensure the group and event id are correct as the api will not fail if incorrect.

    .PARAMETER CustomEventGroup
    ID containing hex values between 0100-0299 referring to the created custom group.

    .PARAMETER EventId
    Event ID from within the EventGroup provided, a 4 character hex value.
    Only provide the 4 character event id, do not precede with group ID.

    .PARAMETER Component
    Path to the item this event is associated with

    .PARAMETER Severity
    Severity of the event

    .PARAMETER SourceIp
    The IP that originated the event

    .PARAMETER ComponentID
    Component ID that originated the event

    .PARAMETER ComponentSubsystem
    Component subsystem that originated the event

    .PARAMETER Text1
    String data to write to log.  See link for event ID messages for more info.

    .PARAMETER Text2
    String data to write to log.  See link for event ID messages for more info.

    .PARAMETER Value1
    Integer data to write to log.  See link for event ID messages for more info.

    .PARAMETER Value2
    Integer data to write to log.  See link for event ID messages for more info.

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.

    .INPUTS
    none

    .OUTPUTS
    none

    .EXAMPLE
    Write-VdcLog -CustomEventGroup '0200' -EventId '0001' -Component '\ved\policy\mycert.com'
    Log an event to a custom group

    .LINK
    https://venafi.github.io/VenafiPS/functions/Write-VdcLog/

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Write-VdcLog.ps1

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Log.php

    #>

    [CmdletBinding(SupportsShouldProcess)]
    [Alias('Write-TppLog')]

    param (

        [Parameter(Mandatory)]
        [ValidateScript({
            if ( $_ -match '^0[1-2]\d\d$' ) {
                $true
            } else {
                throw "$_ is an invalid group.  Custom event groups must be betwen 0100-0299."
            }
        })]
        [string] $CustomEventGroup,

        [Parameter(Mandatory)]
        [ValidateScript({
            if ( $_ -match '^[0-9a-fA-F]{4}$' ) {
                $true
            } else {
                throw "$_ is an invalid event ID.  Event IDs must be a 4 character hex value."
            }
        })]
        [string] $EventId,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $Component,

        [Parameter()]
        [TppEventSeverity] $Severity,

        [Parameter()]
        [ipaddress] $SourceIp,

        [Parameter()]
        [int] $ComponentID,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $ComponentSubsystem,

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
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    Test-VenafiSession $PSCmdlet.MyInvocation

    # the event id is the group id coupled with the event id
    $fullEventId = "$CustomEventGroup$EventId"

    # convert the hex based eventid to decimal equivalent
    $decEventId = [System.Convert]::ToInt64($fullEventId, 16)

    $params = @{

        Method     = 'Post'
        UriLeaf    = 'Log/'
        Body       = @{
            ID        = $decEventId
            Component = $Component
        }
    }

    if ( $PSBoundParameters.ContainsKey('Severity') ) {
        $params.Body.Add('Severity', [TppEventSeverity]::$Severity)
    }

    if ( $PSBoundParameters.ContainsKey('SourceIp') ) {
        $params.Body.Add('SourceIp', $SourceIp.ToString())
    }

    if ( $PSBoundParameters.ContainsKey('ComponentID') ) {
        $params.Body.Add('ComponentID', $ComponentID)
    }

    if ( $PSBoundParameters.ContainsKey('ComponentSubsystem') ) {
        $params.Body.Add('ComponentSubsystem', $ComponentSubsystem)
    }

    if ( $PSBoundParameters.ContainsKey('Text1') ) {
        $params.Body.Add('Text1', $Text1)
    }

    if ( $PSBoundParameters.ContainsKey('Text2') ) {
        $params.Body.Add('Text2', $Text2)
    }

    if ( $PSBoundParameters.ContainsKey('Value1') ) {
        $params.Body.Add('Value1', $Value1)
    }

    if ( $PSBoundParameters.ContainsKey('Value2') ) {
        $params.Body.Add('Value2', $Value2)
    }

    if ( $PSCmdlet.ShouldProcess($Component, 'Write log entry') ) {

        $response = Invoke-VenafiRestMethod @params

        if ( $response.LogResult -eq 1 ) {
            throw "Writing to the TLSPDC log failed.  Ensure you have View permission and Read permission to the default SQL channel object."
        }
    }
}

