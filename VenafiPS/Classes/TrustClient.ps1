class TrustClient {

    [string] $Platform
    [string] $Server
    [int] $TimeoutSec
    [bool] $SkipCertificateCheck
    [string] $AuthType
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
    [object] $Version
    [object] $CustomField
    [object] $User

    TrustClient() {
        $this.Platform = 'VDC'
        $this.Server = ''
        $this.TimeoutSec = 0
        $this.SkipCertificateCheck = $false
        $this.AuthType = ''
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
        $this.Version = $null
        $this.CustomField = $null
        $this.User = $null
    }

    [bool] IsExpired() {
        if ($this.Expires -gt [datetime]::MinValue) {
            return $this.Expires -lt ([DateTime]::UtcNow.AddSeconds(60))
        }
        return $false
    }

    [bool] CanRefresh() {
        if ($this.Platform -eq 'NGTS') {
            return $null -ne $this.Credential
        }

        if ($this.RefreshToken -and $this.AuthServer -and $this.ClientId) {
            if ($this.RefreshExpires -gt [datetime]::MinValue) {
                return $this.RefreshExpires -gt [DateTime]::UtcNow
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
            Invoke-SessionRefresh -Session $this
        }
        catch {
            throw "Failed to refresh access token: $($_.Exception.Message)"
        }
    }

    [void] Revoke() {
        switch ($this.Platform) {
            'VDC' {
                if (-not $this.AccessToken) {
                    throw 'No access token to revoke.'
                }
                Invoke-TrustRestMethod -TrustClient $this -Method Get -UriRoot 'vedauth' -UriLeaf 'Revoke/Token'
                break
            }
            'VC' {
                throw 'Token revocation is not supported for Certificate Manager, SaaS.'
            }
            'NGTS' {
                Write-Warning 'Token revocation is not currently supported for NGTS/SCM.  Clearing tokens locally, but this session may still be valid until the access token expires.'
            }
        }

        $this.AccessToken = $null
        $this.RefreshToken = $null
        $this.Expires = [datetime]::MinValue
        $this.RefreshExpires = [datetime]::MinValue
    }
}
