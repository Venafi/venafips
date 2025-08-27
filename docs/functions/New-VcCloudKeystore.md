# New-VcCloudKeystore

## SYNOPSIS
Create a new cloud keystore

## SYNTAX

### ACM
```
New-VcCloudKeystore -CloudProvider <String> -Name <String> -OwnerTeam <String> [-AuthorizedTeam <String[]>]
 [-ACM] -Region <String> [-IncludeExpiredCertificates] [-DiscoverySchedule <String>] [-PassThru]
 [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### AKV
```
New-VcCloudKeystore -CloudProvider <String> -Name <String> -OwnerTeam <String> [-AuthorizedTeam <String[]>]
 [-AKV] -KeyVaultName <String> [-IncludeExpiredCertificates] [-DiscoverySchedule <String>] [-PassThru]
 [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### GCM
```
New-VcCloudKeystore -CloudProvider <String> -Name <String> -OwnerTeam <String> [-AuthorizedTeam <String[]>]
 [-GCM] [-Location <String>] -ProjectID <String> [-IncludeExpiredCertificates] [-DiscoverySchedule <String>]
 [-PassThru] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Create a new cloud keystore

## EXAMPLES

### EXAMPLE 1
```
New-VcCloudKeystore -CloudProvider 'MyGCP' -Name 'MyGCM' -OwnerTeam 'SpecialTeam' -GCM -ProjectID 'woot1'
```

Create a new GCM keystore

### EXAMPLE 2
```
New-VcCloudKeystore -CloudProvider 'MyAzure' -Name 'MyAKV' -OwnerTeam 'SpecialTeam' -AKV -KeyVaultName 'thisisakeyvault'
```

Create a new AKV keystore

### EXAMPLE 3
```
New-VcCloudKeystore -CloudProvider 'MyAWS' -Name 'MyACM' -OwnerTeam 'SpecialTeam' -ACM -Region 'us-east-1'
```

Create a new ACM keystore

### EXAMPLE 4
```
New-VcCloudKeystore -CloudProvider 'MyAWS' -Name 'MyACM' -OwnerTeam 'SpecialTeam' -ACM -Region 'us-east-1' -IncludeExpiredCertificates
```

Create a new keystore and include expired certificates during discovery

### EXAMPLE 5
```
New-VcCloudKeystore -CloudProvider 'MyAWS' -Name 'MyACM' -OwnerTeam 'SpecialTeam' -ACM -Region 'us-east-1' -PassThru
```

Create a new keystore and provide the details of the new object

## PARAMETERS

### -CloudProvider
Cloud provider ID or name

```yaml
Type: String
Parameter Sets: (All)
Aliases: cloudProviderId, cp

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
Cloud keystore name

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OwnerTeam
ID or name of owning team.
The Owning Team is responsible for the administration, management, and control of a designated cloud keystore, with the authority to update, modify, and delete cloud keystore resources.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AuthorizedTeam
1 or more IDs or names of authorized teams.
Authorized teams are granted permission to use specific resources of a cloud keystore.
Although team members can perform tasks like creating a keystore, their permissions may be limited regarding broader modifications to the keystore's configuration.
Unlike the Owning Team, users may not have the authority to update and delete Cloud Keystores.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -GCM
Create a Google Certificate Manager (GCM) keystore.
Details can be found at https://docs.venafi.cloud/vaas/installations/cloud-keystores/add-cloud-keystore-google/

```yaml
Type: SwitchParameter
Parameter Sets: GCM
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Location
GCM region, default is 'global'

```yaml
Type: String
Parameter Sets: GCM
Aliases:

Required: False
Position: Named
Default value: Global
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProjectID
GCM Project ID

```yaml
Type: String
Parameter Sets: GCM
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AKV
Create a Azure KeyVault (AKV) keystore
Details can be found at https://docs.venafi.cloud/vaas/installations/cloud-keystores/add-cloud-keystore-azure/

```yaml
Type: SwitchParameter
Parameter Sets: AKV
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -KeyVaultName
Azure KeyVault name

```yaml
Type: String
Parameter Sets: AKV
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ACM
Create a AWS Certificate Manager (ACM) keystore
Details can be found at https://docs.venafi.cloud/vaas/installations/cloud-keystores/add-cloud-keystore-aws/

```yaml
Type: SwitchParameter
Parameter Sets: ACM
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Region
ACM region

```yaml
Type: String
Parameter Sets: ACM
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeExpiredCertificates
Provide this switch to include expired certificates when discovery is run

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

### -DiscoverySchedule
A crontab expression representing when the discovery will run, eg.
0 0 * * *, run daily at 12a

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Return newly created cloud keystore object

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
A TLSPC key can also provided.

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

## OUTPUTS

### PSCustomObject, if PassThru provided
## NOTES

## RELATED LINKS
