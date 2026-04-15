class VenafiAuth {

    [string] $Type
    [pscredential] $AccessToken
    [pscredential] $RefreshToken
    [pscredential] $ApiKey
    [pscredential] $Credential
    [string] $AuthServer
    [string] $ClientId
    [object] $Scope
    [datetime] $Expires
    [datetime] $RefreshExpires
    [string] $Tsg

    VenafiAuth() {
        $this.Type = ''
        $this.AccessToken = $null
        $this.RefreshToken = $null
        $this.ApiKey = $null
        $this.Credential = $null
        $this.AuthServer = ''
        $this.ClientId = ''
        $this.Scope = $null
        $this.Expires = [datetime]::MinValue
        $this.RefreshExpires = [datetime]::MinValue
        $this.Tsg = ''
    }
}

class VenafiSession {

    [string] $Platform
    [string] $Server
    [int] $TimeoutSec
    [bool] $SkipCertificateCheck
    [VenafiAuth] $Auth
    [object] $Version
    [object] $CustomField
    [object] $User

    VenafiSession() {
        $this.Platform = 'VDC'
        $this.Server = ''
        $this.TimeoutSec = 0
        $this.SkipCertificateCheck = $false
        $this.Auth = [VenafiAuth]::new()
        $this.Version = $null
        $this.CustomField = $null
        $this.User = $null
    }

    [bool] IsExpired() {
        if ($this.Auth -and $this.Auth.Expires -and $this.Auth.Expires -gt [datetime]::MinValue) {
            # Add 60-second buffer to avoid edge-case timing issues
            return $this.Auth.Expires -lt ([DateTime]::UtcNow.AddSeconds(60))
        }
        return $false
    }

    [bool] CanRefresh() {
        if ($this.Platform -eq 'NGTS') {
            return $null -ne $this.Auth.Credential
        }

        # Must have all components needed to refresh: refresh token, server, and client ID
        if ($this.Auth -and $this.Auth.RefreshToken -and $this.Auth.AuthServer -and $this.Auth.ClientId) {
            # Check if refresh token hasn't expired (if expiry is tracked)
            if ($this.Auth.RefreshExpires -and $this.Auth.RefreshExpires -gt [datetime]::MinValue) {
                return $this.Auth.RefreshExpires -gt [DateTime]::UtcNow
            }
            return $true
        }
        return $false
    }

    [void] Refresh() {
        if (-not $this.CanRefresh()) {
            throw 'This session cannot be auto-refreshed with its current authentication data.'
        }

        try {
            # Determine which platform token we're refreshing and call the appropriate function
            $newToken = if ($this.Platform -eq 'VDC') {
                $refreshParams = @{
                    AuthServer           = $this.Auth.AuthServer
                    RefreshToken         = $this.Auth.RefreshToken
                    ClientId             = $this.Auth.ClientId
                    SkipCertificateCheck = $this.SkipCertificateCheck
                }
                New-VdcToken @refreshParams -ErrorAction Stop
            }
            elseif ($this.Platform -eq 'NGTS') {
                $ngtsParams = @{
                    Credential = $this.Auth.Credential
                }
                if ($this.Auth.Tsg) {
                    $ngtsParams.Tsg = $this.Auth.Tsg
                }

                New-NgtsToken @ngtsParams -ErrorAction Stop
            }
            elseif ($this.Platform -eq 'VC') {
                # VC tokens may not support refresh, but try endpoint-based refresh if available
                Write-Verbose 'VC platform tokens typically do not support refresh via client credentials'
                throw 'Automatic token refresh is not available for VC platform'
            }
            else {
                throw "Unknown platform $($this.Platform) for token refresh"
            }

            # Update auth from the refreshed token response
            $this.Auth.AccessToken = $newToken.AccessToken
            if ($newToken.PSObject.Properties.Name -contains 'RefreshToken') { $this.Auth.RefreshToken = $newToken.RefreshToken }
            if ($newToken.PSObject.Properties.Name -contains 'Scope') { $this.Auth.Scope = $newToken.Scope }
            if ($newToken.PSObject.Properties.Name -contains 'Expires') { $this.Auth.Expires = $newToken.Expires }
            if ($newToken.PSObject.Properties.Name -contains 'RefreshExpires' -and $newToken.RefreshExpires) { $this.Auth.RefreshExpires = $newToken.RefreshExpires }
            if ($newToken.PSObject.Properties.Name -contains 'ClientId' -and $newToken.ClientId) { $this.Auth.ClientId = $newToken.ClientId }
            if ($newToken.PSObject.Properties.Name -contains 'Server' -and $newToken.Server) { $this.Auth.AuthServer = $newToken.Server }

            Write-Verbose 'Access token successfully refreshed'
        }
        catch {
            throw "Failed to refresh access token: $($_.Exception.Message)"
        }
    }
}
