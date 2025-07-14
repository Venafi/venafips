function Find-VdcEngine {
    <#
    .SYNOPSIS
    Find TLSPDC engines using an optional pattern

    .DESCRIPTION
    Find TLSPDC engines using an optional pattern.
    This function is an engine wrapper for Find-VdcObject.

    .PARAMETER Pattern
    Filter against engine names using asterisk (*) and/or question mark (?) wildcard characters.

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A TLSPDC token can also be provided, but this requires an environment variable VDC_SERVER to be set.

    .INPUTS
    Pattern

    .OUTPUTS
    TppObject

    .EXAMPLE
    Find-VdcEngine -Pattern '*partialname*'

    Get engines whose name matches the supplied pattern

    .LINK
    https://venafi.github.io/VenafiPS/functions/Find-VdcEngine/

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Find-VdcEngine.ps1
    #>

    [CmdletBinding()]
    [Alias('Find-TppEngine')]

    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [String] $Pattern,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation
    }

    process {
        $params = @{
            Class         = 'Venafi Platform'
            Path          = '\VED\Engines'
            Pattern       = $Pattern
        }

        Find-VdcObject @params
    }
}

