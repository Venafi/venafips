function New-VcMachineCommonKeystore {
    <#
    .SYNOPSIS
    Create a new common keystore machine

    .DESCRIPTION
    Create a new common keystore, PEM/JKS/PKCS#12, machine.
    SSH and WinRM are both supported in addition to different authentication types.
    By default, the machine details will be verified by performing a test connection; this can be turned off with -NoVerify.
    Creation will occur in parallel and PowerShell v7+ is required.

    .PARAMETER Name
    Machine name

    .PARAMETER VSatellite
    ID or name of a VSatellite.
    If not provided, the first active VSatellite found will be used.

    .PARAMETER Owner
    ID or name of a team to be the owner of the machine

    .PARAMETER Tag
    Optional list of tags to assign

    .PARAMETER Status
    Set the machine status to either 'DRAFT', 'VERIFIED', or 'UNVERIFIED'.
    This optional field has been added for flexibility, but should not be needed under typical usage.
    The platform will handle changing the status to the appropriate value.
    Setting this to a value other than VERIFIED will affect the ability to initiate workflows.

    .PARAMETER SshPassword
    Connect to the target machine over SSH with username and password

    .PARAMETER SshKey
    Connect to the target machine over SSH with username and private key

    .PARAMETER WinrmBasic
    Connect to the target machine over WinRM with Basic authentication

    .PARAMETER WinrmKerberos
    Connect to the target machine over WinRM with Kerberos authentication

    .PARAMETER Hostname
    IP or fqdn of the machine.
    If this is to be the same value as -Name, this parameter can be ommitted.

    .PARAMETER Credential
    Username/password to access the machine.
    If using key-based authentication over SSH, set the password to the private key.
    Alternatively, you can provide the name or id of a shared credential, eg. CyberArk, HashiCorp, etc.

    .PARAMETER Port
    Optional SSH/WinRM port.
    The default for SSH is 22 and WinRM is 5985.

    .PARAMETER UseTls
    Connect with WinRM over HTTPS as opposed to the default of HTTP

    .PARAMETER SkipCertificateCheck
    If connecting with WinRM over HTTPS and you wish to bypass certificate validation

    .PARAMETER DomainName
    Machine domain name for WinRM

    .PARAMETER KeyDistributionCenter
    Address or hostname of the key distribution center for WinRM

    .PARAMETER SPN
    Service Principal Name, eg. WSMAN/server.company.com, for WinRM

    .PARAMETER NoVerify
    By default a connection to the host will be attempted.
    Use this switch to turn off this behavior.
    Not recommended.

    .PARAMETER ThrottleLimit
    Limit the number of threads when running in parallel; the default is 100.
    Setting the value to 1 will disable multithreading.
    On PS v5 the ThreadJob module is required.  If not found, multithreading will be disabled.

    .PARAMETER PassThru
    Return newly created object

    .PARAMETER Force
    Force installation of PSSodium if not already installed

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.
    A Certificate Manager, SaaS key can also provided.

    .OUTPUTS
    PSCustomObject, if PassThru provided

    .EXAMPLE
    New-VcMachineCommonKeystore -Name 'ck1' -Owner 'MyTeam' -Hostname 'ck1.company.com' -Credential $cred -SshPassword

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

    .NOTES
    This function requires the use of sodium encryption via the PSSodium PowerShell module.
    Dotnet standard 2.0 or greater is required via PS Core (recommended) or supporting .net runtime.
    On Windows, the latest Visual C++ redist must be installed.  See https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist.
    #>

    [CmdletBinding(DefaultParameterSetName = 'SshPassword')]
    [Alias('New-VaasMachineCommonKeystore')]

    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $VSatellite,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [String] $Owner,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $Hostname,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [psobject] $Credential,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]] $Tag,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('DRAFT', 'VERIFIED', 'UNVERIFIED')]
        [string] $Status,

        [Parameter(ParameterSetName = 'SshPassword', Mandatory, ValueFromPipelineByPropertyName)]
        [switch] $SshPassword,

        [Parameter(ParameterSetName = 'SshKey', Mandatory, ValueFromPipelineByPropertyName)]
        [switch] $SshKey,

        [Parameter(ParameterSetName = 'WinrmBasic', Mandatory, ValueFromPipelineByPropertyName)]
        [switch] $WinrmBasic,

        [Parameter(ParameterSetName = 'WinrmKerberos', Mandatory, ValueFromPipelineByPropertyName)]
        [switch] $WinrmKerberos,

        [Parameter(ValueFromPipelineByPropertyName)]
        [int] $Port,

        [Parameter(ParameterSetName = 'WinrmBasic', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'WinrmKerberos', ValueFromPipelineByPropertyName)]
        [switch] $UseTls,

        [Parameter(ParameterSetName = 'WinrmBasic', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'WinrmKerberos', ValueFromPipelineByPropertyName)]
        [switch] $SkipCertificateCheck,

        [Parameter(ParameterSetName = 'WinrmKerberos', Mandatory, ValueFromPipelineByPropertyName)]
        [string] $DomainName,

        [Parameter(ParameterSetName = 'WinrmKerberos', Mandatory, ValueFromPipelineByPropertyName)]
        [string] $KeyDistributionCenter,

        [Parameter(ParameterSetName = 'WinrmKerberos', Mandatory, ValueFromPipelineByPropertyName)]
        [string] $SPN,

        [Parameter()]
        [switch] $NoVerify,

        [Parameter()]
        [int32] $ThrottleLimit = 100,

        [Parameter()]
        [switch] $PassThru,

        [Parameter()]
        [switch] $Force,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {

        Test-VenafiSession $PSCmdlet.MyInvocation

        $allMachines = [System.Collections.Generic.List[pscustomobject]]::new()
        $machineTypeId = Get-VcData -InputObject 'Common KeyStore (PEM, JKS, PKCS#12)' -Type 'Plugin'

        Initialize-PSSodium -Force:$Force
    }

    process {

        # need vsat to get dek for encrypting username/password
        if ( $VSatellite ) {
            $vSat = Get-VcData -InputObject $VSatellite -Type 'VSatellite' -Object
            if ( -not $vSat ) {
                throw "'$VSatellite' is either not a valid VSatellite id or name or it is not active"
            }
        }
        else {
            $vSat = Get-VcData -Type 'VSatellite' | Where-Object edgeStatus -eq 'ACTIVE' | Select-Object -First 1
            if ( -not $vSat ) {
                throw "An active VSatellite could not be found"
            }
        }

        $credDetail = if ( $Credential -is [pscredential] ) {

            $userEnc = ConvertTo-SodiumEncryptedString -text $Credential.UserName -PublicKey $vSat.encryptionKey
            $pwEnc = ConvertTo-SodiumEncryptedString -text $Credential.GetNetworkCredential().Password -PublicKey $vSat.encryptionKey

            @{
                username       = $userEnc
                password       = $pwEnc
                credentialType = 'local'
            }
        }
        else {
            # if not a pscredential, assume a string and it will be a shared credential name/id
            $credentialId = Get-VcData -InputObject $Credential -Type 'Credential' -FailOnNotFound -FailOnMultiple
            @{
                credentialId   = $credentialId
                credentialType = 'shared'
            }
        }

        switch ($PSCmdlet.ParameterSetName) {
            'SshPassword' {
                $connectionDetail = @{
                    protocol    = 'ssh2'
                    protocolSsh = @{
                        hostnameOrAddress = if ($Hostname) { $Hostname } else { $Name }
                        sshAuthentication = 'password'
                        sshPassword       = $credDetail
                    }
                }
            }

            'SshKey' {
                $connectionDetail = @{
                    protocol    = 'ssh2'
                    protocolSsh = @{
                        hostnameOrAddress = if ($Hostname) { $Hostname } else { $Name }
                        sshAuthentication = "key"
                        sshPrivateKey     = $credDetail
                    }
                }
            }

            'WinrmBasic' {
                $connectionDetail = @{
                    protocol      = 'winrm2'
                    protocolWinRm = @{
                        hostnameOrAddress  = if ($Hostname) { $Hostname } else { $Name }
                        authenticationType = "basic"
                    } + $credDetail
                }
            }

            'WinrmKerberos' {
                $connectionDetail = @{
                    protocol      = 'winrm2'
                    protocolWinRm = @{
                        hostnameOrAddress  = if ($Hostname) { $Hostname } else { $Name }
                        authenticationType = 'kerberos'
                        kerberos           = @{
                            domain                = "$DomainName"
                            keyDistributionCenter = "$KeyDistributionCenter"
                            servicePrincipalName  = "$SPN"
                        }
                    } + $credDetail
                }
            }
        }

        if ( $Port ) {
            if ( $PSCmdlet.ParameterSetName -match '^Ssh' ) {
                $connectionDetail.protocolSsh.port = $Port
            }
            else {
                $connectionDetail.protocolWinRm.port = $Port
            }
        }

        if ( $UseTls ) {
            $connectionDetail.protocolWinRm.https = $true
            if ( $SkipCertificateCheck ) {
                $connectionDetail.protocolWinRm.skipTlsVerify = $true
            }
        }

        $params = @{
            Name             = $Name
            MachineType      = $machineTypeId
            VSatellite       = $vSat.vsatelliteId
            DekID            = $vSat.encryptionKeyId
            Owner            = $Owner
            ConnectionDetail = $connectionDetail
        }

        if ( $Tag ) {
            $params.Tag = $Tag
        }

        if ( $Status ) {
            $params.Status = $Status
        }

        $allMachines.Add( [pscustomobject]$params )
    }

    end {

        $newParams = @{

            NoVerify      = $NoVerify
            ThrottleLimit = $ThrottleLimit
            PassThru      = $true
        }

        $response = $allMachines | New-VcMachine @newParams

        if ( $PassThru ) {
            $response
        }
    }
}


