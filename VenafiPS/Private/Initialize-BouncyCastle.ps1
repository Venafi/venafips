function Initialize-BouncyCastle {
    <#
    .SYNOPSIS
    Load the BouncyCastle cryptography library bundled with the module

    .DESCRIPTION
    Load the BouncyCastle cryptography library, used for VSatellite encryption, if it isn't already loaded.
    If another module has already loaded a compatible version, v2 or greater, that version is used.
    #>

    [CmdletBinding()]
    param ()

    $loaded = [System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.GetName().Name -eq 'BouncyCastle.Cryptography' } | Select-Object -First 1

    if ( $loaded ) {
        if ( $loaded.GetName().Version.Major -lt 2 ) {
            throw ('BouncyCastle.Cryptography v{0} is already loaded in this session, but v2 or greater is required.  Start a new PowerShell session and try again.' -f $loaded.GetName().Version)
        }
        Write-Verbose ('BouncyCastle.Cryptography v{0} already loaded from {1}' -f $loaded.GetName().Version, $loaded.Location)
        return
    }

    try {
        Add-Type -Path $script:BouncyCastlePath -ErrorAction Stop
    }
    catch {
        throw "BouncyCastle encryption library could not be loaded from $($script:BouncyCastlePath).  $_"
    }
}
