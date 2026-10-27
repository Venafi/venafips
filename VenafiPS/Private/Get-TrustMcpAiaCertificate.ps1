function Get-TrustMcpAiaCertificate {
    <#
    .SYNOPSIS
    Download the issuer certificates from an Authority Information Access (AIA) CA issuers url

    .DESCRIPTION
    Used by the get_certificate_chain MCP tool to build a chain without retrieving the certificate from Certificate Manager,
    which needs the certificate:manage scope.
    Supports DER, PEM, and PKCS #7, eg. .crt, .cer, and .p7c, over http and https.

    .PARAMETER Uri
    AIA CA issuers url from a certificate

    .OUTPUTS
    X509Certificate2
    #>

    [CmdletBinding()]
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2])]
    param (
        [Parameter(Mandatory)]
        [string] $Uri
    )

    $parsed = $null
    if ( -not [uri]::TryCreate($Uri, [UriKind]::Absolute, [ref]$parsed) -or $parsed.Scheme -notin 'http', 'https' ) {
        throw "Unsupported AIA url '$Uri', only http and https are supported"
    }

    if ( $PSVersionTable.PSVersion.Major -lt 6 ) {
        Add-Type -AssemblyName System.Net.Http
    }

    $http = [System.Net.Http.HttpClient]::new()
    try {
        $http.Timeout = [timespan]::FromSeconds(10)
        # issuer certificates are a few KB, don't download anything large
        $http.MaxResponseContentBufferSize = 1MB
        $bytes = $http.GetByteArrayAsync($parsed).GetAwaiter().GetResult()
    }
    finally {
        $http.Dispose()
    }

    $text = [System.Text.Encoding]::ASCII.GetString($bytes)
    if ( $text -match '-----BEGIN CERTIFICATE-----' ) {
        foreach ( $m in [regex]::Matches($text, '-----BEGIN CERTIFICATE-----(.+?)-----END CERTIFICATE-----', 'Singleline') ) {
            [System.Security.Cryptography.X509Certificates.X509Certificate2]::new([Convert]::FromBase64String(($m.Groups[1].Value -replace '\s')))
        }
        return
    }

    # der or pkcs #7
    $collection = [System.Security.Cryptography.X509Certificates.X509Certificate2Collection]::new()
    $collection.Import($bytes)
    foreach ( $cert in $collection ) { $cert }
}
