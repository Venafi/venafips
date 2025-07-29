# Set-VdcPermission

## SYNOPSIS
Set explicit permissions for TLSPDC objects

## SYNTAX

### PermissionObjectGuid (Default)
```
Set-VdcPermission -Guid <Guid> -IdentityId <String> -Permission <TppPermission> [-Force]
 [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### PermissionPath
```
Set-VdcPermission -Path <String> -IdentityId <String> [-IsAssociateAllowed] [-IsCreateAllowed]
 [-IsDeleteAllowed] [-IsManagePermissionsAllowed] [-IsPolicyWriteAllowed] [-IsPrivateKeyReadAllowed]
 [-IsPrivateKeyWriteAllowed] [-IsReadAllowed] [-IsRenameAllowed] [-IsRevokeAllowed] [-IsViewAllowed]
 [-IsWriteAllowed] [-Force] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### PermissionObjectPath
```
Set-VdcPermission -Path <String> -IdentityId <String> -Permission <TppPermission> [-Force]
 [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### PermissionGuid
```
Set-VdcPermission -Guid <Guid> -IdentityId <String> [-IsAssociateAllowed] [-IsCreateAllowed] [-IsDeleteAllowed]
 [-IsManagePermissionsAllowed] [-IsPolicyWriteAllowed] [-IsPrivateKeyReadAllowed] [-IsPrivateKeyWriteAllowed]
 [-IsReadAllowed] [-IsRenameAllowed] [-IsRevokeAllowed] [-IsViewAllowed] [-IsWriteAllowed] [-Force]
 [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Adds, modifies, or removes explicit permissions on TLSPDC objects.
You can provide a complete permission object or modify individual permissions.

## EXAMPLES

### EXAMPLE 1
```
Set-VdcPermission -Guid '1234abcd-g6g6-h7h7-faaf-f50cd6610cba' -IdentityId 'AD+mydomain.com:azsxdcfvgbhnjmlk09877654321' -Permission $TppPermObject
```

Permission a user/group on an object specified by guid

### EXAMPLE 2
```
Set-VdcPermission -Path '\ved\policy\my folder' -IdentityId 'AD+mydomain.com:azsxdcfvgbhnjmlk09877654321' -Permission $TppPermObject
```

Permission a user/group on an object specified by path

### EXAMPLE 3
```
Get-VdcPermission -Path '\ved\policy\my folder' -IdentityId 'AD+mydomain.com:azsxdcfvgbhnjmlk09877654321' -Explicit | Set-VdcPermission -IdentityId $newId
```

Permission a user/group based on permissions of an existing user/group

### EXAMPLE 4
```
Get-VdcPermission -Path '\ved\policy\my folder' -IdentityId 'AD+mydomain.com:azsxdcfvgbhnjmlk09877654321' -Explicit | Set-VdcPermission -IsWriteAllowed
```

Add specific permission(s) for a specific user/group associated with an object

### EXAMPLE 5
```
Get-VdcPermission -Path '\ved\policy\my folder' -Explicit | Set-VdcPermission -IsAssociateAllowed -IsWriteAllowed
```

Add specific permission(s) for all existing user/group associated with an object

### EXAMPLE 6
```
Get-VdcPermission -Path '\ved\policy\my folder' -Explicit | Set-VdcPermission -IsAssociateAllowed:$false
```

Remove specific permission(s) for all existing user/group associated with an object

### EXAMPLE 7
```
$id = Find-VdcIdentity -Name 'brownstein' | Select-Object -ExpandProperty Id
Find-VdcObject -Path '\VED' -Recursive | Get-VdcPermission -IdentityId $id | Set-VdcPermission -Permission $TppPermObject -Force
```

Reset permissions for a specific user/group for all objects. 
Note the use of -Force to overwrite existing permissions.

## PARAMETERS

### -Path
Path to an object

```yaml
Type: String
Parameter Sets: PermissionPath, PermissionObjectPath
Aliases: DN

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Guid
Guid representing a unique object

```yaml
Type: Guid
Parameter Sets: PermissionObjectGuid, PermissionGuid
Aliases: ObjectGuid

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -IdentityId
The id that represents the user or group. 
You can use Find-VdcIdentity or Get-VdcPermission to get the id.

```yaml
Type: String
Parameter Sets: (All)
Aliases: PrefixedUniversalId, ID

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Permission
TppPermission object to set.
You can create a new object and modify it or get an existing object with Get-VdcPermission.

```yaml
Type: TppPermission
Parameter Sets: PermissionObjectGuid, PermissionObjectPath
Aliases: ExplicitPermissions

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -IsAssociateAllowed
Associate or disassociate an Application and Device object with a certificate.
Push the certificate and private key to the Application object.
Retry the certificate installation.

```yaml
Type: SwitchParameter
Parameter Sets: PermissionPath, PermissionGuid
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -IsCreateAllowed
The caller can create subordinate objects, such as Devices and Applications.
Create permission grants implicit View permission.

```yaml
Type: SwitchParameter
Parameter Sets: PermissionPath, PermissionGuid
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -IsDeleteAllowed
The caller can delete objects.

```yaml
Type: SwitchParameter
Parameter Sets: PermissionPath, PermissionGuid
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -IsManagePermissionsAllowed
The caller can grant other user or group Identities permission to the current object or subordinate objects.

```yaml
Type: SwitchParameter
Parameter Sets: PermissionPath, PermissionGuid
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -IsPolicyWriteAllowed
The caller can modify policy values on folders.
Also requires View permission.
Manage Policy permission grants implicit Read permission and Write permission.

```yaml
Type: SwitchParameter
Parameter Sets: PermissionPath, PermissionGuid
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -IsPrivateKeyReadAllowed
The caller can download the private key for Policy and Certificate objects.

```yaml
Type: SwitchParameter
Parameter Sets: PermissionPath, PermissionGuid
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -IsPrivateKeyWriteAllowed
The caller can upload the private key for Policy, Certificate, and Private Key Credential objects to Trust Protection Platform.

```yaml
Type: SwitchParameter
Parameter Sets: PermissionPath, PermissionGuid
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -IsReadAllowed
The caller can view and read object data from the Policy tree.
However, to view subordinate objects, View permission or higher permissions is also required.

```yaml
Type: SwitchParameter
Parameter Sets: PermissionPath, PermissionGuid
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -IsRenameAllowed
The caller can rename and move Policy tree objects.
Move capability also requires Rename permission to the object and Create permission to the target folder.

```yaml
Type: SwitchParameter
Parameter Sets: PermissionPath, PermissionGuid
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -IsRevokeAllowed
The caller can invalidate a certificate.
Also requires Write permission to the certificate.

```yaml
Type: SwitchParameter
Parameter Sets: PermissionPath, PermissionGuid
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -IsViewAllowed
The caller can confirm that the object is present in the Policy tree.

```yaml
Type: SwitchParameter
Parameter Sets: PermissionPath, PermissionGuid
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -IsWriteAllowed
The caller can edit object attributes.
To move objects in the tree, the caller must have Write permission to the objects and Create permission to the target folder.
Write permission grants implicit Read permission.

```yaml
Type: SwitchParameter
Parameter Sets: PermissionPath, PermissionGuid
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
When setting a TppPermission object with -Permission and one already exists, use this to overwrite

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -VenafiSession
Authentication for the function.
The value defaults to the script session object $VenafiSession created by New-VenafiSession.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### Guid, IdentityId, Permission
## OUTPUTS

### None
## NOTES
Confirmation impact is set to Medium, set ConfirmPreference accordingly.

## RELATED LINKS

[https://venafi.github.io/VenafiPS/functions/Set-VdcPermission/](https://venafi.github.io/VenafiPS/functions/Set-VdcPermission/)

[https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Set-VdcPermission.ps1](https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Set-VdcPermission.ps1)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Permissions-object-guid-principal.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Permissions-object-guid-principal.php)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-PUT-Permissions-object-guid-principal.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-PUT-Permissions-object-guid-principal.php)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-Permissions-Effective.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-Permissions-Effective.php)

