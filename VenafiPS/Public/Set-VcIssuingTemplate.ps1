function Set-VcIssuingTemplate {
    <#
    .SYNOPSIS
    Update an existing issuing template

    .DESCRIPTION
    Update details of existing issuing templates.
    Additional properties will be available in the future.

    .PARAMETER IssuingTemplate
    The issuing template to update.  Specify either ID or name.

    .PARAMETER Name
    Provide a new name for the issuing template if you wish to change it.

    .PARAMETER Description
    Provide a new description for the issuing template if you wish to change it.

    .PARAMETER CertificateAuthority
    Update the certificate authority associated with this template.  Specify by name or ID.

    .PARAMETER ProductOption
    When updating the certificate authority, specify the product option to use as well.  Specify by name or ID.

    .PARAMETER PassThru
    Return the newly updated object

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, SaaS key can also provided.

    .INPUTS
    ID

    .OUTPUTS
    PSCustomObject

    .EXAMPLE
    Set-VcIssuingTemplate -IssuingTemplate 'DigiCert' -Name 'ThisNameIsBetter'

    Rename an existing issuing template

    .EXAMPLE
    Set-VcIssuingTemplate -IssuingTemplate 'MyTemplate' -CertificateAuthority 'GreatCA' -ProductOption 'BestOption'

    Change the certificate authority and product option associated with this template.  This will update all certificate requests using this template to use the new CA and product option as well.

    .EXAMPLE
    Set-VcIssuingTemplate -IssuingTemplate 'MyTemplate' -Description 'Updated description'

    Update the description for this template

    .EXAMPLE
    Get-VcIssuingTemplate -All -CA 'OldCA' | Set-VcIssuingTemplate -CertificateAuthority 'newCA' -ProductOption 'NewOption'

    Update all templates using a specific CA to use a new CA and product option
    #>

    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Base')]

    param (

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('issuingTemplateId', 'ID')]
        [string] $IssuingTemplate,

        [Parameter()]
        [string] $Name,

        [Parameter()]
        [string] $Description,

        [Parameter(Mandatory, ParameterSetName = 'CA')]
        [string] $CertificateAuthority,

        [Parameter(Mandatory, ParameterSetName = 'CA')]
        [string] $ProductOption,

        [Parameter()]
        [switch] $PassThru,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession = (Get-VenafiSession)
    )

    begin {

        switch ($PSBoundParameters.Keys ) {
            'CertificateAuthority' {
                $ca = $CertificateAuthority | Get-VcData -Type 'CertificateAuthority' -Object -FailOnNotFound
                $thisProductOption = $ca.productOptions | Where-Object { $ProductOption -in $_.id, $_.productName }
            }

            Default {}
        }
    }

    process {

        $thisTemplate = $IssuingTemplate | Get-VcData -Type 'IssuingTemplate' -Object

        if ( -not $thisTemplate ) {
            # process the next one in the pipeline if we don't have a valid ID this time
            Write-Error "Issuing Template $IssuingTemplate does not exist"
            Continue
        }

        $params = @{
            Method  = 'Put'
            UriLeaf = 'certificateissuingtemplates/{0}' -f $thisTemplate.issuingTemplateId
            Body    = @{
                keyTypes                            = $thisTemplate.keyTypes
                keyReuse                            = $thisTemplate.keyReuse
                name                                = $thisTemplate.name
                resourceConsumerUserIds             = $thisTemplate.resourceConsumerUserIds
                extendedKeyUsageValues              = $thisTemplate.extendedKeyUsageValues
                product                             = $thisTemplate.product
                certificateAuthority                = $thisTemplate.certificateAuthority
                keyGeneratedByVenafiAllowed         = $thisTemplate.keyGeneratedByVenafiAllowed
                csrUploadAllowed                    = $thisTemplate.csrUploadAllowed
                everyoneIsConsumer                  = $thisTemplate.everyoneIsConsumer
                certificateAuthorityProductOptionId = $thisTemplate.certificateAuthorityProductOptionId
                driverGeneratedCsr                  = $thisTemplate.driverGeneratedCsr
                description                         = $thisTemplate.description
                driverId                            = $thisTemplate.driverId
            }
        }

        switch ( $PSBoundParameters.Keys ) {

            'Name' {
                $params.Body.name = $Name
            }

            'Description' {
                $params.Body.description = $Description
            }

            'CertificateAuthority' {

                if ( -not $thisProductOption ) {
                    Write-Error "No product option found for certificate authority $CertificateAuthority matching $ProductOption"
                    return
                }

                $params.Body.certificateAuthority = $ca.type
                $params.Body.certificateAuthorityProductOptionId = $thisProductOption.Id
                $params.Body.product.certificateAuthority = $thisProductOption.productDetails.certificateAuthority
                $params.Body.product.productName = $thisProductOption.productDetails.productName
                $params.Body.product.productTypes = $thisProductOption.productDetails.productTypes
            }
        }

        if ( $PSCmdlet.ShouldProcess($thisTemplate.name, "Update issuing template") ) {
            $response = Invoke-VenafiRestMethod @params

            if ( $PassThru ) {
                $response
            }
        }

    }
}

