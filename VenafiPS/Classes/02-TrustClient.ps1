class TrustClient {

    [TrustPlatform] $Platform
    [string] $Server
    [int] $TimeoutSec
    [bool] $SkipCertificateCheck
    [TrustAuthType] $AuthType
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
        $this.Platform = [TrustPlatform]::None
        $this.Server = ''
        $this.TimeoutSec = 0
        $this.SkipCertificateCheck = $false
        $this.AuthType = [TrustAuthType]::None
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

    # Valid platform + auth type combinations and their required properties
    static [hashtable] $AuthRules = @{
        [TrustPlatform]::VDC  = @{
            [TrustAuthType]::BearerToken = @('AccessToken', 'Server')
        }
        [TrustPlatform]::VC   = @{
            [TrustAuthType]::BearerToken = @('AccessToken', 'Server')
            [TrustAuthType]::ApiKey      = @('ApiKey', 'Server')
        }
        [TrustPlatform]::NGTS = @{
            [TrustAuthType]::ClientCredential = @('Credential', 'AccessToken', 'Expires', 'Server')
        }
    }

    [void] Validate() {
        if ($this.Platform -eq [TrustPlatform]::None) {
            throw 'Platform must be set before validation.'
        }

        $platformRules = [TrustClient]::AuthRules[$this.Platform]
        if (-not $platformRules) {
            throw "No auth rules defined for platform '$($this.Platform)'."
        }

        if ($this.AuthType -eq [TrustAuthType]::None -or -not $platformRules.ContainsKey($this.AuthType)) {
            $validTypes = ($platformRules.Keys | ForEach-Object { $_.ToString() }) -join ', '
            throw "'$($this.AuthType)' is not a valid auth type for platform '$($this.Platform)'. Valid types: $validTypes"
        }

        $missing = foreach ($prop in $platformRules[$this.AuthType]) {
            if (-not $this.$prop) { $prop }
        }
        if ($missing) {
            throw "Missing required properties for $($this.Platform) + $($this.AuthType): $($missing -join ', ')"
        }
    }

    # region VDC factory methods
    static [TrustClient] NewVdcBearerToken([string]$server, [pscredential]$accessToken) {
        $client = [TrustClient]::new()
        $client.Platform = [TrustPlatform]::VDC
        $client.Server = $server
        $client.AuthType = [TrustAuthType]::BearerToken
        $client.AccessToken = $accessToken
        $client.Validate()
        return $client
    }

    static [TrustClient] NewVdcBearerToken([string]$server, [TrustToken]$token) {
        $client = [TrustClient]::NewVdcBearerToken($server, $token.AccessToken)
        $client.AuthServer = $token.Server
        $client.RefreshToken = $token.RefreshToken
        $client.ClientId = $token.ClientId
        $client.Scope = $token.Scope
        $client.Expires = $token.Expires
        if ($token.RefreshExpires -gt [datetime]::MinValue) { $client.RefreshExpires = $token.RefreshExpires }
        if ($token.Credential) { $client.Credential = $token.Credential }
        return $client
    }
    # endregion

    # region VC factory methods
    static [TrustClient] NewVcBearerToken([string]$server, [pscredential]$accessToken) {
        $client = [TrustClient]::new()
        $client.Platform = [TrustPlatform]::VC
        $client.Server = $server
        $client.AuthType = [TrustAuthType]::BearerToken
        $client.AccessToken = $accessToken
        $client.Validate()
        return $client
    }

    static [TrustClient] NewVcBearerToken([string]$server, [TrustToken]$token) {
        $client = [TrustClient]::NewVcBearerToken($server, $token.AccessToken)
        $client.AuthServer = $token.Server
        $client.Scope = $token.Scope
        $client.Expires = $token.Expires
        if ($token.Credential) { $client.Credential = $token.Credential }
        return $client
    }

    static [TrustClient] NewVcApiKey([string]$server, [pscredential]$apiKey) {
        $client = [TrustClient]::new()
        $client.Platform = [TrustPlatform]::VC
        $client.Server = $server
        $client.AuthType = [TrustAuthType]::ApiKey
        $client.ApiKey = $apiKey
        $client.Validate()
        return $client
    }
    # endregion

    # region NGTS factory methods
    static [TrustClient] NewNgtsClientCredential([string]$server, [pscredential]$credential, [TrustToken]$token) {
        $client = [TrustClient]::NewNgtsClientCredential($server, $credential, $token.AccessToken, $token.Expires)
        $client.Scope = $token.Scope
        return $client
    }

    static [TrustClient] NewNgtsClientCredential([string]$server, [pscredential]$credential, [pscredential]$accessToken, [datetime]$expires) {
        $client = [TrustClient]::new()
        $client.Platform = [TrustPlatform]::NGTS
        $client.Server = $server
        $client.AuthType = [TrustAuthType]::ClientCredential
        $client.Credential = $credential
        $client.AccessToken = $accessToken
        $client.Expires = $expires
        $client.Validate()
        return $client
    }
    # endregion

    [bool] CanRefresh() {
        switch ($this.Platform) {
            'VDC' {
                if ($this.RefreshToken -and $this.AuthServer -and $this.ClientId) {
                    if ($this.RefreshExpires -gt [datetime]::MinValue) {
                        return $this.RefreshExpires -gt [DateTime]::UtcNow
                    }
                    return $true
                }
                return $false
            }

            'VC' {
                if ($this.AuthType -eq 'BearerToken' -and $this.Credential) {
                    return $true
                }
                return $false
            }

            'NGTS' {
                return $null -ne $this.Credential
            }
        }
        return $false
    }

    [void] Refresh() {
        $this.Validate()

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
        $this.Validate()

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
