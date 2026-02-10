function Remove-VcCloudKeystore {
    <#
    .SYNOPSIS
    Remove a cloud keystore

    .DESCRIPTION
    Remove a cloud keystore

    .PARAMETER CloudKeystore
    1 or more cloud keystore IDs or names

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, SaaS key can also provided.

    .EXAMPLE
    Remove-VcCloudKeystore -CloudKeystore 'acm1', 'gcm2'

    Remove keystores

    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]

    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('cloudKeystoreId')]
        [string[]] $CloudKeystore,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {

        Test-VenafiSession $PSCmdlet.MyInvocation

        $query = 'mutation DeleteCloudKeystore($cloudKeystoreIds: [UUID!]!) {
                    deleteCloudKeystore(cloudKeystoreIds: $cloudKeystoreIds)
                    }
                '
    }

    process {

        $variables = @{
            'cloudKeystoreIds' = @($CloudKeystore | Get-VcData -Type CloudKeystore)
        }

        if ( $PSCmdlet.ShouldProcess(($CloudKeystore -join ','), 'Remove cloud keystore') ) {

            $null = Invoke-VcGraphQL -Query $query -Variables $variables

        }
    }
}

