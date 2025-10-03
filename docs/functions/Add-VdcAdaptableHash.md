# Add-VdcAdaptableHash

## SYNOPSIS
Adds or updates the hash value for an adaptable script

## SYNTAX

```
Add-VdcAdaptableHash [-Path] <String> [[-Keyname] <String>] [-FilePath] <String> [[-VenafiSession] <PSObject>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
TLSPDC stores a base64 encoded hash of the file contents of an adaptable script in the Secret Store.
This is referenced by
the Attribute 'PowerShell Script Hash Vault Id' on the DN of the adaptable script.
This script retrieves the hash (if
present) from the Secret Store and compares it to the hash of the file in one of the scripts directories.
It then adds
a new or updated hash if required.
When updating an existing hash, it removes the old one from the Secret Store.

## EXAMPLES

### EXAMPLE 1
```
Add-VdcAdaptableHash -Path '\ved\policy\MyAppDriver' -FilePath 'C:\Program Files\Venafi\Scripts\AdaptableApp\AppDriver.ps1'
```

Update the hash on an adaptable app object.

### EXAMPLE 2
```
Add-VdcAdaptableHash -Path $Path -FilePath 'C:\Program Files\Venafi\Scripts\AdaptableLog\Generic-LogDriver.ps1'
```

Update the hash on an adaptable log object.

## PARAMETERS

### -Path
Required.
Path to the object to add or update the hash.
For an adaptable app or an onboard discovery, 'Path' must always be a policy folder as this is where the hash is saved.

```yaml
Type: String
Parameter Sets: (All)
Aliases: DN

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Keyname
The name of the Secret Encryption Key (SEK) to used when encrypting this item.
Default is "Software:Default"

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: Software:Default
Accept pipeline input: False
Accept wildcard characters: False
```

### -FilePath
Required.
The full path to the adaptable script file.
This should typically be in a
'\<drive\>:\Program Files\Venafi\Scripts\\\<subdir\>' directory for TLSPDC to recognize the script.

```yaml
Type: String
Parameter Sets: (All)
Aliases: File

Required: True
Position: 3
Default value: None
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
Position: 4
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

### None
## OUTPUTS

### None
## NOTES

## RELATED LINKS

[https://venafi.github.io/VenafiPS/functions/Add-VdcAdaptableHash/](https://venafi.github.io/VenafiPS/functions/Add-VdcAdaptableHash/)

[https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Add-VdcAdaptableHash.ps1](https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Add-VdcAdaptableHash.ps1)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Secretstore-add.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Secretstore-add.php)

[https://docs.venafi.com/Docs/currentSDK/TopNav/Content/SDK/WebSDK/r-SDK-POST-Secretstore-ownerdelete.php](https://docs.venafi.com/Docs/currentSDK/TopNav/Content/SDK/WebSDK/r-SDK-POST-Secretstore-ownerdelete.php)

[https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Secretstore-retrieve.php](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Secretstore-retrieve.php)

