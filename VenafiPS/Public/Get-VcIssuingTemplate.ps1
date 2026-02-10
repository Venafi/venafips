function Get-VcIssuingTemplate {
    <#
    .SYNOPSIS
    Get issuing template info

    .DESCRIPTION
    Get 1 or more issuing template details

    .PARAMETER IssuingTemplate
    Issuing template ID or name

    .PARAMETER All
    Get all issuing templates

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, SaaS key can also provided.

    .INPUTS
    ID

    .EXAMPLE
    Get-VcIssuingTemplate -IssuingTemplate 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2'

    issuingTemplateId                   : 0a19eaf2-b22b-11ea-a1eb-a37c69eabd4e
    companyId                           : 09b24f81-b22b-11ea-91f3-ebd6dea5452f
    certificateAuthority                : BUILTIN
    name                                : Default
    certificateAuthorityAccountId       : 0a19eaf0-b22b-11ea-a1eb-a37c69eabd4e
    certificateAuthorityProductOptionId : 0a19eaf1-b22b-11ea-a1eb-a37c69eabd4e
    product                             : @{certificateAuthority=BUILTIN; productName=Default Product; productTypes=System.Object[]; validityPeriod=P90D}
    priority                            : 0
    systemGenerated                     : True
    creationDate                        : 6/19/2020 8:47:30 AM
    modificationDate                    : 6/19/2020 8:47:30 AM
    status                              : AVAILABLE
    reason                              :
    referencingApplicationIds           : {995d1fb0-67e9-11eb-a8a7-794fe75a8e6f}
    subjectCNRegexes                    : {.*}
    subjectORegexes                     : {.*}
    subjectOURegexes                    : {.*}
    subjectSTRegexes                    : {.*}
    subjectLRegexes                     : {.*}
    subjectCValues                      : {.*}
    sanRegexes                          : {.*}
    sanDnsNameRegexes                   : {.*}
    keyTypes                            : {@{keyType=RSA; keyLengths=System.Object[]}}
    keyReuse                            : False
    extendedKeyUsageValues              : {}
    csrUploadAllowed                    : True
    keyGeneratedByVenafiAllowed         : False
    resourceConsumerUserIds             : {}
    resourceConsumerTeamIds             : {}
    everyoneIsConsumer                  : True

    Get a single object by ID

    .EXAMPLE
    Get-VcIssuingTemplate -IssuingTemplate 'MyTemplate'

    Get a single object by name.  The name is case sensitive.

    .EXAMPLE
    Get-VcIssuingTemplate -All

    Get all issuing templates

    #>

    [CmdletBinding(DefaultParameterSetName='ID')]
    [Alias('Get-VaasIssuingTemplate')]

    param (

        [Parameter(Mandatory, ParameterSetName = 'ID', ValueFromPipelineByPropertyName, Position = 0)]
        [Alias('issuingTemplateId', 'ID')]
        [string] $IssuingTemplate,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch] $All,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation
    }

    process {

        $params = @{
            UriLeaf = 'certificateissuingtemplates'
        }

        if ( $PSBoundParameters.ContainsKey('IssuingTemplate') ) {
            if ( Test-IsGuid($IssuingTemplate) ) {
                $params.UriLeaf += "/{0}" -f $IssuingTemplate
            }
            else {
                # search by name
                return Get-VcIssuingTemplate -All | Where-Object { $_.name -eq $IssuingTemplate }
            }
        }

        try {
            $response = Invoke-VenafiRestMethod @params
        }
        catch {
            if ( $_.Exception.Response.StatusCode.value__ -eq 404 ) {
                # not found, return nothing
                return
            }
            else {
                throw $_
            }
        }

        if ( $response.PSObject.Properties.Name -contains 'certificateissuingtemplates' ) {
            $templates = $response | Select-Object -ExpandProperty certificateissuingtemplates
        }
        else {
            $templates = $response
        }

        if ( $templates ) {
            $templates | Select-Object -Property @{'n' = 'issuingTemplateId'; 'e' = { $_.id } }, * -ExcludeProperty id
        }
    }
}

