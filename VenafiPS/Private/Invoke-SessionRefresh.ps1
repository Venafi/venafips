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

    $newToken = if ($Session.Platform -eq 'VDC') {
        $refreshParams = @{
            AuthServer           = $Session.AuthServer
            RefreshToken         = $Session.RefreshToken
            ClientId             = $Session.ClientId
            SkipCertificateCheck = $Session.SkipCertificateCheck
        }
        New-VdcToken @refreshParams -ErrorAction Stop
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
    elseif ($Session.Platform -eq 'VC') {
        throw 'Automatic token refresh is not available for VC platform'
    }
    else {
        throw "Unknown platform $($Session.Platform) for token refresh"
    }

    $Session.AccessToken = $newToken.AccessToken
    $Session.Scope = $newToken.Scope
    $Session.Expires = $newToken.Expires
    if ($newToken.RefreshToken) { $Session.RefreshToken = $newToken.RefreshToken }
    if ($newToken.RefreshExpires -gt [datetime]::MinValue) { $Session.RefreshExpires = $newToken.RefreshExpires }
    if ($newToken.ClientId) { $Session.ClientId = $newToken.ClientId }
    if ($newToken.Server) { $Session.AuthServer = $newToken.Server }
}
