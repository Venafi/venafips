function Remove-VdcTeam {
    <#
    .SYNOPSIS
    Remove a team

    .DESCRIPTION
    Remove a team from Certificate Manager, Self-Hosted

    .PARAMETER ID
    Team ID, the "local" ID.

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.

    .INPUTS
    ID

    .EXAMPLE
    Remove-VdcTeam -ID 'local:{803f332e-7576-4696-a5a2-8ac6be6b14e6}'
    Remove a team

    .EXAMPLE
    Remove-VdcTeam -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -Confirm:$false
    Remove a team bypassing the confirmation prompt

    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]

    param (

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('PrefixedUniversal', 'Guid')]
        [string] $ID,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient
    )

    begin {
    }

    process {

        # check if just a guid or prefixed universal id
        if ( Test-VdcIdentityFormat -ID $ID -Format 'Local' ) {
            $guid = [guid]($ID.Replace('local:', ''))
        }
        else {
            try {
                $guid = [guid] $ID
            }
            catch {
                Write-Error "$ID is not a valid team id"
                Continue
            }
        }

        $params = @{
            Method  = 'Delete'
            UriLeaf = ('Teams/local/{{{0}}}' -f $guid.ToString())
        }

        if ( $PSCmdlet.ShouldProcess($ID, "Delete team") ) {
            $null = Invoke-TrustRestMethod @params
        }

    }
}


