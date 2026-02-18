# New-VcMachine

## SYNOPSIS
Create 1 or more machines

## SYNTAX

### AdvancedMachine
```
New-VcMachine -Name <String> -MachineType <String> -VSatellite <String> -Owner <String> [-Tag <String[]>]
 [-Status <String>] -ConnectionDetail <Hashtable> -DekID <String> [-NoVerify] [-ThrottleLimit <Int32>]
 [-PassThru] [-Force] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### BasicMachine
```
New-VcMachine -Name <String> -MachineType <String> [-VSatellite <String>] -Owner <String> [-Tag <String[]>]
 [-Status <String>] [-Hostname <String>] -Credential <PSObject> [-Port <String>] [-NoVerify]
 [-ThrottleLimit <Int32>] [-PassThru] [-Force] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
This creation function is to be used for 'simple' machine types, eg.
F5 and Citrix, where hostname, credential and optionally port are used.
Machine creation for types with additional functionality will have dedicated functions, eg.
New-VcMachineIis.
By default, the machine details will be verified by performing a test connection; this can be turned off with -NoVerify.
Creation will occur in parallel and PowerShell v7+ is required.

## EXAMPLES

### EXAMPLE 1
```
$params = @{
    Name = 'c1'
    MachineType = 'Citrix ADC'
    Owner = 'MyTeam'
    Hostname = 'c1.company.com'
    Credential = $cred
}
New-VcMachine @params
```

machineId        : cf7cfdc0-2b2a-11ee-9546-5136c4b21504
testConnection   : @{Success=True; Error=; WorkflowID=c39310ee-51fc-49f3-8b5b-e504e1bc43d2}
companyId        : 20b24f81-b22b-11ea-91f3-ebd6dea5453f
name             : c1
machineType      : Citrix ADC
pluginId         : ff645e14-bd1a-11ed-a009-ce063932f86d
integrationId    : cf7c8014-2b2a-11ee-9a03-fa8930555887
edgeInstanceId   : 0bc771e1-7abe-4339-9fcd-93fffe9cba7f
creationDate     : 7/25/2023 4:35:36 PM
modificationDate : 7/25/2023 4:35:36 PM
status           : UNVERIFIED
owningTeamId     : 59920180-a3e2-11ec-8dcd-3fcbf84c7da7

Create a new Citrix machine

### EXAMPLE 2
```
[pscustomobject] @{
    Name = 'c1.company.com'
    MachineType = 'Citrix ADC'
    Owner = 'MyTeam'
    Credential = $cred
} | New-VcMachine
```

Use pipeline data to create a machine.
More than 1 machine can be sent thru the pipeline and they will be created in parallel.
You could also import a csv and pipe it to this function as well.

## PARAMETERS

### -Name
Machine name

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -MachineType
Machine type by either ID or name, eg.
'Citrix ADC'.
Get a list of available types by running \`Get-VcConnector -All\` and looking for connectorType is MACHINE.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -VSatellite
ID or name of a vsatellite.
If not provided, the first vsatellite found will be used.

```yaml
Type: String
Parameter Sets: AdvancedMachine
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: BasicMachine
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Owner
ID or name of a team to be the owner of the machine

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Tag
Optional list of tags to assign

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Status
Set the machine status to either 'DRAFT', 'VERIFIED', or 'UNVERIFIED'.
This optional field has been added for flexibility, but should not be needed under typical usage.
The platform will handle changing the status to the appropriate value.
Setting this to a value other than VERIFIED will affect the ability to initiate workflows.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Hostname
IP or fqdn of the machine.
If this is to be the same value as -Name, this parameter can be ommitted.

```yaml
Type: String
Parameter Sets: BasicMachine
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Credential
Username/password to access the machine.
Alternatively, you can provide the name or id of a shared credential, eg.
CyberArk, HashiCorp, etc.

```yaml
Type: PSObject
Parameter Sets: BasicMachine
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Port
Optional port. 
The default value will depend on the machine type.
Eg.
for Citrix ADC this is 443.

```yaml
Type: String
Parameter Sets: BasicMachine
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ConnectionDetail
Full connection detail object to create a machine.
This is typically for use with other machine creation functions, but here for flexibility.

```yaml
Type: Hashtable
Parameter Sets: AdvancedMachine
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -DekID
ID of the data encryption key

```yaml
Type: String
Parameter Sets: AdvancedMachine
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -NoVerify
By default a connection to the host will be attempted.
Use this switch to turn off this behavior.
Not recommended.

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

### -ThrottleLimit
Limit the number of threads when running in parallel; the default is 100.
Setting the value to 1 will disable multithreading.
On PS v5 the ThreadJob module is required. 
If not found, multithreading will be disabled.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 100
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Return newly created object

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

### -Force
Force installation of PSSodium if not already installed

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
To see a full list of tab-completion options, be sure to set the Tab option, Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete.

This function requires the use of sodium encryption via the PSSodium PowerShell module.
Dotnet standard 2.0 or greater is required via PS Core (recommended) or supporting .net runtime.
On Windows, the latest Visual C++ redist must be installed. 
See https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist.

## RELATED LINKS
