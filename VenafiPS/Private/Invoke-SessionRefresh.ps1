function Invoke-SessionRefresh {
    <#
    .SYNOPSIS
    Refresh an expired VenafiSession token.

    .DESCRIPTION
    Module-scoped function that performs the actual token refresh for a VenafiSession.
    Separated from the class method so that Pester can mock the underlying token functions.

    .PARAMETER Session
    The VenafiSession object to refresh. Updated in-place.
    #>

    param(
        [Parameter(Mandatory)]
        [VenafiSession] $Session
    )

    $newToken = if ($Session.Platform -eq 'VDC') {
        $refreshParams = @{
            AuthServer           = $Session.Auth.AuthServer
            RefreshToken         = $Session.Auth.RefreshToken
            ClientId             = $Session.Auth.ClientId
            SkipCertificateCheck = $Session.SkipCertificateCheck
        }
        New-VdcToken @refreshParams -ErrorAction Stop
    }
    elseif ($Session.Platform -eq 'NGTS') {
        $ngtsParams = @{
            Credential = $Session.Auth.Credential
        }
        if ($Session.Auth.Tsg) {
            $ngtsParams.Tsg = $Session.Auth.Tsg
        }
        New-NgtsToken @ngtsParams -ErrorAction Stop
    }
    elseif ($Session.Platform -eq 'VC') {
        throw 'Automatic token refresh is not available for VC platform'
    }
    else {
        throw "Unknown platform $($Session.Platform) for token refresh"
    }

    $Session.Auth.AccessToken = $newToken.AccessToken
    if ($newToken.PSObject.Properties.Name -contains 'RefreshToken') { $Session.Auth.RefreshToken = $newToken.RefreshToken }
    if ($newToken.PSObject.Properties.Name -contains 'Scope') { $Session.Auth.Scope = $newToken.Scope }
    if ($newToken.PSObject.Properties.Name -contains 'Expires') { $Session.Auth.Expires = $newToken.Expires }
    if ($newToken.PSObject.Properties.Name -contains 'RefreshExpires' -and $newToken.RefreshExpires) { $Session.Auth.RefreshExpires = $newToken.RefreshExpires }
    if ($newToken.PSObject.Properties.Name -contains 'ClientId' -and $newToken.ClientId) { $Session.Auth.ClientId = $newToken.ClientId }
    if ($newToken.PSObject.Properties.Name -contains 'Server' -and $newToken.Server) { $Session.Auth.AuthServer = $newToken.Server }
}
