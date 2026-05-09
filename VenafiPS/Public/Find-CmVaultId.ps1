function Find-CmVaultId {
    <#
    .SYNOPSIS
    Find vault IDs in the secret store

    .DESCRIPTION
    Find vault IDs in the secret store associated to an existing object.

    .PARAMETER Path
    Path of the object

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.

    .INPUTS
    Path

    .OUTPUTS
    String

    .EXAMPLE
    Find-CmVaultId -Path '\ved\policy\awesomeobject.cyberark.com'

    Find the vault IDs associated with an object.
    For certificates with historical references, the vault IDs will

    .LINK
    https://venafi.github.io/VenafiPS/functions/Find-CmVaultId/

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Find-CmVaultId.ps1

    #>

    [Alias('Find-VdcVaultId')]
    [CmdletBinding()]

    param (

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string] $Path,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient
    )

    begin {

        $params = @{

            Method  = 'Post'
            UriLeaf = 'SecretStore/LookupByOwner'
            Body    = @{
                'Namespace' = 'config'
            }
        }
    }

    process {

        $params.Body.Owner = $Path

        $response = Invoke-TrustRestMethod @params

        if ( $response.Result -eq 0 ) {
            [pscustomobject]@{
                'Path'    = $Path
                'VaultId' = $response.VaultIDs
            }
        }
        else {
            throw ('Secret store search failed with error code {0}' -f $response.Result)
        }
    }

    end {

    }
}

