function Get-VcData {

    <#
    .SYNOPSIS
        Helper function to get data from Venafi
        Although the name is 'vc', it is currently used for vc and vdc.  This is a todo.
    #>


    [CmdletBinding(DefaultParameterSetName = 'All')]
    # at some point we'll have types that overlap between products
    # use this alias to differentiate between vc and vdc
    [Alias('Get-VdcData')]

    param (
        [parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'ID', Position = '0')]
        [parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Name', Position = '0')]
        [parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Object', Position = '0')]
        [string] $InputObject,

        [parameter(Mandatory)]
        [ValidateSet('Application', 'VSatellite', 'Certificate', 'IssuingTemplate', 'Team', 'Machine', 'Tag', 'Plugin', 'Credential', 'Algorithm', 'User', 'CloudProvider')]
        [string] $Type,

        [parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Name')]
        [switch] $Name,

        [parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Object')]
        [switch] $Object,

        [parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'First')]
        [switch] $First,

        [parameter()]
        [switch] $Reload,

        [parameter()]
        [switch] $FailOnMultiple,

        [parameter()]
        [switch] $FailOnNotFound
    )

    begin {
        $idNameQuery = 'query MyQuery {{ {0} {{ nodes {{ id name }} }} }}'
        $platform = if ( $MyInvocation.InvocationName -eq 'Get-VdcData' ) {
            'vdc'
        }
        else {
            'vc'
        }
    }

    process {

        $latest = $false

        # if we already have a guid and are just looking for the ID, return it
        if ( $PSCmdlet.ParameterSetName -eq 'ID' -and (Test-IsGuid($InputObject)) ) {
            return $InputObject
        }

        if ( $PSCmdlet.ParameterSetName -in 'ID', 'Name' ) {
            switch ($Type) {
                { $_ -in 'Application', 'Team' } {
                    $gqltype = '{0}s' -f ($Type.Substring(0, 1).ToLower() + $Type.Substring(1))
                    $allObject = (Invoke-VcGraphQL -Query ($idNameQuery -f $gqltype)).$gqltype.nodes
                    $thisObject = $allObject | Where-Object { $InputObject -in $_.name, $_.id }
                    break
                }
            }
        }
        else {
            # object or first
            switch ($Type) {
                'Application' {
                    if ( -not $script:vcApplication ) {
                        $script:vcApplication = Get-VcApplication -All | Sort-Object -Property name
                    }
                    $allObject = $script:vcApplication
                    $thisObject = $allObject | Where-Object { $InputObject -in $_.name, $_.applicationId }
                    break
                }
                'Team' {
                    if ( -not $script:vcTeam ) {
                        $script:vcTeam = Get-VcTeam -All | Sort-Object -Property name
                    }
                    $allObject = $script:vcTeam
                    $thisObject = $allObject | Where-Object { $InputObject -in $_.name, $_.teamId }
                    break
                }
            }
        }

        switch ($Type) {
            'CloudProvider' {
                if ( -not $script:vcCloudProvider ) {
                    $script:vcCloudProvider = Get-VcCloudProvider -All | Sort-Object -Property name
                    $latest = $true
                }

                $allObject = $script:vcCloudProvider

                if ( $InputObject ) {
                    $thisObject = $allObject | Where-Object { $InputObject -in $_.name, $_.cloudProviderId }
                    if ( -not $thisObject -and -not $latest ) {
                        $script:vcCloudProvider = Get-VcCloudProvider -All | Sort-Object -Property name
                        $thisObject = $script:vcCloudProvider | Where-Object { $InputObject -in $_.name, $_.cloudProviderId }
                    }
                }

                break
            }

            'VSatellite' {
                if ( -not $script:vcSatellite ) {
                    $script:vcSatellite = Get-VcSatellite -All | Sort-Object -Property name
                    $latest = $true
                }

                $allObject = $script:vcSatellite

                if ( $InputObject ) {
                    $thisObject = $allObject | Where-Object { $InputObject -in $_.name, $_.vsatelliteId }
                    if ( -not $thisObject -and -not $latest ) {
                        $script:vcSatellite = Get-VcSatellite -All | Sort-Object -Property name
                        $thisObject = $script:vcSatellite | Where-Object { $InputObject -in $_.name, $_.vsatelliteId }
                    }
                }

                break
            }

            'IssuingTemplate' {
                if ( -not $script:vcIssuingTemplate ) {
                    $script:vcIssuingTemplate = Get-VcIssuingTemplate -All | Sort-Object -Property name
                    $latest = $true
                }

                $allObject = $script:vcIssuingTemplate

                if ( $InputObject ) {
                    $thisObject = $allObject | Where-Object { $InputObject -in $_.name, $_.issuingTemplateId }
                    if ( -not $thisObject -and -not $latest ) {
                        $script:vcIssuingTemplate = Get-VcIssuingTemplate -All | Sort-Object -Property name
                        $thisObject = $script:vcIssuingTemplate | Where-Object { $InputObject -in $_.name, $_.issuingTemplateId }
                    }
                }
                break
            }

            'Credential' {
                if ( -not $script:vcCredential ) {
                    $script:vcCredential = Invoke-VenafiRestMethod -UriLeaf "credentials" |
                        Select-Object -ExpandProperty credentials |
                        Select-Object -Property @{'n' = 'credentialId'; 'e' = { $_.Id } }, * -ExcludeProperty id
                    $latest = $true
                }

                $allObject = $script:vcCredential

                if ( $InputObject ) {
                    $thisObject = $allObject | Where-Object { $InputObject -in $_.name, $_.credentialId }
                    if ( -not $thisObject -and -not $latest ) {
                        $script:vcCredential = Invoke-VenafiRestMethod -UriLeaf "credentials" |
                            Select-Object -ExpandProperty credentials |
                            Select-Object -Property @{'n' = 'credentialId'; 'e' = { $_.Id } }, * -ExcludeProperty id
                        $thisObject = $script:vcCredential | Where-Object { $InputObject -in $_.name, $_.credentialId }
                    }
                }
                break
            }

            'Plugin' {
                if ( -not $script:vcPlugin ) {
                    $script:vcPlugin = Invoke-VenafiRestMethod -UriLeaf "plugins" |
                        Select-Object -ExpandProperty plugins |
                        Select-Object -Property @{'n' = 'pluginId'; 'e' = { $_.Id } }, * -ExcludeProperty id
                    $latest = $true
                }

                $allObject = $script:vcPlugin

                if ( $InputObject ) {
                    $thisObject = $allObject | Where-Object { $InputObject -in $_.name, $_.pluginId }
                    if ( -not $thisObject -and -not $latest ) {
                        $script:vcPlugin = Invoke-VenafiRestMethod -UriLeaf "plugins" |
                            Select-Object -ExpandProperty plugins |
                            Select-Object -Property @{'n' = 'pluginId'; 'e' = { $_.Id } }, * -ExcludeProperty id
                        $thisObject = $script:vcPlugin | Where-Object { $InputObject -in $_.name, $_.pluginId }
                    }
                }
                break
            }

            'User' {
                if ( -not $script:vcUser ) {
                    $script:vcUser = Get-VcUser -All | Sort-Object -Property username
                    $latest = $true
                }

                $allObject = $script:vcUser

                if ( $InputObject ) {
                    $thisObject = $allObject | Where-Object { $InputObject -in $_.userId, $_.username }
                    if ( -not $thisObject -and -not $latest ) {
                        $script:vcUser = Get-VcUser -All | Sort-Object -Property username
                        $thisObject = $script:vcTag | Where-Object { $InputObject -in $_.userId, $_.username }
                    }
                }
                break
            }

            'Certificate' {
                $thisObject = Find-VcCertificate -Name $InputObject
                break
            }

            'Machine' {
                $thisObject = Find-VcMachine -Name $InputObject
                break
            }

            'Tag' {
                if ( -not $script:vcTag ) {
                    $script:vcTag = Get-VcTag -All | Sort-Object -Property tagId
                    $latest = $true
                }

                $allObject = $script:vcTag

                if ( $InputObject ) {
                    $thisObject = $allObject | Where-Object tagId -eq $InputObject
                    if ( -not $thisObject -and -not $latest ) {
                        $script:vcTag = Get-VcTag -All | Sort-Object -Property tagId
                        $thisObject = $script:vcTag | Where-Object tagId -eq $InputObject
                    }
                }
                break
            }

            'Algorithm' {
                if ( -not $script:vdcAlgorithm ) {
                    $script:vdcAlgorithm = Invoke-VenafiRestMethod -UriLeaf 'algorithmselector/getglobalalgorithms' -Method Post -Body @{} |
                        Select-Object -ExpandProperty Selectors |
                        Select-Object -Property @{'n' = 'AlgorithmId'; 'e' = { $_.PkixParameterSetOid } }, @{'n' = 'Name'; 'e' = { $_.Algorithm } }, * -ExcludeProperty PkixParameterSetOid, Algorithm
                    $latest = $true
                }

                $allObject = $script:vdcAlgorithm

                if ( $InputObject ) {
                    $thisObject = $allObject | Where-Object { $InputObject -in $_.Name, $_.AlgorithmId }
                    if ( -not $thisObject -and -not $latest ) {
                        $script:vdcAlgorithm = Invoke-VenafiRestMethod -UriLeaf 'algorithmselector/getglobalalgorithms' -Method Post -Body @{} |
                            Select-Object -ExpandProperty Selectors |
                            Select-Object -Property @{'n' = 'AlgorithmId'; 'e' = { $_.PkixParameterSetOid } }, @{'n' = 'Name'; 'e' = { $_.Algorithm } }, * -ExcludeProperty PkixParameterSetOid, Algorithm
                        $thisObject = $script:vdcAlgorithm | Where-Object { $InputObject -in $_.Name, $_.AlgorithmId }
                    }
                }
                break
            }
        }

        $returnObject = if ( $InputObject ) {
            $thisObject
        }
        else {
            $allObject
        }

        if ( $FailOnMultiple -and @($returnObject).Count -gt 1 ) {
            throw "Multiple $Type found"
        }

        if ( $FailOnNotFound -and -not $returnObject ) {
            throw "$Type '$InputObject' not found"
        }

        switch ($PSCmdlet.ParameterSetName) {
            'ID' {
                if ( $returnObject ) {
                    if ( $returnObject.id ) {
                        # for the new graphql queries
                        $returnObject.id
                    }
                    else {
                        $returnObject."$("$Type")id"
                    }
                }
                else {
                    return $null
                }

                break
            }

            'Name' {
                switch ($Type) {
                    'Tag' { $InputObject }
                    { $_ -in 'Application', 'Team' } {
                        $returnObject.name
                    }
                }
                break
            }

            'Object' {
                $returnObject
                break
            }

            'First' {
                $returnObject | Select-Object -First 1
                break
            }

            'All' {
                $returnObject
                break
            }
        }
    }

    end {

    }
}
