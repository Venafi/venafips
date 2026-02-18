function Remove-VcCloudProvider {
    <#
    .SYNOPSIS
    Remove a cloud provider

    .DESCRIPTION
    Remove a cloud provider

    .PARAMETER CloudProvider
    1 or more cloud provider IDs or names

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, SaaS key can also provided.

    .EXAMPLE
    Remove-VcCloudProvider -CloudProvider 'azure1', 'gcp2'

    Remove providers

    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]

    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('cloudProviderId')]
        [string[]] $CloudProvider,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {

        Test-VenafiSession $PSCmdlet.MyInvocation

        $query = 'mutation DeleteCloudProvider($cloudProviderId: [UUID!]!) {
                    deleteCloudProvider(cloudProviderId: $cloudProviderId)
                    }
                '
    }

    process {

        $variables = @{
            'cloudProviderId' = @($CloudProvider | Get-VcData -Type CloudProvider)
        }

        if ( $PSCmdlet.ShouldProcess(($CloudProvider -join ','), 'Remove cloud provider') ) {

            $null = Invoke-VcGraphQL -Query $query -Variables $variables

        }
    }
}

