function Get-TrustMcpIssuerChain {
    <#
    .SYNOPSIS
    Follow a certificate's Authority Information Access urls to its root

    .DESCRIPTION
    Used by the Certificate Manager Self-Hosted MCP tools to build a chain from certificate details without retrieving the certificate,
    which needs the certificate:manage scope.
    Each issuer is downloaded from the AIA url in the certificate below it and matched by key id, or subject if there is no key id.

    .PARAMETER Issuer
    Issuer DN of the certificate

    .PARAMETER AuthorityKeyId
    Authority key identifier of the certificate, hex

    .PARAMETER AiaUrl
    AIA CA issuers urls of the certificate

    .PARAMETER Cache
    Hashtable of url to downloaded certificates, shared across calls to download each url once

    .PARAMETER MaxDepth
    Maximum number of issuers to follow

    .OUTPUTS
    Hashtable with chain, the issuers from the issuing CA up, complete, true if it ends at a self-signed root, and warnings
    #>

    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory)]
        [string] $Issuer,

        [Parameter()]
        [AllowNull()]
        [AllowEmptyString()]
        [string] $AuthorityKeyId,

        [Parameter()]
        [AllowEmptyCollection()]
        [string[]] $AiaUrl,

        [Parameter()]
        [hashtable] $Cache = @{},

        [Parameter()]
        [int] $MaxDepth = 5
    )

    $toHex = { param([byte[]] $Bytes) ([System.BitConverter]::ToString($Bytes) -replace '-').ToUpper() }

    # authority key identifier, SEQUENCE { [0] keyIdentifier, ... }
    $getAki = {
        param($X509)
        $ext = $X509.Extensions | Where-Object { $_.Oid.Value -eq '2.5.29.35' }
        if ( -not $ext ) { return $null }
        $raw = $ext.RawData
        if ( $raw.Length -gt 4 -and $raw[0] -eq 0x30 -and $raw[2] -eq 0x80 ) {
            & $toHex $raw[4..(3 + $raw[3])]
        }
    }

    # AIA ca issuers urls, each is the caIssuers oid followed by a [6] uniformResourceIdentifier
    $getAia = {
        param($X509)
        $ext = $X509.Extensions | Where-Object { $_.Oid.Value -eq '1.3.6.1.5.5.7.1.1' }
        if ( -not $ext ) { return }
        $raw = $ext.RawData
        $caIssuers = [byte[]](0x06, 0x08, 0x2B, 0x06, 0x01, 0x05, 0x05, 0x07, 0x30, 0x02, 0x86)
        for ( $i = 0; $i -le $raw.Length - $caIssuers.Length - 1; $i++ ) {
            $match = $true
            for ( $j = 0; $j -lt $caIssuers.Length; $j++ ) { if ( $raw[$i + $j] -ne $caIssuers[$j] ) { $match = $false; break } }
            if ( $match ) {
                $len = $raw[$i + $caIssuers.Length]
                $startAt = $i + $caIssuers.Length + 1
                [System.Text.Encoding]::ASCII.GetString($raw, $startAt, [Math]::Min($len, $raw.Length - $startAt))
            }
        }
    }

    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $toEntry = {
        param($X509, [string] $Source, [bool] $MatchesKeyId)
        $key = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPublicKey($X509)
        if ( -not $key ) { $key = [System.Security.Cryptography.X509Certificates.ECDsaCertificateExtensions]::GetECDsaPublicKey($X509) }
        $basicConstraints = $X509.Extensions | Where-Object { $_ -is [System.Security.Cryptography.X509Certificates.X509BasicConstraintsExtension] }
        [ordered]@{
            subject            = $X509.Subject
            issuer             = $X509.Issuer
            serialNumber       = $X509.SerialNumber
            thumbprintSha1     = $X509.Thumbprint
            thumbprintSha256   = & $toHex $sha256.ComputeHash($X509.RawData)
            validFrom          = $X509.NotBefore.ToUniversalTime()
            validTo            = $X509.NotAfter.ToUniversalTime()
            keyAlgorithm       = $X509.PublicKey.Oid.FriendlyName
            # on Linux the key is an internal OpenSSL type whose KeySize PowerShell can't read, so use the public base class
            keySize            = if ( $key ) { [System.Security.Cryptography.AsymmetricAlgorithm].GetProperty('KeySize').GetValue($key) } else { $null }
            signatureAlgorithm = $X509.SignatureAlgorithm.FriendlyName
            isCA               = [bool]($basicConstraints.CertificateAuthority)
            selfSigned         = $X509.Subject -eq $X509.Issuer
            # true if its subject key identifier is the authority key identifier of the certificate below it
            matchesKeyId       = $MatchesKeyId
            source             = $Source
        }
    }

    $chain = [System.Collections.Generic.List[object]]::new()
    $warnings = [System.Collections.Generic.List[string]]::new()

    $issuerName = $Issuer
    $aki = if ( $AuthorityKeyId ) { $AuthorityKeyId.ToUpper() } else { $null }
    $urls = @($AiaUrl | Where-Object { $_ })
    $selfSigned = $false
    $depth = 0

    # follow the AIA urls up to the root, stop if a level can't be found
    for ( ; $depth -lt $MaxDepth; $depth++ ) {
        if ( -not $urls ) {
            $warnings.Add("No AIA url to find the issuer '$issuerName'")
            break
        }

        $found = $null
        foreach ( $url in $urls ) {
            if ( -not $Cache.ContainsKey($url) ) {
                $Cache[$url] = try { @(Get-TrustMcpAiaCertificate -Uri $url) } catch { $warnings.Add("Unable to download '$url': $($_.Exception.Message)"); @() }
            }
            $candidates = @($Cache[$url])
            $byKeyId = if ( $aki ) {
                $candidates | Where-Object { ($_.Extensions | Where-Object { $_ -is [System.Security.Cryptography.X509Certificates.X509SubjectKeyIdentifierExtension] }).SubjectKeyIdentifier -eq $aki } | Select-Object -First 1
            }
            $byName = $candidates | Where-Object Subject -eq $issuerName | Select-Object -First 1
            $pick = if ( $byKeyId ) { $byKeyId } elseif ( $byName ) { $byName } else { $null }
            if ( $pick ) {
                $found = @{ cert = $pick; url = $url; keyId = [bool]$byKeyId }
                break
            }
            if ( $candidates ) { $warnings.Add("'$url' did not contain the issuer '$issuerName'") }
        }

        if ( -not $found ) { break }

        $chain.Add((& $toEntry $found.cert $found.url $found.keyId))
        $selfSigned = $found.cert.Subject -eq $found.cert.Issuer
        if ( $selfSigned ) { break }

        $issuerName = $found.cert.Issuer
        $aki = & $getAki $found.cert
        $urls = @(& $getAia $found.cert)
    }

    if ( -not $selfSigned -and $depth -ge $MaxDepth ) { $warnings.Add("Stopped after $MaxDepth issuers") }

    @{
        chain    = @($chain)
        complete = $selfSigned
        warnings = @($warnings)
    }
}
