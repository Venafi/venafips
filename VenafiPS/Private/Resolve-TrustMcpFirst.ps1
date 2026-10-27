function Resolve-TrustMcpFirst {
    <#
    .SYNOPSIS
    Resolve the number of results an MCP tool should return

    .PARAMETER Value
    Value requested by the client, if any

    .PARAMETER Default
    Value to use when one was not requested

    .PARAMETER Max
    Upper bound regardless of what was requested
    #>

    [CmdletBinding()]
    [OutputType([int])]
    param (
        [Parameter(Position = 0)]
        [AllowNull()]
        [object] $Value,

        [Parameter(Position = 1)]
        [int] $Default = 25,

        [Parameter(Position = 2)]
        [int] $Max = 200
    )

    if ( $null -eq $Value -or [int]$Value -lt 1 ) {
        return $Default
    }

    [System.Math]::Min([int]$Value, $Max)
}
