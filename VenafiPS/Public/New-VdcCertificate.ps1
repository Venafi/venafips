function New-VdcCertificate {
    <#
    .SYNOPSIS
    Enrolls or provisions a new certificate

    .DESCRIPTION
    Enrolls or provisions a new certificate

    .PARAMETER Path
    The folder DN path for the new certificate.

    .PARAMETER Name
    Name of the certifcate object.
    If CommonName isn't provided, this value will be used.

    .PARAMETER CommonName
    Subject Common Name.  If CommonName isn't provided, Name will be used.

    .PARAMETER Csr
    The PKCS#10 Certificate Signing Request (CSR).
    If this value is provided, any Subject DN fields and the KeyBitSize in the request are ignored.

    .PARAMETER CertificateType
    Type of certificate to be created.  The default is X.509 Server Certificate.

    .PARAMETER CertificateAuthorityPath
    The path of the Certificate Authority Template object for enrolling the certificate.
    If the value is missing, it is expected a policy has been applied to Path.

    .PARAMETER CertificateAuthorityAttribute
    Name/value pairs providing any CA attributes to store with the Certificate object.
    During enrollment, these values will be submitted to the CA.

    .PARAMETER ManagementType
    The level of management that Trust Protection Platform applies to the certificate:
    - Enrollment: Default. Issue a new certificate, renewed certificate, or key generation request to a CA for enrollment. Do not automatically provision the certificate.
    - Provisioning:  Issue a new certificate, renewed certificate, or key generation request to a CA for enrollment. Automatically install or provision the certificate.
    - Monitoring:  Allow Trust Protection Platform to monitor the certificate for expiration and renewal.
    - Unassigned: Certificates are neither enrolled or monitored by Trust Protection Platform.

    .PARAMETER SubjectAltName
    A list of Subject Alternate Names.
    The value must be 1 or more hashtables with the SAN type and value.
    Acceptable SAN types are OtherName, Email, DNS, URI, and IPAddress.
    You can provide more than 1 of the same SAN type with multiple hashtables.

    .PARAMETER CustomField
    Hashtable of custom field(s) to be updated when creating the certificate.
    This is required when the custom fields are mandatory.
    The key is the name, not guid, of the custom field.

    .PARAMETER NoWorkToDo
    Turn off lifecycle processing for this certificate update

    .PARAMETER Device
    An array of hashtables for devices to be created.
    Available parameters can be found at https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Certificates-request.php.
    If provisioning applications as well, those should be provided with the Application parameter.

    .PARAMETER Application
    An array of hashtables for applications to be created.
    Available parameters can be found at https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Certificates-request-ApplicationsParameter.php.
    In addition to the application parameters, a key/value must be provided for the associated device.
    The key needs to be 'DeviceName' and the value is the ObjectName from the device.
    See the example.

    .PARAMETER TimeoutSec
    Control the wait time, in seconds, for a CA to issue/renew a certificate.
    Can be set globally in the product, https://docs.venafi.com/Docs/currentSDK/TopNav/Content/SDK/WebSDK/r-SDK-Certificates-API-settings.php.
    Use this as an override to the global setting.

    .PARAMETER PassThru
    Return an object representing the newly created certificate.
    If devices and/or applications were created, a 'Device' property will be available as well.

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.

    .INPUTS
    None

    .OUTPUTS
    PSCustomObject, if PassThru is provided
    If devices and/or applications were created, a 'Device' property will be available as well.

    .EXAMPLE
    New-VdcCertificate -Path '\ved\policy\folder' -Name 'mycert.com'
    Create certificate by name.  A CA template policy must be defined.

    .EXAMPLE
    New-VdcCertificate -Path '\ved\policy\folder' -Name 'mycert.com' -CertificateAuthorityPath '\ved\policy\CA Templates\my template'
    Create certificate by name with specific CA template

    .EXAMPLE
    New-VdcCertificate -Path '\ved\policy\folder' -CertificateAuthorityPath '\ved\policy\CA Templates\my template' -Csr '-----BEGIN CERTIFICATE REQUEST-----\nMIIDJDCCAgwCAQAw...-----END CERTIFICATE REQUEST-----'
    Create certificate using a CSR

    .EXAMPLE
    New-VdcCertificate -Path '\ved\policy\folder' -Name 'mycert.com' -CertificateAuthorityPath '\ved\policy\CA Templates\my template' -CustomField @{''=''}
    Create certificate and update custom fields

    .EXAMPLE
    New-VdcCertificate -Path '\ved\policy\folder' -CommonName 'mycert.com' -CertificateAuthorityPath '\ved\policy\CA Templates\my template' -PassThru
    Create certificate using common name.  Return the created object.

    .EXAMPLE
    New-VdcCertificate -Path '\ved\policy\folder' -Name 'mycert.com' -CertificateAuthorityPath '\ved\policy\CA Templates\my template' -SubjectAltName @{'Email'='me@x.com'},@{'IPAddress'='1.2.3.4'}
    Create certificate including subject alternate names

    .EXAMPLE
    New-VdcCertificate -Path '\ved\policy\folder' -Name 'mycert.com' -Device @{'PolicyDN'=$DevicePath; 'ObjectName'='MyDevice'; 'Host'='1.2.3.4'} -Application @{'DeviceName'='MyDevice'; 'ObjectName'='BasicApp'; 'DriverName'='appbasic'}
    Create a new certificate with associated device and app objects

    .LINK
    https://venafi.github.io/VenafiPS/functions/New-VdcCertificate/

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/New-VdcCertificate.ps1

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Certificates-request.php

    #>

    [CmdletBinding(DefaultParameterSetName = 'ByName', SupportsShouldProcess)]
    [Alias('New-TppCertificate')]

    param (

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if ( $_ | Test-TppDnPath ) {
                    $true
                }
                else {
                    throw "'$_' is not a valid DN path"
                }
            })]
        [Alias('PolicyDN')]
        [String] $Path,

        [Parameter(Mandatory, ParameterSetName = 'ByName', ValueFromPipeline)]
        [Parameter(Mandatory, ParameterSetName = 'ByNameWithDevice', ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [String] $Name,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Alias('Subject')]
        [String] $CommonName,

        [Parameter()]
        [string] $Csr,

        [Parameter()]
        [String] $CertificateType,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if ( $_ | Test-TppDnPath ) {
                    $true
                }
                else {
                    throw "'$_' is not a valid DN path"
                }
            })]
        [Alias('CertificateAuthorityDN')]
        [Alias('CADN')]
        [String] $CertificateAuthorityPath,

        [Parameter()]
        [Hashtable] $CertificateAuthorityAttribute,

        [Parameter()]
        [TppManagementType] $ManagementType,

        [Parameter()]
        [Hashtable[]] $SubjectAltName,

        [Parameter()]
        [Hashtable] $CustomField,

        [Parameter()]
        [switch] $NoWorkToDo,

        [Parameter(ParameterSetName = 'ByName')]
        [Parameter(Mandatory, ParameterSetName = 'ByNameWithDevice')]
        [hashtable[]] $Device,

        [Parameter(ParameterSetName = 'ByNameWithDevice')]
        [hashtable[]] $Application,

        [Parameter()]
        [Alias('WorkToDoTimeout')]
        [ValidateRange(0, 120)]
        [int32] $TimeoutSec,

        [Parameter()]
        [switch] $PassThru,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {

        Test-VenafiSession $PSCmdlet.MyInvocation

        if ( $PSBoundParameters.ContainsKey('SubjectAltName') ) {

            $errors = $SubjectAltName | ForEach-Object {
                $_.GetEnumerator() | ForEach-Object {

                    $thisKey = $_.Key
                    $thisValue = $_.Value

                    switch ($thisKey) {
                        'OtherName' {
                            # no validaton
                        }

                        'Email' {
                            try {
                                $null = [mailaddress]$thisValue
                            }
                            catch {
                                ('''{0}'' is not a valid email' -f $thisValue)
                            }
                        }

                        'DNS' {
                            # no validaton
                        }

                        'URI' {
                            # no validaton
                        }

                        'IPAddress' {
                            try {
                                $null = [ipaddress]$thisValue
                            }
                            catch {
                                ('''{0}'' is not a valid IP Address' -f $thisValue)
                            }
                        }

                        Default {
                            # invalid type name provided
                            ('''{0}'' is not a valid SAN type.  Valid values include OtherName, Email, DNS, URI, and IPAddress.' -f $thisKey)
                        }
                    }
                }
            }

            if ( $errors ) {
                throw $errors
            }
        }

        $params = @{

            Method  = 'Post'
            UriLeaf = 'certificates/request'
            Body    = @{
                PolicyDN             = $Path
                Origin               = 'VenafiPS'
                CASpecificAttributes = @(
                    @{
                        'Name'  = 'Origin'
                        'Value' = 'VenafiPS'
                    }
                )
                SetWorkToDo          = -not $NoWorkToDo
            }
        }

        if ( $CertificateType ) {
            $params.Body.Add('CertificateType', $CertificateType)
        }

        if ( $PSBoundParameters.ContainsKey('CertificateAuthorityAttribute') ) {
            $CertificateAuthorityAttribute.GetEnumerator() | ForEach-Object {

                $params.Body.CASpecificAttributes +=
                @{
                    'Name'  = $_.Key
                    'Value' = $_.Value
                }
            }
        }

        if ( $Csr ) {
            $params.Body.Add('PKCS10', ($Csr -replace "`n|`r"))
        }

        if ( $PSBoundParameters.ContainsKey('CertificateAuthorityPath') ) {
            $params.Body.Add('CADN', $CertificateAuthorityPath)
        }

        if ( $PSBoundParameters.ContainsKey('CommonName') ) {
            $params.Body.Add('Subject', $CommonName)
        }

        if ( $PSBoundParameters.ContainsKey('ManagementType') ) {
            $params.Body.Add('ManagementType', [enum]::GetName([TppManagementType], $ManagementType))
        }

        if ( $PSBoundParameters.ContainsKey('TimeoutSec') ) {
            $params.Body.Add('WorkToDoTimeout', $TimeoutSec)
        }

        if ( $PSBoundParameters.ContainsKey('SubjectAltName') ) {
            $newSan = @($SubjectAltName | ForEach-Object {
                    $_.GetEnumerator() | ForEach-Object {
                        @{
                            'TypeName' = $_.Key
                            'Name'     = $_.Value
                        }
                    }
                }
            )
            $params.Body.Add('SubjectAltNames', $newSan)
        }

        if ( $PSBoundParameters.ContainsKey('CustomField') ) {
            $newCf = $CustomField.GetEnumerator() | ForEach-Object {

                @{
                    'Name'   = $_.Key
                    'Values' = @($_.Value)
                }
            }
            $params.Body.Add('CustomFields', @($newCf))
        }

        if ( $Device ) {
            # convert apps to array of custom objects to make it easier to search
            $appCustom = @($Application | ForEach-Object { [pscustomobject] $_ })

            # loop through devices and append any apps found
            $updatedDevice = foreach ($thisDevice in $Device) {

                $thisApplication = $appCustom | Where-Object { $_.DeviceName -eq $thisDevice.ObjectName }

                if ( $thisApplication ) {
                    $finalAppList = foreach ($app in $thisApplication | Select-Object -Property * -ExcludeProperty DeviceName) {
                        $ht = @{}
                        $app.psobject.properties | ForEach-Object { $ht[$_.Name] = $_.Value }
                        $ht
                    }

                    $thisDevice.Applications = @($finalAppList)
                }

                $thisDevice
            }
            $params.Body.Add('Devices', @($updatedDevice))

        }
    }

    process {

        $params.Body.ObjectName = $Name
        if ( -not $PSBoundParameters.ContainsKey('CommonName')) {
            $params.Body.Subject = $Name
        }

        if ( $PSCmdlet.ShouldProcess("$Path\$Name", 'Create new certificate') ) {

            try {
                $response = Invoke-VenafiRestMethod @params
                Write-Verbose ($response | Out-String)

                if ( $PassThru ) {
                    $newCert = Get-VdcObject -Path $response.CertificateDN
                    if ( $response.Devices.DN ) {
                        $newCert | Add-Member @{ 'Device' = @{'Path' = $response.Devices.DN } }
                        if ( $response.Devices.Applications.DN ) {
                            $newCert.Device.Application = $response.Devices.Applications.DN
                        }
                    }
                    $newCert
                }
            }
            catch {
                Write-Error $_
                continue
            }
        }
    }
}


