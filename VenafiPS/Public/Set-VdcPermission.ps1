function Set-VdcPermission {
    <#
    .SYNOPSIS
    Set explicit permissions for Certificate Manager, Self-Hosted objects

    .DESCRIPTION
    Adds, modifies, or removes explicit permissions on Certificate Manager, Self-Hosted objects.
    You can provide a complete permission object or modify individual permissions.

    .PARAMETER Path
    Path to an object

    .PARAMETER Guid
    Guid representing a unique object

    .PARAMETER IdentityId
    The id that represents the user or group.  You can use Find-VdcIdentity or Get-VdcPermission to get the id.

    .PARAMETER Permission
    TppPermission object to set.
    You can create a new object and modify it or get an existing object with Get-VdcPermission.

    .PARAMETER Force
    When setting a TppPermission object with -Permission and one already exists, use this to overwrite

    .PARAMETER IsAssociateAllowed
    Associate or disassociate an Application and Device object with a certificate.
    Push the certificate and private key to the Application object.
    Retry the certificate installation.

    .PARAMETER IsCreateAllowed
    The caller can create subordinate objects, such as Devices and Applications. Create permission grants implicit View permission.

    .PARAMETER IsDeleteAllowed
    The caller can delete objects.

    .PARAMETER IsManagePermissionsAllowed
    The caller can grant other user or group Identities permission to the current object or subordinate objects.

    .PARAMETER IsPolicyWriteAllowed
    The caller can modify policy values on folders.
    Also requires View permission.
    Manage Policy permission grants implicit Read permission and Write permission.

    .PARAMETER IsPrivateKeyReadAllowed
    The caller can download the private key for Policy and Certificate objects.

    .PARAMETER IsPrivateKeyWriteAllowed
    The caller can upload the private key for Policy, Certificate, and Private Key Credential objects to Trust Protection Platform.

    .PARAMETER IsReadAllowed
    The caller can view and read object data from the Policy tree.
    However, to view subordinate objects, View permission or higher permissions is also required.

    .PARAMETER IsRenameAllowed
    The caller can rename and move Policy tree objects.
    Move capability also requires Rename permission to the object and Create permission to the target folder.

    .PARAMETER IsRevokeAllowed
    The caller can invalidate a certificate.
    Also requires Write permission to the certificate.

    .PARAMETER IsViewAllowed
    The caller can confirm that the object is present in the Policy tree.

    .PARAMETER IsWriteAllowed
    The caller can edit object attributes.
    To move objects in the tree, the caller must have Write permission to the objects and Create permission to the target folder.
    Write permission grants implicit Read permission.

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.

    .INPUTS
    Guid, IdentityId, Permission

    .OUTPUTS
    None

    .EXAMPLE
    Set-VdcPermission -Guid '1234abcd-g6g6-h7h7-faaf-f50cd6610cba' -IdentityId 'AD+mydomain.com:azsxdcfvgbhnjmlk09877654321' -Permission $TppPermObject

    Permission a user/group on an object specified by guid

    .EXAMPLE
    Set-VdcPermission -Path '\ved\policy\my folder' -IdentityId 'AD+mydomain.com:azsxdcfvgbhnjmlk09877654321' -Permission $TppPermObject

    Permission a user/group on an object specified by path

    .EXAMPLE
    Get-VdcPermission -Path '\ved\policy\my folder' -IdentityId 'AD+mydomain.com:azsxdcfvgbhnjmlk09877654321' -Explicit | Set-VdcPermission -IdentityId $newId

    Permission a user/group based on permissions of an existing user/group

    .EXAMPLE
    Get-VdcPermission -Path '\ved\policy\my folder' -IdentityId 'AD+mydomain.com:azsxdcfvgbhnjmlk09877654321' -Explicit | Set-VdcPermission -IsWriteAllowed

    Add specific permission(s) for a specific user/group associated with an object

    .EXAMPLE
    Get-VdcPermission -Path '\ved\policy\my folder' -Explicit | Set-VdcPermission -IsAssociateAllowed -IsWriteAllowed

    Add specific permission(s) for all existing user/group associated with an object

    .EXAMPLE
    Get-VdcPermission -Path '\ved\policy\my folder' -Explicit | Set-VdcPermission -IsAssociateAllowed:$false

    Remove specific permission(s) for all existing user/group associated with an object

    .EXAMPLE
    $id = Find-VdcIdentity -Name 'brownstein' | Select-Object -ExpandProperty Id
    Find-VdcObject -Path '\VED' -Recursive | Get-VdcPermission -IdentityId $id | Set-VdcPermission -Permission $TppPermObject -Force

    Reset permissions for a specific user/group for all objects.  Note the use of -Force to overwrite existing permissions.

    .LINK
    https://venafi.github.io/VenafiPS/functions/Set-VdcPermission/

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Set-VdcPermission.ps1

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Permissions-object-guid-principal.php

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-PUT-Permissions-object-guid-principal.php

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-Permissions-Effective.php

    .NOTES
    Confirmation impact is set to Medium, set ConfirmPreference accordingly.
    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium', DefaultParameterSetName = 'PermissionObjectGuid')]
    [Alias('Set-TppPermission')]

    param (
        [Parameter(Mandatory, ParameterSetName = 'PermissionObjectPath')]
        [Parameter(Mandatory, ParameterSetName = 'PermissionPath')]
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
        [String] $Path,

        [Parameter(Mandatory, ParameterSetName = 'PermissionObjectGuid', ValueFromPipelineByPropertyName)]
        [Parameter(Mandatory, ParameterSetName = 'PermissionGuid', ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('ObjectGuid')]
        [guid] $Guid,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateScript( {
                if ( $_ | Test-VdcIdentityFormat -Format 'Universal' ) {
                    $true
                }
                else {
                    throw "'$_' is not a valid Prefixed Universal Id format.  See https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-IdentityInformation.php."
                }
            })]
        [Alias('PrefixedUniversalId', 'ID')]
        [string] $IdentityId,

        [Parameter(Mandatory, ParameterSetName = 'PermissionObjectPath', ValueFromPipelineByPropertyName)]
        [Parameter(Mandatory, ParameterSetName = 'PermissionObjectGuid', ValueFromPipelineByPropertyName)]
        [Alias('ExplicitPermissions')]
        [TppPermission] $Permission,

        [Parameter(ParameterSetName = 'PermissionPath')]
        [Parameter(ParameterSetName = 'PermissionGuid')]
        [switch] $IsAssociateAllowed,

        [Parameter(ParameterSetName = 'PermissionPath')]
        [Parameter(ParameterSetName = 'PermissionGuid')]
        [switch] $IsCreateAllowed,

        [Parameter(ParameterSetName = 'PermissionPath')]
        [Parameter(ParameterSetName = 'PermissionGuid')]
        [switch] $IsDeleteAllowed,

        [Parameter(ParameterSetName = 'PermissionPath')]
        [Parameter(ParameterSetName = 'PermissionGuid')]
        [switch] $IsManagePermissionsAllowed,

        [Parameter(ParameterSetName = 'PermissionPath')]
        [Parameter(ParameterSetName = 'PermissionGuid')]
        [switch] $IsPolicyWriteAllowed,

        [Parameter(ParameterSetName = 'PermissionPath')]
        [Parameter(ParameterSetName = 'PermissionGuid')]
        [switch] $IsPrivateKeyReadAllowed,

        [Parameter(ParameterSetName = 'PermissionPath')]
        [Parameter(ParameterSetName = 'PermissionGuid')]
        [switch] $IsPrivateKeyWriteAllowed,

        [Parameter(ParameterSetName = 'PermissionPath')]
        [Parameter(ParameterSetName = 'PermissionGuid')]
        [switch] $IsReadAllowed,

        [Parameter(ParameterSetName = 'PermissionPath')]
        [Parameter(ParameterSetName = 'PermissionGuid')]
        [switch] $IsRenameAllowed,

        [Parameter(ParameterSetName = 'PermissionPath')]
        [Parameter(ParameterSetName = 'PermissionGuid')]
        [switch] $IsRevokeAllowed,

        [Parameter(ParameterSetName = 'PermissionPath')]
        [Parameter(ParameterSetName = 'PermissionGuid')]
        [switch] $IsViewAllowed,

        [Parameter(ParameterSetName = 'PermissionPath')]
        [Parameter(ParameterSetName = 'PermissionGuid')]
        [switch] $IsWriteAllowed,

        [Parameter()]
        [switch] $Force,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation

    }

    process {
        Write-Verbose "Parameterset = $($PSCmdlet.ParameterSetName)"

        $params = @{

            Method        = 'Post'
            UriLeaf       = 'placeholder'
            Body          = $null
            FullResponse  = $true
        }

        if ( $Path ) {
            $thisGuid = $Path | ConvertTo-VdcObject | Select-Object -ExpandProperty Guid
        }
        else {
            $thisGuid = $Guid
        }
        $params.UriLeaf = "Permissions/Object/{$thisGuid}"

        if ( $IdentityId.StartsWith('local:') ) {
            # format of local is local:universalId
            $type, $id = $IdentityId.Split(':')
            $params.UriLeaf += "/$type/$id"
        }
        else {
            # external source, eg. AD, LDAP
            # format is type+name:universalId
            $type, $name, $id = $IdentityId -Split { $_ -in '+', ':' }
            $params.UriLeaf += "/$type/$name/$id"
        }

        if ( $PSCmdlet.ParameterSetName -like 'PermissionObject*' ) {
            $params.Body = $Permission.ToHashtable()
        }
        else {
            Write-Verbose "Getting existing permissions for $IdentityId"
            $thisPerm = $thisGuid | Get-VdcPermission -IdentityId $IdentityId -Explicit | Select-Object -ExpandProperty ExplicitPermissions

            if ( $thisPerm ) {
                Write-Verbose 'Existing identity found will be updated'
                $params.Method = 'Put'
            }
            else {
                Write-Verbose 'Existing identity not found.  Only the permissions switches set will be true, all others will be false.'
                $thisPerm = [TppPermission]::new()
            }

            foreach ($k in $PSBoundParameters.Keys) {
                if ($k -in 'IsAssociateAllowed', 'IsCreateAllowed', 'IsDeleteAllowed', 'IsManagePermissionsAllowed', 'IsPolicyWriteAllowed', 'IsPrivateKeyReadAllowed', 'IsPrivateKeyWriteAllowed', 'IsReadAllowed', 'IsRenameAllowed', 'IsRevokeAllowed', 'IsViewAllowed', 'IsWriteAllowed') {
                    $thisPerm.$k = $PSBoundParameters[$k]
                }
            }

            $params.Body = $thisPerm.ToHashtable()
        }

        if ( $PSCmdlet.ShouldProcess($Path, "Set permission for $IdentityId") ) {
            try {

                $response = Invoke-VenafiRestMethod @params
                switch ( $response.StatusCode ) {

                    { $_ -in 200, 201 } {
                        # success
                    }

                    409 {
                        # user/group already has permissions defined on this object
                        # need to use a put method instead
                        if ( $Force ) {

                            Write-Verbose "Existing user/group found and Force option provided, updating existing permissions"
                            $params.Method = 'Put'
                            $response = Invoke-VenafiRestMethod @params
                            if ( $response.StatusCode -ne 200 ) {
                                Write-Error ('Failed to update permission with error {0}' -f $response.Error)
                            }
                        }
                        else {
                            # force option not provided, let the user know what's up
                            Write-Error ('Permission for {0} already exists.  To override, provide the -Force option.' -f $IdentityId)
                        }
                    }

                    default {
                        Write-Error ('Failed to create permission with error {0}, {1}' -f [int]$response.StatusCode, $response.Error)
                    }
                }
            }
            catch {
                Write-Error ("Failed to set permissions on $Path, user/group $IdentityId.  $_")
            }
        }
    }
}


