function ConvertTo-CmIdentity {
    <#
    .SYNOPSIS
    Convert identity to standard format

    .DESCRIPTION
    Convert identity to standard format

    .PARAMETER InputObject
    Identity object

    .INPUTS
    InputObject

    .OUTPUTS
    PSCustomObject

    .EXAMPLE
    $identityObj | ConvertTo-CmIdentity

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
            n = 'Name'
            e = { $_.Name }
        },
        @{
            n = 'ID'
            e = { $_.PrefixedUniversal }
        },
        @{
            n = 'Path'
            e = { $_.FullName }
        },
        @{
            n = 'FullName'
            e = { $_.PrefixedName }
        },
        @{
            n = 'IsGroup'
            e = { $_.Type -ne 1 }
        }, * -ExcludeProperty PrefixedUniversal, FullName, Prefix, PrefixedName, Type, Universal, IsGroup, Name
    }
}
