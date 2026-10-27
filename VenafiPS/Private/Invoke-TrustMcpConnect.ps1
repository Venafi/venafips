function Invoke-TrustMcpConnect {
    <#
    .SYNOPSIS
    Run the Start-TrustMcpServer Connect scriptblock and return the session it creates

    .DESCRIPTION
    Connect can return the session, eg. New-TrustClient -PassThru, or only store it, eg. New-TrustClient without -PassThru.
    Either way the new session becomes the module default session.
    All other output is written to stderr so it can't corrupt the stdio protocol.

    .PARAMETER Connect
    Scriptblock which creates the session

    .PARAMETER Session
    Existing session to update in place with the new one, eg. when reconnecting, so anything holding it keeps working.
    The existing session is returned.

    .OUTPUTS
    TrustClient, or nothing if Connect didn't create a session
    #>

    [CmdletBinding()]
    [OutputType([TrustClient])]
    param (
        [Parameter(Mandatory)]
        [scriptblock] $Connect,

        [Parameter()]
        [TrustClient] $Session
    )

    $before = $script:TrustClient
    $newClient = $null

    # capture all streams so nothing reaches stdout
    foreach ( $record in (& $Connect *>&1) ) {
        if ( $record -is [TrustClient] ) {
            $newClient = $record
        }
        else {
            [Console]::Error.WriteLine("$record")
        }
    }

    # New-TrustClient without -PassThru stores the new session instead of returning it
    if ( -not $newClient -and $script:TrustClient -and -not [object]::ReferenceEquals($script:TrustClient, $before) ) {
        $newClient = $script:TrustClient
    }

    if ( -not $newClient ) { return }

    if ( $Session ) {
        foreach ( $prop in $newClient.PSObject.Properties ) {
            $Session.($prop.Name) = $prop.Value
        }
        $newClient = $Session
    }

    $script:TrustClient = $newClient
    $newClient
}
