function Add-VdcAdaptableHash {
    <#
    .SYNOPSIS
    Adds or updates the hash value for an adaptable script

    .DESCRIPTION
    TLSPDC stores a base64 encoded hash of the file contents of an adaptable script in the Secret Store. This is referenced by
    the Attribute 'PowerShell Script Hash Vault Id' on the DN of the adaptable script. This script retrieves the hash (if
    present) from the Secret Store and compares it to the hash of the file in one of the scripts directories. It then adds
    a new or updated hash if required. When updating an existing hash, it removes the old one from the Secret Store.

    .PARAMETER Path
    Required. Path to the object to add or update the hash.
    For an adaptable app or an onboard discovery, 'Path' must always be a policy folder as this is where the hash is saved.

    .PARAMETER Keyname
    The name of the Secret Encryption Key (SEK) to used when encrypting this item. Default is "Software:Default"

    .PARAMETER FilePath
    Required. The full path to the adaptable script file. This should typically be in a
    '<drive>:\Program Files\Venafi\Scripts\<subdir>' directory for TLSPDC to recognize the script.

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.

    .INPUTS
    None

    .OUTPUTS
    None

    .EXAMPLE
    Add-VdcAdaptableHash -Path '\ved\policy\MyAppDriver' -FilePath 'C:\Program Files\Venafi\Scripts\AdaptableApp\AppDriver.ps1'

    Update the hash on an adaptable app object.

    .EXAMPLE
    Add-VdcAdaptableHash -Path $Path -FilePath 'C:\Program Files\Venafi\Scripts\AdaptableLog\Generic-LogDriver.ps1'

    Update the hash on an adaptable log object.

    .LINK
    https://venafi.github.io/VenafiPS/functions/Add-VdcAdaptableHash/

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Add-VdcAdaptableHash.ps1

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Secretstore-add.php

    .LINK
    https://docs.venafi.com/Docs/currentSDK/TopNav/Content/SDK/WebSDK/r-SDK-POST-Secretstore-ownerdelete.php

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-POST-Secretstore-retrieve.php
    #>

    [CmdletBinding(SupportsShouldProcess)]
    [Alias('Add-TppAdaptableHash')]

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
        [Alias('DN')]
        [String] $Path,

        [Parameter()]
        [string] $Keyname = "Software:Default",

        [Parameter(Mandatory)]
        [Alias('File')]
        [string] $FilePath,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation
    }

    process {
        $thisObject = Get-VdcObject -Path $Path

        $existingVaultId = if ( $thisObject.TypeName -eq 'Policy' ) {
            Get-VdcAttribute -Path $thisObject.Path -Class 'Adaptable App' -Attribute 'PowerShell Script Hash Vault Id' -AsValue
        }
        else {
            Get-VdcAttribute -Path $thisObject.Path -Attribute 'PowerShell Script Hash Vault Id' -AsValue
        }

        $bytes = [Text.Encoding]::UTF32.GetBytes([IO.File]::ReadAllText($FilePath))
        $hash = Get-FileHash -InputStream ([System.IO.MemoryStream]::New($bytes))
        $newBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($hash.hash.ToLower()))

        if ( $existingVaultId ) {
            $paramsRetrieve = @{
                Method  = 'Post'
                UriLeaf = 'SecretStore/retrieve'
                Body    = @{
                    VaultID = $existingVaultId
                }
            }

            $retrieveResponse = Invoke-VenafiRestMethod @paramsRetrieve

            if ( $retrieveResponse.Result -ne [TppSecretStoreResult]::Success ) {
                Write-Error ("Error retrieving VaultID: {0}" -f [enum]::GetName([TppSecretStoreResult], $retrieveResponse.Result)) -ErrorAction Stop
            }

            if ($null -ne $retrieveResponse.Base64Data) {
                $currentBase64 = $retrieveResponse.Base64Data
            }
        }

        if ( $newBase64 -eq $currentBase64 ) {
            'PowerShell Script Hash Vault Id unchanged for {0}' -f $thisObject.Path | Write-Verbose
            return
        }

        # if Owner happens to have a trailing slash, this call fails
        $paramsAdd = @{
            Method  = 'Post'
            UriLeaf = 'SecretStore/Add'
            Body    = @{
                VaultType  = '128'
                Keyname    = $Keyname
                Base64Data = $newBase64
                Namespace  = 'Config'
                Owner      = $thisObject.Path
            }
        }

        $addResponse = Invoke-VenafiRestMethod @paramsAdd

        $addResponse | Write-Verbose

        if ( $addResponse.Result -ne [TppSecretStoreResult]::Success ) {
            throw ("Error adding VaultID: {0}" -f [enum]::GetName([TppSecretStoreResult], $addResponse.Result))
        }

        if ( $thisObject.TypeName -eq 'Policy' ) {
            Set-VdcAttribute -Path $thisObject.Path -PolicyClass 'Adaptable App' -Attribute @{ 'PowerShell Script Hash Vault Id' = [string]$addresponse.VaultID } -Lock -ErrorAction Stop
        }
        else {
            Set-VdcAttribute -Path $thisObject.Path -Attribute @{ 'PowerShell Script Hash Vault Id' = [string]$addresponse.VaultID } -ErrorAction Stop
        }

        'PowerShell Script Hash Vault Id for {0} set to {1}' -f $thisObject.Path, $addResponse.VaultID | Write-Verbose

        # cleanup old vault entry if we succeeded in adding the new
        if ( $currentBase64 -and $addResponse.VaultID ) {

            'Removing old VaultID {0}' -f $existingVaultId | Write-Verbose

            $paramsDelete = @{
                Method  = 'Post'
                UriLeaf = 'SecretStore/OwnerDelete'
                Body    = @{
                    Namespace = 'Config'
                    Owner     = $thisObject.Path
                    VaultID   = $existingVaultId
                }
            }

            $deleteResponse = Invoke-VenafiRestMethod @paramsDelete

            if ( $deleteResponse.Result -ne [TppSecretStoreResult]::Success ) {
                Write-Error ("Error removing VaultID: {0}" -f [enum]::GetName([TppSecretStoreResult], $deleteResponse.Result)) -ErrorAction Stop
            }
        }
    }
}

