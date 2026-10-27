function Invoke-SessionRefresh {
    <#
    .SYNOPSIS
    Refresh an expired TrustClient token.

    .DESCRIPTION
    Module-scoped function that performs the actual token refresh for a TrustClient.
    Separated from the class method so that Pester can mock the underlying token functions.

    .PARAMETER Session
    The TrustClient object to refresh. Updated in-place.
    #>

    param(
        [Parameter(Mandatory)]
        [TrustClient] $Session
    )

    $newToken = if ($Session.Platform -eq 'CM') {
        $refreshParams = @{
            AuthServer           = $Session.AuthServer
            RefreshToken         = $Session.RefreshToken
            ClientId             = $Session.ClientId
            SkipCertificateCheck = $Session.SkipCertificateCheck
        }
        New-CmToken @refreshParams -ErrorAction Stop
    }
    elseif ($Session.Platform -eq 'NGTS') {
        $ngtsParams = @{
            Credential = $Session.Credential
        }
        if ($Session.PlatformData.Tsg) {
            $ngtsParams.Tsg = $Session.PlatformData.Tsg
        }
        New-NgtsToken @ngtsParams -ErrorAction Stop
    }
    elseif ($Session.Platform -eq 'CMS') {
        if ( $Session.AuthType -eq 'ApiKey' ) {
            Update-CmsApiKey -TrustClient $Session -ErrorAction Stop
        }
    }
    else {
        throw "Unknown platform $($Session.Platform) for token refresh"
    }

    $Session.AccessToken = $newToken.AccessToken
    $Session.Scope = $newToken.Scope
    $Session.ApiKey = $newToken.ApiKey
    $Session.Expires = $newToken.Expires
    if ($newToken.RefreshToken) { $Session.RefreshToken = $newToken.RefreshToken }
    if ($newToken.RefreshExpires -gt [datetime]::MinValue) { $Session.RefreshExpires = $newToken.RefreshExpires }
    if ($newToken.ClientId) { $Session.ClientId = $newToken.ClientId }
    if ($newToken.Server) { $Session.AuthServer = $newToken.Server }

    # CM refresh tokens are single use so the one in the vault is no longer valid.
    # Save the new one, with the existing metadata, so the next New-TrustClient -VaultRefreshTokenName works.
    if ($Session.Platform -eq 'CM' -and $Session.VaultRefreshTokenName -and $newToken.RefreshToken) {
        try {
            $secretInfo = Get-SecretInfo -Name $Session.VaultRefreshTokenName -Vault 'VenafiPS' -ErrorAction Stop | Select-Object -First 1
            $metadata = @{}
            if ($secretInfo.Metadata) {
                foreach ($key in $secretInfo.Metadata.Keys) { $metadata[$key] = $secretInfo.Metadata[$key] }
            }
            Set-Secret -Name $Session.VaultRefreshTokenName -Secret $newToken.RefreshToken -Vault 'VenafiPS' -Metadata $metadata -ErrorAction Stop
        }
        catch {
            Write-Warning ("The access token was refreshed, but the new refresh token could not be saved to vault entry '{0}'.  The next New-TrustClient -VaultRefreshTokenName {0} will fail until the entry is recreated with credentials.  {1}" -f $Session.VaultRefreshTokenName, $_.Exception.Message)
        }
    }
}
