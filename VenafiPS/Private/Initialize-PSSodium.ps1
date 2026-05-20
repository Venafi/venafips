function Initialize-PSSodium {
    [CmdletBinding()]
    param (
        [Parameter()]
        [switch] $Force
    )

    # Check if the module is already loaded
    if ( Get-Module PSSodium ) {
        return
    }

    # Check if the module is installed
    $module = Get-Module PSSodium -ListAvailable | Where-Object { $_.Version -eq $script:pssodiumVersion }

    if ( -not $module ) {
        if ( $Force ) {
            Install-Module -Name PSSodium -Repository PSGallery -Force -RequiredVersion $script:pssodiumVersion

            # validate hash
            $modulePath = $module.ModuleBase

            $script:pssodiumHash | ForEach-Object {
                $fullPath = Join-Path $modulePath $_.Path
                $CurrentHash = (Get-FileHash $fullPath -Algorithm SHA256).Hash
                if ($CurrentHash -ne $_.Hash) {
                    throw "PSSodium file tampered with: $fullPath"
                }
                else {
                    Write-Verbose "PSSodium file validated: $fullPath"
                }
            }
        }
        else {
            throw "The PSSodium module is not installed.  Add -Force for the module to be automatically installed or install v$script:pssodiumVersion from the PowerShell Gallery."
        }
    }

    try {
        Import-Module -Name PSSodium -RequiredVersion $script:pssodiumVersion -Force -ErrorAction Stop
    }
    catch {
        throw "Sodium encryption could not be loaded.  Ensure you are running PowerShell v7+ and if on Windows, install the latest Visual C++ Runtime.  $_"
    }
}
