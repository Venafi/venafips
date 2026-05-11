function Get-TrustData {

    <#
    .SYNOPSIS
        Helper function to get data from Venafi
        Although the name is 'vc', it is currently used for vc and cm.  This is a todo.
    #>


    [CmdletBinding(DefaultParameterSetName = 'All')]
    # at some point we'll have types that overlap between products
    # use this alias to differentiate between vc and cm
    [Alias('Get-CmData')]

    param (
        [parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'ID', Position = '0')]
        [parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Name', Position = '0')]
        [parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Object', Position = '0')]
        [string] $InputObject,

        [parameter(Mandatory)]
        [ValidateSet('Application', 'VSatellite', 'Certificate', 'IssuingTemplate', 'Team', 'Machine', 'Tag', 'Plugin', 'Credential', 'Algorithm', 'User', 'CloudProvider', 'CloudKeystore', 'CertificateAuthority', 'MachineIdentity')]
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
        $platform = if ( $MyInvocation.InvocationName -eq 'Get-CmData' ) {
            'cm'
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
                    $allObject = (Invoke-TrustGraphQL -Query ($idNameQuery -f $gqltype)).$gqltype.nodes
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
                        $script:vcApplication = Get-CmsApplication -All | Sort-Object -Property name
                    }
                    $allObject = $script:vcApplication
                    if ( $InputObject ) {
                    $thisObject = $allObject | Where-Object { $InputObject -in $_.name, $_.applicationId }
                        if ( -not $thisObject -and -not $latest ) {
                        $script:vcApplication = Get-CmsApplication -All | Sort-Object -Property name
                            $thisObject = $script:vcApplication | Where-Object { $InputObject -in $_.name, $_.applicationId }
                        }
                    }
                    break
                }
                'Team' {
                    if ( -not $script:vcTeam ) {
                        $script:vcTeam = Get-CmsTeam -All | Sort-Object -Property name
                    }
                    $allObject = $script:vcTeam

                    if ( $InputObject ) {
                        $thisObject = $allObject | Where-Object { $InputObject -in $_.name, $_.teamId }
                        if ( -not $thisObject -and -not $latest ) {
                            $script:vcTeam = Get-CmsTeam -All | Sort-Object -Property name
                            $thisObject = $script:vcTeam | Where-Object { $InputObject -in $_.name, $_.teamId }
                        }
                    }
                    break
                }
            }
        }

        switch ($Type) {
            'CloudKeystore' {
                if ( -not $script:vcCloudKeystore ) {
                    $script:vcCloudKeystore = Get-TrustCloudKeystore -All | Sort-Object -Property name
                    $latest = $true
                }

                $allObject = $script:vcCloudKeystore

                if ( $InputObject ) {
                    $thisObject = $allObject | Where-Object { $InputObject -in $_.name, $_.cloudKeystoreId }
                    if ( -not $thisObject -and -not $latest ) {
                        $script:vcCloudKeystore = Get-TrustCloudKeystore -All | Sort-Object -Property name
                        $thisObject = $script:vcCloudKeystore | Where-Object { $InputObject -in $_.name, $_.cloudKeystoreId }
                    }
                }

                break
            }

            'CloudProvider' {
                if ( -not $script:vcCloudProvider ) {
                    $script:vcCloudProvider = Get-TrustCloudProvider -All | Sort-Object -Property name
                    $latest = $true
                }

                $allObject = $script:vcCloudProvider

                if ( $InputObject ) {
                    $thisObject = $allObject | Where-Object { $InputObject -in $_.name, $_.cloudProviderId }
                    if ( -not $thisObject -and -not $latest ) {
                        $script:vcCloudProvider = Get-TrustCloudProvider -All | Sort-Object -Property name
                        $thisObject = $script:vcCloudProvider | Where-Object { $InputObject -in $_.name, $_.cloudProviderId }
                    }
                }

                break
            }

            'VSatellite' {
                if ( -not $script:vcSatellite ) {
                    $script:vcSatellite = Get-TrustSatellite -All | Sort-Object -Property name
                    $latest = $true
                }

                $allObject = $script:vcSatellite

                if ( $InputObject ) {
                    $thisObject = $allObject | Where-Object { $InputObject -in $_.name, $_.vsatelliteId }
                    if ( -not $thisObject -and -not $latest ) {
                        $script:vcSatellite = Get-TrustSatellite -All | Sort-Object -Property name
                        $thisObject = $script:vcSatellite | Where-Object { $InputObject -in $_.name, $_.vsatelliteId }
                    }
                }

                break
            }

            'IssuingTemplate' {
                if ( -not $script:vcIssuingTemplate ) {
                    $script:vcIssuingTemplate = Get-TrustIssuingTemplate -All | Sort-Object -Property name
                    $latest = $true
                }

                $allObject = $script:vcIssuingTemplate

                if ( $InputObject ) {
                    $thisObject = $allObject | Where-Object { $InputObject -in $_.name, $_.issuingTemplateId }
                    if ( -not $thisObject -and -not $latest ) {
                        $script:vcIssuingTemplate = Get-TrustIssuingTemplate -All | Sort-Object -Property name
                        $thisObject = $script:vcIssuingTemplate | Where-Object { $InputObject -in $_.name, $_.issuingTemplateId }
                    }
                }
                break
            }

            'CertificateAuthority' {
                if ( -not $script:vcCertificateAuthority ) {
                    $script:vcCertificateAuthority = Get-TrustCertificateAuthority -All | Sort-Object -Property name
                    $latest = $true
                }

                $allObject = $script:vcCertificateAuthority

                if ( $InputObject ) {
                    $thisObject = $allObject | Where-Object { $InputObject -in $_.name, $_.certificateAuthorityId }
                    if ( -not $thisObject -and -not $latest ) {
                        $script:vcCertificateAuthority = Get-TrustCertificateAuthority -All | Sort-Object -Property name
                        $thisObject = $script:vcCertificateAuthority | Where-Object { $InputObject -in $_.name, $_.certificateAuthorityId }
                    }
                }
                break
            }

            'Credential' {
                if ( -not $script:vcCredential ) {
                    $script:vcCredential = Invoke-TrustRestMethod -UriLeaf "credentials" |
                        Select-Object -ExpandProperty credentials |
                        Select-Object -Property @{'n' = 'credentialId'; 'e' = { $_.Id } }, * -ExcludeProperty id
                    $latest = $true
                }

                $allObject = $script:vcCredential

                if ( $InputObject ) {
                    $thisObject = $allObject | Where-Object { $InputObject -in $_.name, $_.credentialId }
                    if ( -not $thisObject -and -not $latest ) {
                        $script:vcCredential = Invoke-TrustRestMethod -UriLeaf "credentials" |
                            Select-Object -ExpandProperty credentials |
                            Select-Object -Property @{'n' = 'credentialId'; 'e' = { $_.Id } }, * -ExcludeProperty id
                        $thisObject = $script:vcCredential | Where-Object { $InputObject -in $_.name, $_.credentialId }
                    }
                }
                break
            }

            'Plugin' {
                if ( -not $script:vcPlugin ) {
                    $script:vcPlugin = Invoke-TrustRestMethod -UriLeaf "plugins" |
                        Select-Object -ExpandProperty plugins |
                        Select-Object -Property @{'n' = 'pluginId'; 'e' = { $_.Id } }, * -ExcludeProperty id
                    $latest = $true
                }

                $allObject = $script:vcPlugin

                if ( $InputObject ) {
                    $thisObject = $allObject | Where-Object { $InputObject -in $_.name, $_.pluginId }
                    if ( -not $thisObject -and -not $latest ) {
                        $script:vcPlugin = Invoke-TrustRestMethod -UriLeaf "plugins" |
                            Select-Object -ExpandProperty plugins |
                            Select-Object -Property @{'n' = 'pluginId'; 'e' = { $_.Id } }, * -ExcludeProperty id
                        $thisObject = $script:vcPlugin | Where-Object { $InputObject -in $_.name, $_.pluginId }
                    }
                }
                break
            }

            'User' {
                if ( -not $script:vcUser ) {
                    $script:vcUser = Get-CmsUser -All | Sort-Object -Property username
                    $latest = $true
                }

                $allObject = $script:vcUser

                if ( $InputObject ) {
                    $thisObject = $allObject | Where-Object { $InputObject -in $_.userId, $_.username }
                    if ( -not $thisObject -and -not $latest ) {
                        $script:vcUser = Get-CmsUser -All | Sort-Object -Property username
                        $thisObject = $script:vcTag | Where-Object { $InputObject -in $_.userId, $_.username }
                    }
                }
                break
            }

            'Certificate' {
                if ( $InputObject ) {
                    $allObject = Find-TrustCertificate -Name $InputObject
                    $thisObject = $allObject | Where-Object { $InputObject -in $_.certificateName, $_.certificateId }
                }
                else {
                    $allObject = Find-TrustCertificate
                }
                break
            }

            'Machine' {
                if ( $InputObject ) {
                    $allObject = Find-TrustMachine -Name $InputObject
                    $thisObject = $allObject | Where-Object { $InputObject -in $_.name, $_.machineId }
                }
                else {
                    $allObject = Find-TrustMachine
                }
                break
            }

            'MachineIdentity' {
                if ( $InputObject ) {
                    $thisObject = Get-TrustMachineIdentity -MachineIdentity $InputObject
                }
                else {
                    $allObject = Find-TrustMachineIdentity
                }
                break
            }

            'Tag' {
                if ( -not $script:vcTag ) {
                    $script:vcTag = Get-TrustTag -All | Sort-Object -Property tagId
                    $latest = $true
                }

                $allObject = $script:vcTag

                if ( $InputObject ) {
                    # tags can be specified as name or name:value
                    # ensure it exists either way
                    if ( $InputObject.Contains(':') ) {
                        $key, $value = $InputObject.Split(':', 2)
                        $thisObject = $allObject | Where-Object { $_.tagId -eq $key -and $value -in $_.value }
                    }
                    else {
                        $thisObject = $allObject | Where-Object tagId -eq $InputObject
                    }
                    if ( -not $thisObject -and -not $latest ) {
                        $script:vcTag = Get-TrustTag -All | Sort-Object -Property tagId
                        if ( $InputObject.Contains(':') ) {
                            $key, $value = $InputObject.Split(':', 2)
                            $thisObject = $allObject | Where-Object { $_.tagId -eq $key -and $value -in $_.value }
                        }
                        else {
                            $thisObject = $allObject | Where-Object tagId -eq $InputObject
                        }
                    }
                }
                break
            }

            'Algorithm' {
                if ( -not $script:cmAlgorithm ) {
                    $script:cmAlgorithm = Invoke-TrustRestMethod -UriLeaf 'algorithmselector/getglobalalgorithms' -Method Post -Body @{} |
                        Select-Object -ExpandProperty Selectors |
                        Select-Object -Property @{'n' = 'AlgorithmId'; 'e' = { $_.PkixParameterSetOid } }, @{'n' = 'Name'; 'e' = { $_.Algorithm } }, * -ExcludeProperty PkixParameterSetOid, Algorithm
                    $latest = $true
                }

                $allObject = $script:cmAlgorithm

                if ( $InputObject ) {
                    $thisObject = $allObject | Where-Object { $InputObject -in $_.Name, $_.AlgorithmId }
                    if ( -not $thisObject -and -not $latest ) {
                        $script:cmAlgorithm = Invoke-TrustRestMethod -UriLeaf 'algorithmselector/getglobalalgorithms' -Method Post -Body @{} |
                            Select-Object -ExpandProperty Selectors |
                            Select-Object -Property @{'n' = 'AlgorithmId'; 'e' = { $_.PkixParameterSetOid } }, @{'n' = 'Name'; 'e' = { $_.Algorithm } }, * -ExcludeProperty PkixParameterSetOid, Algorithm
                        $thisObject = $script:cmAlgorithm | Where-Object { $InputObject -in $_.Name, $_.AlgorithmId }
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
            throw [System.InvalidOperationException]::new('Multiple {0}s found' -f $Type)
        }

        if ( $FailOnNotFound -and -not $returnObject ) {
            throw [System.Management.Automation.ItemNotFoundException]::new("$Type '$InputObject' not found")
        }

        switch ($PSCmdlet.ParameterSetName) {
            'ID' {
                if ( $returnObject ) {
                    if ( $returnObject.PSObject.Properties.Name -contains 'id' ) {
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
                    'Tag' {
                        $InputObject
                    }

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
