function Test-CmIdentityFormat {

    <#
    .SYNOPSIS
        Validate identity formats
    .DESCRIPTION
        Validate the format for identities prefixed name, prefixed universal, and local.
        As these formats are often interchangeable with api calls, you can validate multiple formats at once.
        By default, prefixed name and prefixed universal will be validated.
    .PARAMETER Identity
        The identity string to be validated
    .PARAMETER Format
        Format to validate, Name, Universal, and/or Local.
    .EXAMPLE
        Test-CmIdentityFormat -ID "AD+BigSur:cypher"

        Test the identity against all formats.  This would succeed for Name, but fail on Universal
    .EXAMPLE
        Test-CmIdentityFormat -ID "AD+BigSur:cypher" -Format Name

        Test the identity against a specific format.
    #>

    [CmdletBinding()]
    [OutputType([System.Boolean])]

    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string] $ID,

        [Parameter()]
        [ValidateSet('Name', 'Universal', 'Domain', 'Local')]
        [string] $Format
    )

    begin {
        $domainProviderRegex = '(?im)^(AD|LDAP)\+.+:'
        $localProviderRegex = '(?im)^local:'
        $nameRegex = '.+$'
        $universalRegex = '\{?([0-9A-F]{8}[-]?(?:[0-9A-F]{4}[-]?){3}[0-9A-F]{12})\}?$'
    }

    process {
        switch ( $Format ) {

            'Name' {
                $ID -match ($domainProviderRegex + $nameRegex) -or $ID -match ($localProviderRegex + $nameRegex)
            }

            'Universal' {
                $ID -match ($domainProviderRegex + $universalRegex) -or $ID -match ($localProviderRegex + $universalRegex)
            }

            'Domain' {
                $ID -match ($domainProviderRegex + $universalRegex) -or $ID -match ($domainProviderRegex + $nameRegex)
            }

            'Local' {
                $ID -match ($localProviderRegex + $universalRegex) -or $ID -match ($localProviderRegex + $nameRegex)
            }

            default {
                $ID -match ($domainProviderRegex + $universalRegex) -or $ID -match ($domainProviderRegex + $nameRegex) -or $ID -match ($localProviderRegex + $universalRegex) -or $ID -match ($localProviderRegex + $nameRegex)
            }
        }
    }
}
