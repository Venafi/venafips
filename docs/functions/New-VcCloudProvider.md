# New-VcCloudProvider

## SYNOPSIS
Create a new cloud provider

## SYNTAX

### AWS
```
New-VcCloudProvider -Name <String> -OwnerTeam <String> [-AuthorizedTeam <String[]>] [-AWS] -AccountID <String>
 -IamRoleName <String> [-Validate] [-PassThru] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

### AZURE
```
New-VcCloudProvider -Name <String> -OwnerTeam <String> [-AuthorizedTeam <String[]>] [-Azure]
 -ApplicationID <String> -DirectoryID <String> -ClientSecret <String> [-Validate] [-PassThru]
 [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### GCP-WIF
```
New-VcCloudProvider -Name <String> -OwnerTeam <String> [-AuthorizedTeam <String[]>] [-GCP]
 -ServiceAccountEmail <String> -ProjectNumber <String> -PoolID <String> -PoolProviderID <String> [-Validate]
 [-PassThru] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### GCP-Venafi
```
New-VcCloudProvider -Name <String> -OwnerTeam <String> [-AuthorizedTeam <String[]>] [-GCP]
 -ServiceAccountEmail <String> [-Validate] [-PassThru] [-VenafiSession <PSObject>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Create a new cloud provider for either AWS, Azure, or GCP

## EXAMPLES

### EXAMPLE 1
```
New-VcCloudProvider -Name 'MyGCP' -OwnerTeam 'SpecialTeam' -GCP -ServiceAccountEmail 'greg-brownstein@my-secret-project.iam.gserviceaccount.com'
```

Create a new GCP Venafi Generated Key provider

### EXAMPLE 2
```
New-VcCloudProvider -Name 'MyGCP' -OwnerTeam 'SpecialTeam' -GCP -ServiceAccountEmail 'greg-brownstein@my-secret-project.iam.gserviceaccount.com' -ProjectNumber 12345 -PoolID hithere -PoolProviderID blahblah1
```

Create a new GCP Workload Identity Foundation provider

### EXAMPLE 3
```
New-VcCloudProvider -Name 'MyAzure' -OwnerTeam 'SpecialTeam' -Azure -ApplicationID '5e256486-ef8f-443f-84ad-221a7ac1d52e' -DirectoryID '45f2133f-8317-44d5-9813-ed08bf92eb7b' -ClientSecret 'youllneverguess'
```

Create a new Azure provider

### EXAMPLE 4
```
New-VcCloudProvider -Name 'MyAWS' -OwnerTeam 'SpecialTeam' -AWS -AccountID 123456789012 -IamRoleName 'TlspcIntegrationRole'
```

Create a new AWS provider

### EXAMPLE 5
```
New-VcCloudProvider -Name 'MyAWS' -OwnerTeam 'SpecialTeam' -AWS -AccountID 123456789012 -IamRoleName 'TlspcIntegrationRole' -Validate
```

Create a new provider and validate once created

### EXAMPLE 6
```
New-VcCloudProvider -Name 'MyAWS' -OwnerTeam 'SpecialTeam' -AWS -AccountID 123456789012 -IamRoleName 'TlspcIntegrationRole' -PassThru
```

Create a new provider and provide the details of the new object

## PARAMETERS

### -Name
Cloud provider name

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
The Owning Team is responsible for the administration, management, and control of a designated cloud provider, with the authority to update, modify, and delete cloud provider resources.

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
Authorized teams are granted permission to use specific resources of a cloud provider.
Although team members can perform tasks like creating a keystore, their permissions may be limited regarding broader modifications to the provider's configuration.
Unlike the Owning Team, users may not have the authority to update and delete Cloud Providers.

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

### -GCP
Create a GCP cloud provider.
Details can be found at https://docs.venafi.cloud/vaas/integrations/gcp/gcp/.

```yaml
Type: SwitchParameter
Parameter Sets: GCP-WIF, GCP-Venafi
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ServiceAccountEmail
Service account email address.
Provide for GCP connections with either Workload Identity Federation or Venafi Generated Key.
Venafi Generated Key, https://docs.venafi.cloud/vaas/integrations/gcp/gcp-serviceaccount/
Workload Identity Federation, https://docs.venafi.cloud/vaas/integrations/gcp/gcp-workload-identity/

```yaml
Type: String
Parameter Sets: GCP-WIF, GCP-Venafi
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProjectNumber
GCP project number, needed for WIF

```yaml
Type: String
Parameter Sets: GCP-WIF
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PoolID
Workload Identity Pool ID, located in the GCP Workload Identity Federation section
This must be 4 to 32 lowercase letters, digits, or hyphens.

```yaml
Type: String
Parameter Sets: GCP-WIF
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PoolProviderID
Unique, meaningful name related to this specific cloud provider, such as venafi-provider.
This will be created.
This must be 4 to 32 lowercase letters, digits, or hyphens.

```yaml
Type: String
Parameter Sets: GCP-WIF
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Azure
Create a Azure cloud provider
Details can be found at https://docs.venafi.cloud/vaas/integrations/azure/azure-key-vault/

```yaml
Type: SwitchParameter
Parameter Sets: AZURE
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ApplicationID
Active Directory Application (client) Id.
The client Id is the unique identifier of an application created in Active Directory.
You can have many applications in an Active Directory and each application will have a different access levels.

```yaml
Type: String
Parameter Sets: AZURE
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DirectoryID
Unique identifier of the Azure Active Directory instance.
One subscription can have multiple tenants.
Using this Tenant Id you register and manage your apps.

```yaml
Type: String
Parameter Sets: AZURE
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ClientSecret
Credential that is used to authenticate and authorize a client application when it interacts with Azure services.

```yaml
Type: String
Parameter Sets: AZURE
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AWS
Create a AWS cloud provider
Details can be found at https://docs.venafi.cloud/vaas/integrations/Aws/aws-acm/

```yaml
Type: SwitchParameter
Parameter Sets: AWS
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -AccountID
12 digit AWS Account ID

```yaml
Type: String
Parameter Sets: AWS
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IamRoleName
Role name, to be created, that carries significance and can be readily linked to this specific cloud provider

```yaml
Type: String
Parameter Sets: AWS
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Validate
Invoke cloud provider validation once created.
If using -PassThru, the validation result will be provided with the new cloud provider details.

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
Return newly created cloud provider object

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
