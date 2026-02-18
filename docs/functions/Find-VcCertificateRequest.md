# Find-VcCertificateRequest

## SYNOPSIS
Find certificate requests

## SYNTAX

### SimpleFilter (Default)
```
Find-VcCertificateRequest [-Status <String[]>] [-Application <String[]>] [-User <String[]>]
 [-IssuingTemplate <String[]>] [-KeyLength <Int32>] [-CreateDateFrom <DateTime>] [-IncludeAny]
 [-Order <PSObject[]>] [-First <Int32>] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### AdvancedFilter
```
Find-VcCertificateRequest -Filter <System.Collections.Generic.List`1[System.Object]> [-Order <PSObject[]>]
 [-First <Int32>] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Find certificate requests via fields directly or provide a string filter

## EXAMPLES

### EXAMPLE 1
```
Find-VcCertificateRequest
```

Get all certificate requests

### EXAMPLE 2
```
Find-VcCertificateRequest -Application 'MyApp' -CreateDateFrom (Get-Date).AddDays(-7)
```

Find requests for a specific application created in the last 7 days

## PARAMETERS

### -Status
Request status, one of 'NEW', 'PENDING', 'PENDING_APPROVAL', 'PENDING_FINAL_APPROVAL', 'REJECTED_APPROVAL', 'REQUESTED', 'ISSUED', 'REJECTED', 'CANCELLED', 'REVOKED', 'FAILED', 'DELETED'

```yaml
Type: String[]
Parameter Sets: SimpleFilter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Application
One or more application id or names

```yaml
Type: String[]
Parameter Sets: SimpleFilter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -User
One or more owner user id or usernames

```yaml
Type: String[]
Parameter Sets: SimpleFilter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IssuingTemplate
One or more issuing template id or names

```yaml
Type: String[]
Parameter Sets: SimpleFilter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -KeyLength
Certificate key length

```yaml
Type: Int32
Parameter Sets: SimpleFilter
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -CreateDateFrom
Filter certificate requests from this date/time and forward

```yaml
Type: DateTime
Parameter Sets: SimpleFilter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeAny
When using multiple filter parameters, combine them with OR logic instead of AND logic

```yaml
Type: SwitchParameter
Parameter Sets: SimpleFilter
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Filter
Array or multidimensional array of fields and values to filter on.
Each array should be of the format @('operator', @(field, comparison operator, value), @(field2, comparison operator2, value2)).
Nested filters are supported.
For a complete list of comparison operators, see https://docs.venafi.cloud/api/about-api-search-operators/.

```yaml
Type: System.Collections.Generic.List`1[System.Object]
Parameter Sets: AdvancedFilter
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Order
Array of fields to order on.
For each item in the array, you can provide a field name by itself; this will default to ascending.
You can also provide a hashtable with the field name as the key and either asc or desc as the value.

```yaml
Type: PSObject[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -First
Only retrieve this many records

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
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

## OUTPUTS

## NOTES

## RELATED LINKS
