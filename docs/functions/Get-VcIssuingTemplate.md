# Get-VcIssuingTemplate

## SYNOPSIS
Get issuing template info

## SYNTAX

### ID (Default)
```
Get-VcIssuingTemplate [-IssuingTemplate] <String> [-VenafiSession <PSObject>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### All
```
Get-VcIssuingTemplate [-All] [-CertificateAuthority <String>] [-VenafiSession <PSObject>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Get 1 or more issuing template details

## EXAMPLES

### EXAMPLE 1
```
Get-VcIssuingTemplate -IssuingTemplate 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2'
```

issuingTemplateId                   : 0a19eaf2-b22b-11ea-a1eb-a37c69eabd4e
companyId                           : 09b24f81-b22b-11ea-91f3-ebd6dea5452f
certificateAuthority                : BUILTIN
name                                : Default
certificateAuthorityAccountId       : 0a19eaf0-b22b-11ea-a1eb-a37c69eabd4e
certificateAuthorityProductOptionId : 0a19eaf1-b22b-11ea-a1eb-a37c69eabd4e
product                             : @{certificateAuthority=BUILTIN; productName=Default Product; productTypes=System.Object\[\]; validityPeriod=P90D}
priority                            : 0
systemGenerated                     : True
creationDate                        : 6/19/2020 8:47:30 AM
modificationDate                    : 6/19/2020 8:47:30 AM
status                              : AVAILABLE
reason                              :
referencingApplicationIds           : {995d1fb0-67e9-11eb-a8a7-794fe75a8e6f}
subjectCNRegexes                    : {.*}
subjectORegexes                     : {.*}
subjectOURegexes                    : {.*}
subjectSTRegexes                    : {.*}
subjectLRegexes                     : {.*}
subjectCValues                      : {.*}
sanRegexes                          : {.*}
sanDnsNameRegexes                   : {.*}
keyTypes                            : {@{keyType=RSA; keyLengths=System.Object\[\]}}
keyReuse                            : False
extendedKeyUsageValues              : {}
csrUploadAllowed                    : True
keyGeneratedByVenafiAllowed         : False
resourceConsumerUserIds             : {}
resourceConsumerTeamIds             : {}
everyoneIsConsumer                  : True

Get a single object by ID

### EXAMPLE 2
```
Get-VcIssuingTemplate -IssuingTemplate 'MyTemplate'
```

Get a single object by name. 
The name is case sensitive.

### EXAMPLE 3
```
Get-VcIssuingTemplate -All
```

Get all issuing templates

### EXAMPLE 4
```
Get-VcIssuingTemplate -All -CA 'MyCA'
```

Get all issuing templates with a specific certificate authority

## PARAMETERS

### -IssuingTemplate
Issuing template ID or name

```yaml
Type: String
Parameter Sets: ID
Aliases: issuingTemplateId, ID

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -All
Get all issuing templates

```yaml
Type: SwitchParameter
Parameter Sets: All
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -CertificateAuthority
Limit templates to those using a specific certificate authority. 
Specify by name or ID.

```yaml
Type: String
Parameter Sets: All
Aliases: CA

Required: False
Position: Named
Default value: None
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
Aliases:

Required: False
Position: Named
Default value: (Get-VenafiSession)
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

### ID
## OUTPUTS

## NOTES

## RELATED LINKS
