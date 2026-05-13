# Set-CmPermission

## SYNOPSIS
Set explicit permissions for Certificate Manager, Self-Hosted objects

## SYNTAX

### PermissionObjectGuid (Default)
```
Set-CmPermission -Guid <Guid> -IdentityId <String> -Permission <CmPermission> [-Force]
 [-TrustClient <TrustClient>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### PermissionPath
```
Set-CmPermission -Path <String> -IdentityId <String> [-IsAssociateAllowed] [-IsCreateAllowed]
 [-IsDeleteAllowed] [-IsManagePermissionsAllowed] [-IsPolicyWriteAllowed] [-IsPrivateKeyReadAllowed]
 [-IsPrivateKeyWriteAllowed] [-IsReadAllowed] [-IsRenameAllowed] [-IsRevokeAllowed] [-IsViewAllowed]
 [-IsWriteAllowed] [-Force] [-TrustClient <TrustClient>] [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### PermissionObjectPath
```
Set-CmPermission -Path <String> -IdentityId <String> -Permission <CmPermission> [-Force]
 [-TrustClient <TrustClient>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### PermissionGuid
```
Set-CmPermission -Guid <Guid> -IdentityId <String> [-IsAssociateAllowed] [-IsCreateAllowed] [-IsDeleteAllowed]
 [-IsManagePermissionsAllowed] [-IsPolicyWriteAllowed] [-IsPrivateKeyReadAllowed] [-IsPrivateKeyWriteAllowed]
 [-IsReadAllowed] [-IsRenameAllowed] [-IsRevokeAllowed] [-IsViewAllowed] [-IsWriteAllowed] [-Force]
 [-TrustClient <TrustClient>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Adds, modifies, or removes explicit permissions on Certificate Manager, Self-Hosted objects.
You can provide a complete permission object or modify individual permissions.

## EXAMPLES

### EXAMPLE 1
```
Set-CmPermission -Guid '1234abcd-g6g6-h7h7-faaf-f50cd6610cba' -IdentityId 'AD+mydomain.com:azsxdcfvgbhnjmlk09877654321' -Permission $CmPermObject
```

Permission a user/group on an object specified by guid

### EXAMPLE 2
```
Set-CmPermission -Path '\ved\policy\my folder' -IdentityId 'AD+mydomain.com:azsxdcfvgbhnjmlk09877654321' -Permission $CmPermObject
```

Permission a user/group on an object specified by path

### EXAMPLE 3
```
Get-CmPermission -Path '\ved\policy\my folder' -IdentityId 'AD+mydomain.com:azsxdcfvgbhnjmlk09877654321' -Explicit | Set-CmPermission -IdentityId $newId
```

Permission a user/group based on permissions of an existing user/group

### EXAMPLE 4
```
Get-CmPermission -Path '\ved\policy\my folder' -IdentityId 'AD+mydomain.com:azsxdcfvgbhnjmlk09877654321' -Explicit | Set-CmPermission -IsWriteAllowed
```

Add specific permission(s) for a specific user/group associated with an object

### EXAMPLE 5
```
Get-CmPermission -Path '\ved\policy\my folder' -Explicit | Set-CmPermission -IsAssociateAllowed -IsWriteAllowed
```

Add specific permission(s) for all existing user/group associated with an object

### EXAMPLE 6
```
Get-CmPermission -Path '\ved\policy\my folder' -Explicit | Set-CmPermission -IsAssociateAllowed:$false
```

Remove specific permission(s) for all existing user/group associated with an object

### EXAMPLE 7
```
$id = Find-CmIdentity -Name 'brownstein' | Select-Object -ExpandProperty Id
Find-CmObject -Path '\VED' -Recursive | Get-CmPermission -IdentityId $id | Set-CmPermission -Permission $CmPermObject -Force
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
You can use Find-CmIdentity or Get-CmPermission to get the id.

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
CmPermission object to set.
You can create a new object and modify it or get an existing object with Get-CmPermission.

```yaml
Type: CmPermission
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
When setting a CmPermission object with -Permission and one already exists, use this to overwrite

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

### -TrustClient
Authentication for the function.
The value defaults to the script session object $TrustClient created by New-TrustClient.

```yaml
Type: TrustClient
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

[https://venafi.github.io/VenafiPS/functions/Set-CmPermission/](https://venafi.github.io/VenafiPS/functions/Set-CmPermission/)

[https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Set-CmPermission.ps1](https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Set-CmPermission.ps1)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Permissions-object-guid-principal.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Permissions-object-guid-principal.php)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-PUT-Permissions-object-guid-principal.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-PUT-Permissions-object-guid-principal.php)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-Permissions-Effective.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-Permissions-Effective.php)

