function Find-CmEngine {
    <#
    .SYNOPSIS
    Find Certificate Manager, Self-Hosted engines using an optional pattern

    .DESCRIPTION
    Find Certificate Manager, Self-Hosted engines using an optional pattern.
    This function is an engine wrapper for Find-CmObject.

    .PARAMETER Pattern
    Filter against engine names using asterisk (*) and/or question mark (?) wildcard characters.

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.

    .INPUTS
    Pattern

    .OUTPUTS
    CmObject

    .EXAMPLE
    Find-CmEngine -Pattern '*partialname*'

    Get engines whose name matches the supplied pattern

    .LINK
    https://venafi.github.io/VenafiPS/functions/Find-CmEngine/

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Find-CmEngine.ps1
    #>

    [Alias('Find-VdcEngine')]
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

        Find-CmObject @params
    }
}

