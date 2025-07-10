function Get-VdcPermission {
    <#
    .SYNOPSIS
    Get permissions for TLSPDC objects

    .DESCRIPTION
    Get permissions for users and groups on any object.
    The effective permissions will be retrieved by default, but inherited/explicit permissions can optionally be retrieved.
    You can retrieve all permissions for an object or for a specific user/group.

    .PARAMETER InputObject
    TppObject representing an object in TLSPDC, eg. from Find-VdcObject or Get-VdcObject

    .PARAMETER Path
    Full path to an object

    .PARAMETER Guid
    Guid representing a unique object

    .PARAMETER IdentityId
    Specifying this optional parameter will only return objects that have permissions assigned to this id.
    You can use Find-VdcIdentity to search for identities.

    .PARAMETER Explicit
    Get explicit (direct) and implicit (inherited) permissions instead of effective.

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.

    .INPUTS
    InputObject, Path, Guid, IdentityId

    .OUTPUTS
    PSCustomObject with the following properties:
        Path
        Guid
        Name
        TypeName
        IdentityId
        IdentityPath, may be null if the identity has been deleted
        IdentityName, may be null if the identity has been deleted
        EffectivePermissions (if Explicit switch is not used)
        ExplicitPermissions (if Explicit switch is used)
        ImplicitPermissions (if Explicit switch is used)

    .EXAMPLE
    Get-VdcPermission -Path '\VED\Policy\barron'

    Path                 : \ved\policy\barron
    Guid                 : 3ba630d8-acf0-4b52-9824-df549cb33b82
    Name                 : barron
    TypeName             : Policy
    IdentityId           : AD+domain:410aaf10ea816c4d823e9e05b1ad055d
    IdentityPath         : CN=Greg Brownstein,OU=Users,OU=Enterprise Administration,DC=domain,DC=net
    IdentityName         : greg
    EffectivePermissions : TppPermission

    Get all assigned effective permissions for users/groups on a specific policy folder

    .EXAMPLE
    Get-VdcObject -Path '\VED\Policy\My folder' | Get-VdcPermission

    Get all assigned effective permissions for users/groups on a specific policy folder by piping the object

    .EXAMPLE
    Get-VdcObject -Path '\VED\Policy\barron' | Get-VdcPermission -Explicit

    Path                : \ved\policy\barron
    Guid                : 3ba630d8-acf0-4b52-9824-df549cb33b82
    Name                : barron
    TypeName            : Policy
    IdentityId          : AD+domain:410aaf10ea816c4d823e9e05b1ad055d
    IdentityPath        : CN=Greg Brownstein,OU=Users,OU=Enterprise Administration,DC=domain,DC=net
    IdentityName        : greg
    ExplicitPermissions : TppPermission
    ImplicitPermissions : TppPermission

    Get explicit and implicit permissions for users/groups on a specific policy folder

    .EXAMPLE
    Find-VdcObject -Path '\VED' -Recursive | Get-VdcPermission -IdentityId 'AD+myprov:jasdf87s9dfsdfhkashfg78f7'

    Find assigned permissions for a specific user across all objects

    .LINK
    https://venafi.github.io/VenafiPS/functions/Get-VdcPermission/

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Get-VdcPermission.ps1

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Get-VdcIdentityAttribute.ps1

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-GET-Permissions-object-guid.php

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-GET-Permissions-object-guid-external.php

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-GET-Permissions-object-guid-local.php

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-GET-Permissions-object-guid-principal.php


    #>

    [CmdletBinding(DefaultParameterSetName = 'ByObject')]
    [Alias('Get-TppPermission')]

    param (

        [Parameter(Mandatory, ParameterSetName = 'ByObject', ValueFromPipeline)]
        [pscustomobject] $InputObject,

        [Parameter(Mandatory, ParameterSetName = 'ByPath', ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if ( $_ | Test-TppDnPath ) {
                    $true
                }
                else {
                    throw "'$_' is not a valid DN path"
                }
            })]
        [Alias('DN')]
        [String[]] $Path,

        [Parameter(Mandatory, ParameterSetName = 'ByGuid', ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('ObjectGuid')]
        [guid[]] $Guid,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript( {
                if ( $_ | Test-VdcIdentityFormat ) {
                    $true
                }
                else {
                    throw "'$_' is not a valid Identity format.  See https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-IdentityInformation.php."
                }
            })]
        [Alias('PrefixedUniversalId', 'ID')]
        [string[]] $IdentityId,

        [Parameter()]
        [Alias('ExplicitImplicit')]
        [switch] $Explicit,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation

        $params = @{

            Method        = 'Get'
            UriLeaf       = 'placeholder'
        }
    }

    process {

        switch ( $PsCmdLet.ParameterSetName) {
            'ByObject' {
                $newInputObject = $InputObject
            }

            'ByPath' {
                $newInputObject = $Path
            }

            'ByGuid' {
                $newInputObject = $Guid
            }

            Default {
                throw ('Unknown parameterset {0}' -f $PsCmdLet.ParameterSetName)
            }
        }

        foreach ( $thisInputObject in $newInputObject ) {

            switch ( $PsCmdLet.ParameterSetName) {
                'ByObject' {
                    $thisTppObject = $thisInputObject
                }

                Default {
                    $thisTppObject = $thisInputObject | ConvertTo-VdcObject
                }
            }

            $uriBase = ('Permissions/Object/{{{0}}}' -f $thisTppObject.Guid )
            $params.UriLeaf = $uriBase

            try {
                # get list of identities permissioned to this object
                $identities = Invoke-VenafiRestMethod @params
            }
            catch {
                Write-Error ('Couldn''t obtain list of permissions for {0}.  {1}' -f $thisTppObject.Path, $_ | Out-String)
                continue
            }

            # limit to specific identities provided
            if ( $PSBoundParameters.ContainsKey('IdentityId') ) {
                $identities = $identities | Where-Object { $_ -in $IdentityId }
            }

            foreach ( $thisId in $identities ) {

                Write-Verbose ('Path: {0}, Id: {1}' -f $thisTppObject.Path, $thisId)

                $params.UriLeaf = $uriBase

                if ( $thisId.StartsWith('local:') ) {
                    # format of local is local:universalId
                    $type, $id = $thisId.Split(':')
                    $params.UriLeaf += "/local/$id"
                }
                else {
                    # external source, eg. AD, LDAP
                    # format is type+name:universalId
                    $type, $name, $id = $thisId -Split { $_ -in '+', ':' }
                    $params.UriLeaf += "/$type/$name/$id"
                }

                if ( -not $Explicit.IsPresent ) {
                    $params.UriLeaf += '/Effective'
                }

                $thisReturnObject = [PSCustomObject] @{
                    Path         = $thisTppObject.Path
                    Guid         = $thisTppObject.Guid
                    Name         = $thisTppObject.Name
                    TypeName     = $thisTppObject.TypeName
                    IdentityId   = $thisId
                    IdentityPath = $null
                    IdentityName = $null
                }

                if ( $Explicit ) {
                    $thisReturnObject | Add-Member @{
                        ExplicitPermissions = $null
                        ImplicitPermissions = $null
                    }
                }
                else {
                    $thisReturnObject | Add-Member @{
                        EffectivePermissions = $null
                    }
                }

                try {

                    $response = Invoke-VenafiRestMethod @params

                    if ( $Explicit ) {
                        $thisReturnObject.ExplicitPermissions = [TppPermission] $response.ExplicitPermissions
                        $thisReturnObject.ImplicitPermissions = [TppPermission] $response.ImplicitPermissions
                    }
                    else {
                        $thisReturnObject.EffectivePermissions = [TppPermission] $response.EffectivePermissions
                    }

                    $attribParams = @{
                        IdentityId    = $thisReturnObject.IdentityId

                    }

                    $attribResponse = Get-VdcIdentityAttribute @attribParams -ErrorAction SilentlyContinue

                    if ( $attribResponse ) {
                        $thisReturnObject.IdentityPath = $attribResponse.Attributes.FullName
                        $thisReturnObject.IdentityName = $attribResponse.Attributes.Name
                    }
                }
                catch {
                    # handle edge case where permissions had been set, but the user account has been deleted
                    # this way we can return the permissions that are set, just not the identity attributes, eg. name
                    if ( $_ -like '*Unable to verify principal*' ) {
                        if ( $Explicit ) {
                            # this will only return explicit permissions, not effective
                            $notFoundParams = @{
                                Method  = 'Post'
                                UriLeaf = 'permissions/getpermissions'
                                Body    = @{
                                    ObjectDN  = $thisTppObject.Path
                                    Principal = $thisID
                                }
                            }

                            $notFoundResponse = invoke-venafirestmethod @notFoundParams

                            if ( $notFoundResponse.Permissions ) {
                                $thisReturnObject.ExplicitPermissions = [TppPermission]$notFoundResponse.Permissions
                            }
                        }
                    }
                    else {
                        Write-Error ('Unable to retrieve permissions.  Path: {0}, Id: {1}, Error: {2}' -f $thisTppObject.Path, $thisId, $_)
                    }
                }

                $thisReturnObject
            }
        }
    }
}


