# New-TrustMachineIis

## SYNOPSIS
Create a new IIS machine

## SYNTAX

### WinrmBasic (Default)
```
New-TrustMachineIis -Name <String> [-VSatellite <String>] -Owner <String> [-Hostname <String>]
 -Credential <PSObject> [-Tag <String[]>] [-Status <String>] [-Port <Int32>] [-UseTls] [-SkipCertificateCheck]
 [-NoVerify] [-ThrottleLimit <Int32>] [-PassThru] [-Force] [-TrustClient <TrustClient>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### WinrmKerberos
```
New-TrustMachineIis -Name <String> [-VSatellite <String>] -Owner <String> [-Hostname <String>]
 -Credential <PSObject> [-Tag <String[]>] [-Status <String>] [-Port <Int32>] [-UseTls] [-SkipCertificateCheck]
 -DomainName <String> -KeyDistributionCenter <String> -SPN <String> [-NoVerify] [-ThrottleLimit <Int32>]
 [-PassThru] [-Force] [-TrustClient <TrustClient>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Create a new IIS machine with either basic or kerberos authentication.
By default, the machine details will be verified by performing a test connection; this can be turned off with -NoVerify.
Creation will occur in parallel and PowerShell v7+ is required.

## EXAMPLES

### EXAMPLE 1
```
$params = @{
    Name = 'iis1'
    Owner = 'MyTeam'
    Hostname = 'iis1.company.com'
    Credential = $cred
    DomainName = 'company.com'
    KeyDistributionCenter = '1.2.3.4'
    SPN = 'WSMAN/iis1.company.com'
}
New-TrustMachineIis @params
```

machineId        : 55e054d0-2b2a-11ee-9546-5136c4b21504
testConnection   : @{Success=True; Error=; WorkflowID=c39310ee-51fc-49f3-8b5b-e504e1bc43d2}
companyId        : 20b24f81-b22b-11ea-91f3-ebd6dea5453f
name             : iis1
machineType      : Microsoft IIS
pluginId         : be453281-d080-11ec-a07a-6d5bc1b54078
integrationId    : 55df8877-2b2a-11ee-9264-9e16d4b8a8c9
edgeInstanceId   : 0bc771e1-7abe-4339-9fcd-93fffe9cba7f
creationDate     : 7/25/2023 4:32:12 PM
modificationDate : 7/25/2023 4:32:12 PM
status           : UNVERIFIED
owningTeamId     : 59920180-a3e2-11ec-8dcd-3fcbf84c7da7

Create a new machine with Kerberos authentication

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
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -VSatellite
ID or name of a vsatellite.
If not provided, the first vsatellite found will be used.

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

### -Hostname
IP or fqdn of the machine.
If this is to be the same value as -Name, this parameter can be ommitted.

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

### -Credential
Username/password to access the machine
Alternatively, you can provide the name or id of a shared credential, eg.
CyberArk, HashiCorp, etc.

```yaml
Type: PSObject
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

### -Port
Optional WinRM port. 
The default is 5985.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -UseTls
Connect over HTTPS as opposed to the default of HTTP

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -SkipCertificateCheck
If connecting over HTTPS and you wish to bypass certificate validation

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -DomainName
Machine domain name

```yaml
Type: String
Parameter Sets: WinrmKerberos
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -KeyDistributionCenter
Address or hostname of the key distribution center

```yaml
Type: String
Parameter Sets: WinrmKerberos
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -SPN
Service Principal Name, eg.
WSMAN/server.company.com

```yaml
Type: String
Parameter Sets: WinrmKerberos
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

### -TrustClient
Authentication for the function.
The value defaults to the script session object $TrustClient created by New-TrustClient.

```yaml
Type: TrustClient
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
This function requires the use of sodium encryption via the PSSodium PowerShell module.
Dotnet standard 2.0 or greater is required via PS Core (recommended) or supporting .net runtime.
On Windows, the latest Visual C++ redist must be installed. 
See https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist.

## RELATED LINKS
