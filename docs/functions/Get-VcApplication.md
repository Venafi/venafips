# Get-VcApplication

## SYNOPSIS
Get application info

## SYNTAX

### ID (Default)
```
Get-VcApplication [-Application] <String> [-IncludeConfig] [-VenafiSession <PSObject>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### All
```
Get-VcApplication [-IncludeConfig] [-All] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Get 1 or more applications.
Application level renewal configurations are included.

## EXAMPLES

### EXAMPLE 1
```
Get-VcApplication -Application 'ca7ff555-88d2-4bfc-9efa-2630ac44c1f2'
```

applicationId              : 96fc9310-67ec-11eb-a8a7-794fe75a8e6f
issuingTemplate            : @{Name=MyTemplate; id=7fb6af20-b22e-11ea-9a24-930fb5d2b247}
autoRenew                  : True
autoProvision              : True
renewalWindowInherit       : False
renewalWindowDays          : 15
companyId                  : 09b24f81-b22b-11ea-91f3-ebd6dea5452e
name                       : myapp
description                :
ownerIdsAndTypes           : {@{ownerId=0a2adae0-b22b-11ea-91f3-ebd6dea5452f; ownerType=TEAM}}
fullyQualifiedDomainNames  : {}
ipRanges                   : {}
ports                      : {}
modificationDate           : 6/8/2023 11:06:43 AM
creationDate               : 2/5/2021 2:59:00 PM
ownership                  : @{owningUsers=System.Object\[\]}

Get a single object by ID

### EXAMPLE 2
```
Get-VcApplication -Application 'My Awesome App'
```

Get a single object by name. 
The name is case sensitive.

### EXAMPLE 3
```
Get-VcApplication -All
```

Get all applications

## PARAMETERS

### -Application
Application ID or name, tab completion supported

```yaml
Type: String
Parameter Sets: ID
Aliases: applicationId, ID

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -IncludeConfig
Include autorenewal configuration

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

### -All
Get all applications

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

### ID
## OUTPUTS

## NOTES

## RELATED LINKS
