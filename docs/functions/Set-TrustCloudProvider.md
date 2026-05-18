# Set-TrustCloudProvider

## SYNOPSIS
Update a cloud provider

## SYNTAX

```
Set-TrustCloudProvider [-CloudProvider] <String> [[-Name] <String>] [[-OwnerTeam] <String>]
 [[-AuthorizedTeam] <String[]>] [[-ContractID] <String[]>] [[-HostName] <String>] [[-AccessToken] <PSObject>]
 [[-ClientToken] <PSObject>] [[-ClientSecret] <PSObject>] [[-ApplicationID] <String>] [[-DirectoryID] <String>]
 [[-AccountID] <String>] [[-IamRoleName] <String>] [[-ServiceAccountEmail] <String>]
 [[-ProjectNumber] <String>] [[-PoolID] <String>] [[-PoolProviderID] <String>] [-Validate] [-PassThru]
 [[-TrustClient] <TrustClient>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Update an existing cloud provider for Akamai, AWS, Azure, or GCP.
Only the parameters you provide will be updated; all other settings are preserved (except for ClientSecret, see parameter description).
The provider type is determined automatically from the existing provider.

## EXAMPLES

### EXAMPLE 1
```
Set-TrustCloudProvider -CloudProvider 'MyAkamai' -HostName 'newhost.luna.akamaiapis.net' -ClientSecret $secret
```

Update the host on an Akamai cloud provider

### EXAMPLE 2
```
Set-TrustCloudProvider -CloudProvider 'MyAzure' -ClientSecret $newSecret -Validate -PassThru
```

Update the Azure client secret and validate the connection

### EXAMPLE 3
```
Set-TrustCloudProvider -CloudProvider 'MyAWS' -IamRoleName 'NewRoleName'
```

Update the IAM role name on an AWS provider

### EXAMPLE 4
```
Set-TrustCloudProvider -CloudProvider 'MyGCP' -ServiceAccountEmail 'new-sa@project.iam.gserviceaccount.com'
```

Update the service account email on a GCP provider

### EXAMPLE 5
```
Set-TrustCloudProvider -CloudProvider 'MyGCP' -ProjectNumber 98765 -PoolID 'new-pool' -PoolProviderID 'new-provider'
```

Update GCP Workload Identity Federation settings

### EXAMPLE 6
```
Set-TrustCloudProvider -CloudProvider 'MyAkamai' -Name 'RenamedProvider' -OwnerTeam 'NewTeam'
```

Rename a provider and change the owning team.
ClientSecret not required since connection settings are not being updated.

## PARAMETERS

### -CloudProvider
ID or name of the cloud provider to update.

```yaml
Type: String
Parameter Sets: (All)
Aliases: cloudProviderId

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
New name for the cloud provider.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
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

Required: False
Position: 3
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
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ContractID
1 or more Akamai contract IDs.
Only valid for Akamai providers.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -HostName
Akamai API hostname (e.g., the host from your .edgerc credentials).
Only valid for Akamai providers.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AccessToken
Akamai access token.
Accepts a string or SecureString.
Only valid for Akamai providers.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ClientToken
Akamai client token.
Accepts a string or SecureString.
Only valid for Akamai providers.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ClientSecret
Client secret credential.
Accepts a string or SecureString.
Only valid for Akamai and Azure providers.
Required when updating any Akamai or Azure connection settings.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ApplicationID
Active Directory Application (client) ID.
Must be a valid GUID.
Only valid for Azure providers.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 10
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DirectoryID
Azure Active Directory tenant ID.
Must be a valid GUID.
Only valid for Azure providers.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 11
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AccountID
12 digit AWS Account ID.
Only valid for AWS providers.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 12
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IamRoleName
IAM role name used for the integration.
Only valid for AWS providers.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 13
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ServiceAccountEmail
Service account email address.
Provide for GCP connections with either Workload Identity Federation or Venafi Generated Key.
Only valid for GCP providers.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 14
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProjectNumber
GCP project number, needed for Workload Identity Federation.
Only valid for GCP providers.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 15
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PoolID
Workload Identity Pool ID, located in the GCP Workload Identity Federation section.
Must be 4 to 32 lowercase letters, digits, or hyphens.
Only valid for GCP providers.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 16
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PoolProviderID
Workload Identity Pool Provider ID.
Must be 4 to 32 lowercase letters, digits, or hyphens.
Only valid for GCP providers.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 17
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Validate
Invoke cloud provider validation after the update.
If using -PassThru, the validation result will be included with the provider details.

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
Return the updated cloud provider object.

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
Position: 18
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
