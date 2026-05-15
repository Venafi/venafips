function ConvertTo-Hashtable {
    <#
    .SYNOPSIS
    Convert a PSCustomObject to a hashtable, optionally recursing into nested objects.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [psobject] $InputObject,

        [Parameter()]
        [switch] $Recurse
    )

    process {
        $ht = @{}
        $InputObject.PSObject.Properties | ForEach-Object {
            if ( $Recurse -and $_.Value -is [System.Management.Automation.PSCustomObject] ) {
                $ht[$_.Name] = ConvertTo-Hashtable -InputObject $_.Value -Recurse
            }
            else {
                $ht[$_.Name] = $_.Value
            }
        }
        $ht
    }
}
