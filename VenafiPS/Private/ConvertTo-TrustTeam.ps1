function ConvertTo-TrustTeam {
    <#
    .SYNOPSIS
    Convert vaas team to standard format

    .DESCRIPTION
    Convert vaas team to standard format

    .PARAMETER InputObject
    Team object

    .INPUTS
    InputObject

    .OUTPUTS
    PSCustomObject

    .EXAMPLE
    $teamObj | ConvertTo-TrustTeam

    #>

    [CmdletBinding()]

    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowNull()]
        [PSCustomObject[]] $InputObject
    )

    begin {
    }

    process {
        $InputObject | Select-Object -Property `
        @{
            n = 'teamId'
            e = { $_.id }
        }, * -ExcludeProperty id
    }
}
