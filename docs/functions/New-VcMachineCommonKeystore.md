# New-VcMachineCommonKeystore

## SYNOPSIS
Create a new common keystore machine

## SYNTAX

### SshPassword (Default)
```
New-VcMachineCommonKeystore -Name <String> [-VSatellite <String>] -Owner <String> [-Hostname <String>]
 -Credential <PSObject> [-Tag <String[]>] [-Status <String>] [-SshPassword] [-Port <Int32>] [-NoVerify]
 [-ThrottleLimit <Int32>] [-PassThru] [-Force] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### SshKey
```
New-VcMachineCommonKeystore -Name <String> [-VSatellite <String>] -Owner <String> [-Hostname <String>]
 -Credential <PSObject> [-Tag <String[]>] [-Status <String>] [-SshKey] [-Port <Int32>] [-NoVerify]
 [-ThrottleLimit <Int32>] [-PassThru] [-Force] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### WinrmBasic
```
New-VcMachineCommonKeystore -Name <String> [-VSatellite <String>] -Owner <String> [-Hostname <String>]
 -Credential <PSObject> [-Tag <String[]>] [-Status <String>] [-WinrmBasic] [-Port <Int32>] [-UseTls]
 [-SkipCertificateCheck] [-NoVerify] [-ThrottleLimit <Int32>] [-PassThru] [-Force] [-VenafiSession <PSObject>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### WinrmKerberos
```
New-VcMachineCommonKeystore -Name <String> [-VSatellite <String>] -Owner <String> [-Hostname <String>]
 -Credential <PSObject> [-Tag <String[]>] [-Status <String>] [-WinrmKerberos] [-Port <Int32>] [-UseTls]
 [-SkipCertificateCheck] -DomainName <String> -KeyDistributionCenter <String> -SPN <String> [-NoVerify]
 [-ThrottleLimit <Int32>] [-PassThru] [-Force] [-VenafiSession <PSObject>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Create a new common keystore, PEM/JKS/PKCS#12, machine.
SSH and WinRM are both supported in addition to different authentication types.
By default, the machine details will be verified by performing a test connection; this can be turned off with -NoVerify.
Creation will occur in parallel and PowerShell v7+ is required.

## EXAMPLES

### EXAMPLE 1
```
New-VcMachineCommonKeystore -Name 'ck1' -Owner 'MyTeam' -Hostname 'ck1.company.com' -Credential $cred -SshPassword
```

machineId        : a9b60a70-2b28-11ee-b5b5-4b044579acad
testConnection   : @{Success=True; Error=; WorkflowID=c14e181b-82ea-423a-b0fd-c3fe9b218a64}
companyId        : 20b24f81-b22b-11ea-91f3-ebd6dea5453f
name             : ck1
machineType      : Common KeyStore (PEM, JKS, PKCS#12)
pluginId         : 0e565e41-dd31-11ec-841d-a7d91c5a907c
integrationId    : a9b5b842-2b28-11ee-9263-9e16d4b8a8c9
edgeInstanceId   : 0bc771e1-7abe-4339-9fcd-93fffe9cba7f
creationDate     : 7/25/2023 4:20:14 PM
modificationDate : 7/25/2023 4:20:14 PM
status           : UNVERIFIED
owningTeamId     : 59920180-a3e2-11ec-8dcd-3fcbf84c7da7

Create a new machine with SSH password authentication

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
ID or name of a VSatellite.
If not provided, the first active VSatellite found will be used.

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
Username/password to access the machine.
If using key-based authentication over SSH, set the password to the private key.
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

### -SshPassword
Connect to the target machine over SSH with username and password

```yaml
Type: SwitchParameter
Parameter Sets: SshPassword
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -SshKey
Connect to the target machine over SSH with username and private key

```yaml
Type: SwitchParameter
Parameter Sets: SshKey
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -WinrmBasic
Connect to the target machine over WinRM with Basic authentication

```yaml
Type: SwitchParameter
Parameter Sets: WinrmBasic
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -WinrmKerberos
Connect to the target machine over WinRM with Kerberos authentication

```yaml
Type: SwitchParameter
Parameter Sets: WinrmKerberos
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Port
Optional SSH/WinRM port.
The default for SSH is 22 and WinRM is 5985.

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
Connect with WinRM over HTTPS as opposed to the default of HTTP

```yaml
Type: SwitchParameter
Parameter Sets: WinrmBasic, WinrmKerberos
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -SkipCertificateCheck
If connecting with WinRM over HTTPS and you wish to bypass certificate validation

```yaml
Type: SwitchParameter
Parameter Sets: WinrmBasic, WinrmKerberos
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -DomainName
Machine domain name for WinRM

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
Address or hostname of the key distribution center for WinRM

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
WSMAN/server.company.com, for WinRM

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

### PSCustomObject, if PassThru provided
## NOTES
This function requires the use of sodium encryption via the PSSodium PowerShell module.
Dotnet standard 2.0 or greater is required via PS Core (recommended) or supporting .net runtime.
On Windows, the latest Visual C++ redist must be installed. 
See https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist.

## RELATED LINKS
