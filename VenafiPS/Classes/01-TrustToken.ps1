class TrustToken {

    [string] $Server
    [pscredential] $AccessToken
    [pscredential] $RefreshToken
    [pscredential] $Credential
    [object] $Scope
    [string] $Identity
    [string] $TokenType
    [string] $ClientId
    [datetime] $Expires
    [datetime] $RefreshExpires

    TrustToken() {
        $this.Server = ''
        $this.AccessToken = $null
        $this.RefreshToken = $null
        $this.Credential = $null
        $this.Scope = $null
        $this.Identity = ''
        $this.TokenType = ''
        $this.ClientId = ''
        $this.Expires = [datetime]::MinValue
        $this.RefreshExpires = [datetime]::MinValue
    }
}
