function Set-TrustApplication {
    <#
    .SYNOPSIS
    Update an existing application

    .DESCRIPTION
    Update details of existing applications.
    Additional properties will be available in the future.

    .PARAMETER Application
    The application to update.  Specify either ID or name.

    .PARAMETER Name
    Provide a new name for the application if you wish to change it.

    .PARAMETER TeamOwner
    Associate a team as an owner of this application

    .PARAMETER IssuingTemplate
    Associate one or more issuing templates by ID or name

    .PARAMETER NoOverwrite
    Append to existing details as opposed to overwriting

    .PARAMETER PassThru
    Return the newly updated object

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.

    .INPUTS
    ID

    .OUTPUTS
    PSCustomObject

    .EXAMPLE
    Set-TrustApplication -ID 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2' -Name 'ThisAppNameIsBetter'

    Rename an existing application

    .EXAMPLE
    Set-TrustApplication -ID 'MyApp' -TeamOwner 'GreatTeam'

    Change the owner to this team

    .EXAMPLE
    Set-TrustApplication -ID 'MyApp' -TeamOwner 'GreatTeam' -NoOverwrite

    Append this team to the list of owners

    .EXAMPLE
    Set-TrustApplication -ID 'MyApp' -IssuingTemplate 'Template1', 'Template2'

    Update the templates associated with application.  This will overwrite any existing templates configured.
    #>

    [CmdletBinding(SupportsShouldProcess)]
    [Alias('Set-VcApplication')]

    param (

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('applicationId')]
        [string] $Application,

        [Parameter()]
        [string] $Name,

        [Parameter()]
        [string[]] $TeamOwner,

        [Parameter()]
        [string[]] $IssuingTemplate,

        [Parameter()]
        [switch] $NoOverwrite,

        [Parameter()]
        [switch] $PassThru,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient
    )

    begin {

        $params = @{

            Method  = 'Put'
            UriRoot = 'outagedetection/v1'
            Body    = @{}
        }

        switch ($PSBoundParameters.Keys ) {
            'TeamOwner' {
                $allTeams = Get-TrustTeam -All
            }
            Default {}
        }
    }

    process {

        $thisApp = Get-TrustApplication -Application $Application

        if ( -not $thisApp ) {
            # process the next one in the pipeline if we don't have a valid ID this time
            Write-Error "Application $Application does not exist"
            Continue
        }

        $params.UriLeaf = 'applications/{0}' -f $thisApp.applicationId

        # set required fields to existing values by default
        $params.Body.name = if ( $Name ) {
            $Name
        }
        else {
            $thisApp.name
        }
        $params.Body.ownerIdsAndTypes = $thisApp.ownerIdsAndTypes

        switch ( $PSBoundParameters.Keys ) {
            'TeamOwner' {
                $params.Body.ownerIdsAndTypes = @()
                foreach ($owner in $TeamOwner ) {

                    if ( Test-IsGuid($owner) ) {
                        $thisOwner = $owner
                    }
                    else {
                        $thisOwner = $allTeams | Where-Object { $_.name -eq $owner } | Select-Object -ExpandProperty teamId
                    }

                    if ( $thisOwner ) {
                        $params.Body.ownerIdsAndTypes += @{
                            ownerId   = $thisOwner
                            ownerType = 'TEAM'
                        }
                    }
                    else {
                        Write-Error "Team $ID does not exist"
                    }
                }

                if ( $NoOverwrite -and $thisApp.ownerIdsAndTypes ) {
                    $params.Body.ownerIdsAndTypes += $thisApp.ownerIdsAndTypes
                }
            }

            'IssuingTemplate' {
                $newT = @{}
                # grab existing templates as our starting point if we're not overwriting
                # issuingTempate is of type PSNoteProperty so we need to iterate and add to hashtable
                if ( $NoOverwrite -and $thisApp.issuingTemplate ) {
                    $thisApp.issuingTemplate | ForEach-Object {
                        $newT[$_.name] = $_.issuingTemplateId
                    }
                }

                foreach ($template in $IssuingTemplate ) {
                    $t = Get-TrustIssuingTemplate -IssuingTemplate $template
                    if ( $t ) {
                        $newT[$t.name] = $t.issuingTemplateId
                    }
                    else {
                        Write-Error "Issuing template $template does not exist"
                    }
                }

                if ( $newT.Count -gt 0 ) {
                    $params.Body.certificateIssuingTemplateAliasIdMap = $newT

                }
            }
        }

        if ( $PSCmdlet.ShouldProcess($params.Body.name, "Update application") ) {
            $response = Invoke-TrustRestMethod @params
        }

        if ( $PassThru ) {
            $response | ConvertTo-VaasTeam
        }
    }
}

