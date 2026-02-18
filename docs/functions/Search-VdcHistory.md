# Search-VdcHistory

## SYNOPSIS
Search Certificate Manager, Self-Hosted history for items with specific attributes

## SYNTAX

```
Search-VdcHistory [[-Path] <String>] [-Attribute] <Hashtable> [[-VenafiSession] <PSObject>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Items in the secret store matching the key/value provided will be found and their details returned with their associated 'current' item.
As this function may return details on many items, optional parallel processing has been implemented.
Be sure to use PowerShell v7+ to take advantage.

## EXAMPLES

### EXAMPLE 1
```
Search-VdcHistory -Attribute @{'ValidTo' = (Get-Date)}
```

Name     : test.gdb.com
TypeName : X509 Server Certificate
Path     : \VED\Policy\Certificates\test.gdb.com
History  : {@{AIACAIssuerURL=System.Object\[\]; AIAKeyIdentifier=F2E970BA11A64D616E78592911D7CC; C=US;
           CDPURI=0::False; EnhancedKeyUsage=Server Authentication(1.3.6.1.5.5.7.3.1).........}}

Find historical items that are still active

### EXAMPLE 2
```
Search-VdcHistory -Attribute @{'ValidTo' = (Get-Date)} -Path '\ved\policy\certs'
```

Find historical items that are still active and the current item starts with a specific path

## PARAMETERS

### -Path
Starting path to associated current items to limit the search.
The default is \VED\Policy.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: \VED\Policy
Accept pipeline input: False
Accept wildcard characters: False
```

### -Attribute
Name and value to search.
See https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Secretstore-lookupbyassociation.php for more details.
Note, ValidFrom will perform a greater than or equal comparison and ValidTo will perform a less than or equal comparison.
Currently, one 1 name/value pair can be used.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
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
Position: 3
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

### PSCustomObject
## NOTES

## RELATED LINKS
