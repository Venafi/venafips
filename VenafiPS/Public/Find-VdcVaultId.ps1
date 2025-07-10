function Find-VdcVaultId {
    <#
    .SYNOPSIS
    Find vault IDs in the secret store

    .DESCRIPTION
    Find vault IDs in the secret store associated to an existing object.

    .PARAMETER Path
    Path of the object

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.

    .INPUTS
    Path

    .OUTPUTS
    String

    .EXAMPLE
    Find-VdcVaultId -Path '\ved\policy\awesomeobject.cyberark.com'

    Find the vault IDs associated with an object.
    For certificates with historical references, the vault IDs will

    .LINK
    https://venafi.github.io/VenafiPS/functions/Find-VdcVaultId/

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Find-VdcVaultId.ps1

    #>

    [CmdletBinding()]

    param (

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string] $Path,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation

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

        $response = Invoke-VenafiRestMethod @params

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

