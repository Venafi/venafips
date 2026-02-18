# Set-VcCertificate

## SYNOPSIS
Update a certificate

## SYNTAX

### Application (Default)
```
Set-VcCertificate -Certificate <String> -Application <String[]> [-NoOverwrite] [-PassThru]
 [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Tag
```
Set-VcCertificate -Certificate <String> -Tag <String[]> [-NoOverwrite] [-PassThru] [-VenafiSession <PSObject>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Associate one or more certificates with one or more applications or tags.
The associated applications/tags can either replace or be added to existing.
By default, applications/tags will be replaced.

## EXAMPLES

### EXAMPLE 1
```
Add-VcCertificateAssociation -Certificate '7ac56ec0-2017-11ee-9417-a17dd25b82f9' -Application '96fc9310-67ec-11eb-a8a7-794fe75a8e6f'
```

Associate a certificate to an application

### EXAMPLE 2
```
Add-VcCertificateAssociation -Certificate '7ac56ec0-2017-11ee-9417-a17dd25b82f9' -Application '96fc9310-67ec-11eb-a8a7-794fe75a8e6f', 'a05013bd-921d-440c-bc22-c9ead5c8d548'
```

Associate a certificate to multiple applications

### EXAMPLE 3
```
Find-VcCertificate -First 5 | Add-VcCertificateAssociation -Application 'My Awesome App'
```

Associate multiple certificates to 1 application by name

### EXAMPLE 4
```
Add-VcCertificateAssociation -Certificate '7ac56ec0-2017-11ee-9417-a17dd25b82f9' -Tag 'MyTagName'
```

Associate a certificate to a tag

### EXAMPLE 5
```
Add-VcCertificateAssociation -Certificate '7ac56ec0-2017-11ee-9417-a17dd25b82f9' -Tag 'MyTagName:MyTagValue'
```

Associate a certificate to a tag name/value pair

### EXAMPLE 6
```
Add-VcCertificateAssociation -Certificate '7ac56ec0-2017-11ee-9417-a17dd25b82f9' -Tag 'Tag1', 'MyTagName:MyTagValue'
```

Associate a certificate to multiple tags

### EXAMPLE 7
```
Add-VcCertificateAssociation -Certificate 'www.barron.com' -Application '96fc9310-67ec-11eb-a8a7-794fe75a8e6f' -NoOverwrite
```

Associate a certificate, by name, to an additonal application, keeping the existing application in place

## PARAMETERS

### -Certificate
Certificate ID or name to be associated.
If a name is provided and multiple certificates are found, they will all be associated.
Tab completion can be used for a list of certificate names to choose from.
Type 3 or more characters for tab completion to work.

```yaml
Type: String
Parameter Sets: (All)
Aliases: certificateID

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Application
One or more application IDs or names.
Tab completion can be used for a list of application names.

```yaml
Type: String[]
Parameter Sets: Application
Aliases: applicationID

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Tag
One of more tag names or name/value pairs.
To specify a name/value pair, use the format 'name:value'.

```yaml
Type: String[]
Parameter Sets: Tag
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoOverwrite
Append to existing as opposed to overwriting

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

### -PassThru
Return the newly updated certificate object(s)

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
A Certificate Manager, SaaS key can also provided.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases: Key

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

### Certificate
## OUTPUTS

### PSCustomObject
## NOTES

## RELATED LINKS
