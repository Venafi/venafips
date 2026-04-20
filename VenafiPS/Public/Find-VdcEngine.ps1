function Find-VdcEngine {
    <#
    .SYNOPSIS
    Find Certificate Manager, Self-Hosted engines using an optional pattern

    .DESCRIPTION
    Find Certificate Manager, Self-Hosted engines using an optional pattern.
    This function is an engine wrapper for Find-VdcObject.

    .PARAMETER Pattern
    Filter against engine names using asterisk (*) and/or question mark (?) wildcard characters.

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.

    .INPUTS
    Pattern

    .OUTPUTS
    VdcObject

    .EXAMPLE
    Find-VdcEngine -Pattern '*partialname*'

    Get engines whose name matches the supplied pattern

    .LINK
    https://venafi.github.io/VenafiPS/functions/Find-VdcEngine/

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Find-VdcEngine.ps1
    #>

    [CmdletBinding()]

    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [String] $Pattern,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient
    )

    begin {
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

