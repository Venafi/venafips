function Remove-TrustCloudKeystore {
    <#
    .SYNOPSIS
    Remove a cloud keystore

    .DESCRIPTION
    Remove a cloud keystore

    .PARAMETER CloudKeystore
    1 or more cloud keystore IDs or names

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.

    .EXAMPLE
    Remove-TrustCloudKeystore -CloudKeystore 'acm1', 'gcm2'

    Remove keystores

    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [Alias('Remove-VcCloudKeystore')]

    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('cloudKeystoreId')]
        [string[]] $CloudKeystore,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient
    )

    begin {


        $query = 'mutation DeleteCloudKeystore($cloudKeystoreIds: [UUID!]!) {
                    deleteCloudKeystore(cloudKeystoreIds: $cloudKeystoreIds)
                    }
                '
    }

    process {

        $variables = @{
            'cloudKeystoreIds' = @($CloudKeystore | Get-TrustData -Type CloudKeystore)
        }

        if ( $PSCmdlet.ShouldProcess(($CloudKeystore -join ','), 'Remove cloud keystore') ) {

            $null = Invoke-TrustGraphQL -Query $query -Variables $variables

        }
    }
}

