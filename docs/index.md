<p align="center">
  <img src="images/cybr-mis.jpeg" alt="CyberArk"/>
</p>

# VenafiPS - Automate your CyberArk Certificate Manager (Venafi TLS Protect) Self-Hosted and SaaS platforms!

[![Testing](https://github.com/Venafi/VenafiPS/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/Venafi/VenafiPS/actions/workflows/ci.yml)
[![Deployment](https://github.com/Venafi/VenafiPS/actions/workflows/cd.yml/badge.svg?branch=main)](https://github.com/Venafi/VenafiPS/actions/workflows/cd.yml)
[![Documentation Status](https://readthedocs.org/projects/venafips/badge/?version=latest)](https://venafips.readthedocs.io/en/latest/?badge=latest)
[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/VenafiPS?style=plastic)](https://www.powershellgallery.com/packages/VenafiPS)
![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/VenafiPS?style=plastic)

Welcome to VenafiPS (where the PS stands for PowerShell, not Professional Services :smiley:).  Here you will find a PowerShell module to automate Venafi TLS Protect Datacenter (TLSPDC), formerly known as Trust Protection Platform, and TLS Protect Cloud (TLSPC).  Please let us know how you are using this module and what we can do to make it better!  Ask questions or feel free to [submit an issue/enhancement](https://github.com/Venafi/VenafiPS/issues).

## Documentation

Documentation can be found at [http://VenafiPS.readthedocs.io](http://VenafiPS.readthedocs.io) or by using built-in PowerShell help.  Every effort has been made to document each parameter and provide good examples.

## Supported Platforms

VenafiPS works on PowerShell v5.1 as well as cross-platform PowerShell on Windows, Linux, and Mac.

## Install Module

VenafiPS is published to the PowerShell Gallery.  The most recent version is listed in the badge 'powershell gallery' above and can be viewed by clicking on it.  To install the module, you need to have PowerShell installed first.  On Windows, Windows PowerShell (v5.x) will already be installed, but is recommended to install the latest version of cross-platform PowerShell.  For [Linux](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux?view=powershell-7) or [macOS](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-macos?view=powershell-7), you will need to install PowerShell; follow those links for guidance.  Once PowerShell is installed, start a PowerShell prompt and execute `Install-Module -Name VenafiPS` which will install from the gallery.

> :warning: If using an older operating system, eg. Windows Server 2016, and you receive errors downloading/installing nuget when attempting to install VenafiPS, your SSL/TLS version is most likely at the default and will not work.  Execute the following before installing the module,
``` powershell
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
```

### Additional Modules

- If running on Windows with PowerShell v5, multithreading is supported with [Microsoft.PowerShell.ThreadJob](https://github.com/PowerShell/ThreadJob), a Microsoft PowerShell module.  Install this via `Install-Module -Name Microsoft.PowerShell.ThreadJob` for increased performance on the functions that support it.  Version 2.1.0 has been tested.
- There are a few TLSPC functions which require Sodium encryption.  These functions require the PSSodium module be installed from the PowerShell Gallery via `Install-Module -Name PSSodium -RequiredVersion '0.4.2'`.  Optionally, you can provide `-Force` to the function for the module to be automatically installed .  Also for those functions, on Windows, the latest C++ runtime must be installed.  Version 0.4.2 has been tested.

## Usage

As the module supports both TLSPDC and TLSPC, you will note different names for the functions.  Functions with `-Vdc` are for TLSPDC only, `-Vc` are for TLSPC only, and `-Venafi` are for both.  You can easily see the available commands for each platform with
``` powershell
Get-Command -Module VenafiPS -Name '*-Vdc*' # for TLSPDC functions
Get-Command -Module VenafiPS -Name '*-Vc*' # for TLSPC functions
```

For TLSPDC, [token based authentication](https://docs.venafi.com/Docs/current/TopNav/Content/SDK/AuthSDK/t-SDKa-Setup-OAuth.php) must be setup and configured.

We want to create a Venafi session which will hold the details needed for future operations.  Start a new PowerShell prompt (even if you have one from the install-module step) and create a new VenafiPS session with:

```powershell
# username/password for TLSPDC.  TLSPC uses any value for username and your api key for the password
$cred = Get-Credential

# create a session for TLSPDC
New-VenafiSession -Server 'venafi.mycompany.com' -Credential $cred -ClientId 'MyApp' -Scope @{'certificate'='manage'}

# create a session for TLSPC (your API key can be found in your user profile -> preferences)
New-VenafiSession -VcKey $cred
```

The above will create a session variable named $VenafiSession which will be used by default in other functions.

View the help on all the ways you can create a new Venafi session with
``` powershell
help New-VenafiSession -full
```
To utilize the SecretManagement vault functionality, ensure you [complete the setup below](https://github.com/Venafi/VenafiPS#tokenkey-secret-storage).

## TLSPDC Examples

One of the easiest ways to get started is to use `Find-VdcObject`:

```powershell
$allPolicy = Find-VdcObject -Path '\ved\policy' -Recursive
```

This will return all objects in the Policy folder.  You can also search from the root folder, \ved.

To find a certificate object, not retrieve an actual certificate, use:
```powershell
$cert = Find-VdcCertificate -First 1
```

Check out the parameters for `Find-VdcCertificate` as there's an extensive list to search on.

Now you can take that certificate object and find all log entries associated with it:

```powershell
$cert | Read-VdcLog
```

To perform many of the core certificate actions, we will use `Invoke-VdcCertificateAction`.  For example, to create a new session and renew a certificate, use the following:

```powershell
New-VenafiSession -Server 'venafi.mycompany.com' -Credential $cred -ClientId 'MyApp' -Scope @{'certificate'='manage'}
Invoke-VdcCertificateAction -CertificateId '\VED\Policy\My folder\app.mycompany.com' -Renew
```

You can also find and perform an action on mutliple objects.  In this example we find all certificates expriring in the next 30 days and renew them

``` powershell
Find-VdcCertificate -ExpireBefore (Get-Date).AddDays(30) -ExpireAfter (Get-Date) | Invoke-VdcCertificateAction -Renew
```

You can also have multiple sessions at once, either to the same server with different credentials or different servers.
This can be helpful to determine the difference between what different users can access or perhaps compare folder structures across environments.  The below will compare the objects one user can see vs. another.

```powershell
# assume you've created 1 session already as shown above...

$user2Cred = Get-Credential # specify credentials for a different/limited user

# get a session as user2 and save the session in a variable
$user2Session = New-VenafiSession -ServerUrl 'https://venafi.mycompany.com' -Credential $user2Cred -PassThru

# get all objects in the Policy folder for the first user
$all = Find-VdcObject -Path '\ved\policy' -Recursive

# get all objects in the Policy folder for user2
$all2 = Find-VdcObject -Path '\ved\policy' -Recursive -VenafiSession $user2Session

Compare-Object -ReferenceObject $all -DifferenceObject $all2 -Property Path
```

## TLSPC Examples

Most of the same functionality from the above examples exist for TLSPC as well.  Simply replace `-Vdc` with `-Vc`.

## Token/Key Secret Storage

To securely store and retrieve secrets, VenafiPS has added support for the [PowerShell SecretManagement module](https://github.com/PowerShell/SecretManagement).  This can be used to store your access tokens, refresh tokens, or vaas key.  To use this feature, a vault will need to be created.  You can use [SecretStore](https://github.com/PowerShell/SecretStore) provided by the PowerShell team or any other vault type.  All of this functionality has been added to `New-VenafiSession`.  To prepare your environment, execute the following:
- `Install-Module Microsoft.PowerShell.SecretManagement`
- `Install-Module Microsoft.PowerShell.SecretStore` or whichever vault you would like to use
- `Register-SecretVault -Name VenafiPS -ModuleName Microsoft.PowerShell.SecretStore`.  If you are using a different vault type, replace the value for `-ModuleName`.
- If using the vault Microsoft.PowerShell.SecretStore, execute `Set-SecretStoreConfiguration -Authentication None -Confirm:$false`.  Note, although the vault authentication is set to none, this just turns off the password required to access the vault, it does not mean your secrets are not encrypted.  This is required for automation purposes.  If using a different vault type, ensure you turn off any features which inhibit automation.
- Check out the help for `New-VenafiSession` for the many ways you can store and retrieve secrets from the vault, but the easiest way to get started is:
  - `New-VenafiSession -Server my.venafi.com -Credential $myCred -ClientId MyApp -Scope $scope -VaultRefreshTokenName tlspdc-token`.  This will create a new token based session and store the refresh token in the vault.  The server and clientid will be stored with the refresh token as metadata.  Scope does not need to be stored as it is inherent in the token.
  - To create a new session going forward, `New-VenafiSession -VaultRefreshTokenName tlspdc-token`.  This will retrieve the refresh token and associated metadata from the vault, retrieve a new access token based on that refresh token and create a new session.

Note, extension vaults are registered to the current logged in user context, and will be available only to that user (unless also registered to other users).

## Contributing

Please feel free to log an issue for any new features you would like, bugs you come across, or just simply a question.  We are happy to have people contribute to the codebase as well.
