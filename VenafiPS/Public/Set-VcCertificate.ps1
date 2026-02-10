function Set-VcCertificate {
    <#
    .SYNOPSIS
    Update a certificate

    .DESCRIPTION
    Associate one or more certificates with one or more applications or tags.
    The associated applications/tags can either replace or be added to existing.
    By default, applications/tags will be replaced.

    .PARAMETER Certificate
    Certificate ID or name to be associated.
    If a name is provided and multiple certificates are found, they will all be associated.
    Tab completion can be used for a list of certificate names to choose from.
    Type 3 or more characters for tab completion to work.

    .PARAMETER Application
    One or more application IDs or names.
    Tab completion can be used for a list of application names.

    .PARAMETER Tag
    One of more tag names or name/value pairs.
    To specify a name/value pair, use the format 'name:value'.

    .PARAMETER NoOverwrite
    Append to existing as opposed to overwriting

    .PARAMETER PassThru
    Return the newly updated certificate object(s)

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, SaaS key can also provided.

    .INPUTS
    Certificate

    .OUTPUTS
    PSCustomObject

    .EXAMPLE
    Add-VcCertificateAssociation -Certificate '7ac56ec0-2017-11ee-9417-a17dd25b82f9' -Application '96fc9310-67ec-11eb-a8a7-794fe75a8e6f'

    Associate a certificate to an application

    .EXAMPLE
    Add-VcCertificateAssociation -Certificate '7ac56ec0-2017-11ee-9417-a17dd25b82f9' -Application '96fc9310-67ec-11eb-a8a7-794fe75a8e6f', 'a05013bd-921d-440c-bc22-c9ead5c8d548'

    Associate a certificate to multiple applications

    .EXAMPLE
    Find-VcCertificate -First 5 | Add-VcCertificateAssociation -Application 'My Awesome App'

    Associate multiple certificates to 1 application by name

    .EXAMPLE
    Add-VcCertificateAssociation -Certificate '7ac56ec0-2017-11ee-9417-a17dd25b82f9' -Tag 'MyTagName'

    Associate a certificate to a tag

    .EXAMPLE
    Add-VcCertificateAssociation -Certificate '7ac56ec0-2017-11ee-9417-a17dd25b82f9' -Tag 'MyTagName:MyTagValue'

    Associate a certificate to a tag name/value pair

    .EXAMPLE
    Add-VcCertificateAssociation -Certificate '7ac56ec0-2017-11ee-9417-a17dd25b82f9' -Tag 'Tag1', 'MyTagName:MyTagValue'

    Associate a certificate to multiple tags

    .EXAMPLE
    Add-VcCertificateAssociation -Certificate 'www.barron.com' -Application '96fc9310-67ec-11eb-a8a7-794fe75a8e6f' -NoOverwrite

    Associate a certificate, by name, to an additonal application, keeping the existing application in place
    #>

    [CmdletBinding(DefaultParameterSetName = 'Application')]

    param (

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('certificateID')]
        [string] $Certificate,

        [Parameter(Mandatory, ParameterSetName = 'Application')]
        [Alias('applicationID')]
        [string[]] $Application,

        [Parameter(Mandatory, ParameterSetName = 'Tag')]
        [string[]] $Tag,

        [Parameter()]
        [switch] $NoOverwrite,

        [Parameter()]
        [switch] $PassThru,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Alias('Key')]
        [psobject] $VenafiSession
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation

        switch ($PSCmdlet.ParameterSetName) {
            'Application' {
                $apps = $Application | Get-VcData -Type 'Application' -FailOnNotFound

                $params = @{
                    Method  = 'Patch'
                    UriRoot = 'outagedetection/v1'
                    UriLeaf = 'applications/certificates'
                    Body    = @{
                        action                 = 'REPLACE'
                        targetedApplicationIds = @($apps)
                    }
                }

                if ( $NoOverwrite ) {
                    $params.Body.action = 'ADD'
                }
            }

            'Tag' {
                # ensure tags exist and have the correct case
                # tag assignment will fail if the tag name is not exact
                $tagNames = $Tag | Get-VcData -Type 'Tag' -Name -FailOnNotFound

                $params = @{
                    Method  = 'Patch'
                    UriLeaf = 'tagsassignment'
                    Body    = @{
                        action       = 'REPLACE'
                        targetedTags = @($tagNames)
                        entityType   = 'CERTIFICATE'
                    }
                }

                if ( $NoOverwrite ) {
                    $params.Body.action = 'ADD'
                }

            }
        }

        $allCerts = [System.Collections.Generic.List[string]]::new()
    }

    process {
        if ( Test-IsGuid($Certificate) ) {
            $allCerts.Add($Certificate)
        }
        else {
            # search by name
            $certIDs = Get-VcData -InputObject $Certificate -Type 'Certificate'
            foreach ($certID in @($certIDs)) {
                $allCerts.Add($certID)
            }
        }
    }

    end {
        switch ($PSCmdlet.ParameterSetName ) {
            'Application' {
                $params.Body.certificateIds = $allCerts

                $response = Invoke-VenafiRestMethod @params

                if ( $PassThru ) {
                    $response.certificates
                }
            }

            'Tag' {
                $params.Body.entityIds = $allCerts

                $response = Invoke-VenafiRestMethod @params

                if ( $PassThru ) {
                    $response.tagsAssignInformation | Select-Object -Property @{'n' = 'certificateId'; 'e' = { $_.entityId } }, * -ExcludeProperty entityId, entityType
                }
            }
        }
    }
}


