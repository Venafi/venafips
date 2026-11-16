function ConvertTo-DekEncryptedString {
    <#
    .SYNOPSIS
    Encrypt a string with a VSatellite data encryption key (DEK)

    .DESCRIPTION
    Encrypt a string, eg. a private key password or credential, with the public key of a VSatellite data encryption key so only the VSatellite can decrypt it.
    The encryption scheme is determined by the key algorithm:
    - ED25519: anonymous sealed box, X25519 + XSalsa20-Poly1305, compatible with libsodium crypto_box_seal
    - VSAT_HPKE: HPKE base mode (RFC 9180) with DHKEM(P-384, HKDF-SHA384), HKDF-SHA512, and AES-256-GCM.  The company id is used as both the info and additional authenticated data.

    .PARAMETER Text
    String to encrypt

    .PARAMETER PublicKey
    Base64 encoded public key of the data encryption key

    .PARAMETER KeyAlgorithm
    Algorithm of the data encryption key, either ED25519 or VSAT_HPKE

    .PARAMETER CompanyId
    Company id the data encryption key belongs to.  Required for VSAT_HPKE.

    .OUTPUTS
    String, base64 encoded

    .EXAMPLE
    ConvertTo-DekEncryptedString -Text 'myPassw0rd!' -PublicKey $vSat.encryptionKey -KeyAlgorithm $vSat.encryptionKeyAlgorithm -CompanyId $vSat.companyId
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory)]
        [string] $Text,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $PublicKey,

        [Parameter()]
        [string] $KeyAlgorithm = 'ED25519',

        [Parameter()]
        [string] $CompanyId
    )

    Initialize-BouncyCastle

    $publicKeyBytes = [System.Convert]::FromBase64String($PublicKey)
    $plaintext = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $random = [Org.BouncyCastle.Security.SecureRandom]::new()

    # keys created before the algorithm was provided are ED25519
    if ( -not $KeyAlgorithm ) { $KeyAlgorithm = 'ED25519' }

    switch ($KeyAlgorithm) {

        'ED25519' {
            if ( $publicKeyBytes.Length -ne 32 ) {
                throw ('An ED25519 data encryption key must be 32 bytes, but the key provided is {0} bytes' -f $publicKeyBytes.Length)
            }

            # ephemeral key pair and shared secret
            $ephemeralPrivate = [byte[]]::new(32)
            $ephemeralPublic = [byte[]]::new(32)
            $sharedSecret = [byte[]]::new(32)
            [Org.BouncyCastle.Math.EC.Rfc7748.X25519]::GeneratePrivateKey($random, $ephemeralPrivate)
            [Org.BouncyCastle.Math.EC.Rfc7748.X25519]::GeneratePublicKey($ephemeralPrivate, 0, $ephemeralPublic, 0)
            if ( -not [Org.BouncyCastle.Math.EC.Rfc7748.X25519]::CalculateAgreement($ephemeralPrivate, 0, $publicKeyBytes, 0, $sharedSecret, 0) ) {
                throw 'The data encryption key is not a valid X25519 public key'
            }

            # box key = HSalsa20(shared secret, zero nonce).
            # HSalsa20 is the Salsa20 core without the final addition of the input words so,
            # with a zero nonce and counter, take the first Salsa20 block and subtract the input words.
            # The input words at 0, 5, 10, and 15 are the 'expand 32-byte k' constants and the words at 6-9 are zero.
            $salsa = [Org.BouncyCastle.Crypto.Engines.Salsa20Engine]::new()
            $salsa.Init($true, [Org.BouncyCastle.Crypto.Parameters.ParametersWithIV]::new([Org.BouncyCastle.Crypto.Parameters.KeyParameter]::new($sharedSecret), [byte[]]::new(8)))
            $block = [byte[]]::new(64)
            $salsa.ProcessBytes([byte[]]::new(64), 0, 64, $block, 0)

            $boxKey = [byte[]]::new(32)
            $sigma = 0x61707865, 0x3320646e, 0x79622d32, 0x6b206574
            $wordIndex = 0, 5, 10, 15
            for ($i = 0; $i -lt 4; $i++) {
                $word = ([int64][System.BitConverter]::ToUInt32($block, $wordIndex[$i] * 4) - $sigma[$i] + 0x100000000) % 0x100000000
                [System.Array]::Copy([System.BitConverter]::GetBytes([uint32]$word), 0, $boxKey, $i * 4, 4)
            }
            [System.Array]::Copy($block, 24, $boxKey, 16, 16)

            # nonce = blake2b-192(ephemeral public key || recipient public key)
            $nonce = [byte[]]::new(24)
            $blake = [Org.BouncyCastle.Crypto.Digests.Blake2bDigest]::new(192)
            $blake.BlockUpdate($ephemeralPublic, 0, 32)
            $blake.BlockUpdate($publicKeyBytes, 0, 32)
            $null = $blake.DoFinal($nonce, 0)

            # xsalsa20-poly1305, the first 32 bytes of the key stream are the poly1305 key
            $xsalsa = [Org.BouncyCastle.Crypto.Engines.XSalsa20Engine]::new()
            $xsalsa.Init($true, [Org.BouncyCastle.Crypto.Parameters.ParametersWithIV]::new([Org.BouncyCastle.Crypto.Parameters.KeyParameter]::new($boxKey), $nonce))
            $polyKey = [byte[]]::new(32)
            $xsalsa.ProcessBytes([byte[]]::new(32), 0, 32, $polyKey, 0)
            $ciphertext = [byte[]]::new($plaintext.Length)
            if ( $plaintext.Length -gt 0 ) {
                $xsalsa.ProcessBytes($plaintext, 0, $plaintext.Length, $ciphertext, 0)
            }

            $mac = [byte[]]::new(16)
            $poly = [Org.BouncyCastle.Crypto.Macs.Poly1305]::new()
            $poly.Init([Org.BouncyCastle.Crypto.Parameters.KeyParameter]::new($polyKey))
            $poly.BlockUpdate($ciphertext, 0, $ciphertext.Length)
            $null = $poly.DoFinal($mac, 0)

            # sealed box = ephemeral public key || mac || ciphertext
            return [System.Convert]::ToBase64String([byte[]]($ephemeralPublic + $mac + $ciphertext))
        }

        'VSAT_HPKE' {
            if ( -not $CompanyId ) {
                throw [System.ArgumentNullException]::new('CompanyId', 'A company id is required to encrypt with a VSAT_HPKE data encryption key')
            }

            # uncompressed P-384 point
            if ( $publicKeyBytes.Length -ne 97 -or $publicKeyBytes[0] -ne 4 ) {
                throw ('A VSAT_HPKE data encryption key must be a 97 byte uncompressed P-384 public key, but the key provided is {0} bytes' -f $publicKeyBytes.Length)
            }

            # info, and aad, is the canonical lowercase form of the company id
            $info = [System.Text.Encoding]::UTF8.GetBytes(([guid] $CompanyId).ToString())

            $hpkeLabel = [System.Text.Encoding]::ASCII.GetBytes('HPKE-v1')
            # kem id 0x0011 = DHKEM(P-384, HKDF-SHA384), kdf id 0x0003 = HKDF-SHA512, aead id 0x0002 = AES-256-GCM
            $kemSuiteId = [byte[]]([System.Text.Encoding]::ASCII.GetBytes('KEM') + [byte[]](0x00, 0x11))
            $hpkeSuiteId = [byte[]]([System.Text.Encoding]::ASCII.GetBytes('HPKE') + [byte[]](0x00, 0x11, 0x00, 0x03, 0x00, 0x02))

            function Get-Hmac([string] $Hash, [byte[]] $Key, [byte[]] $Data) {
                $hmac = if ( $Hash -eq 'SHA384' ) { [System.Security.Cryptography.HMACSHA384]::new($Key) } else { [System.Security.Cryptography.HMACSHA512]::new($Key) }
                try { $hmac.ComputeHash($Data) } finally { $hmac.Dispose() }
            }

            # hkdf-extract with the hpke label, an empty salt is a string of hash length zeros
            function Get-LabeledExtract([string] $Hash, [byte[]] $SuiteId, [byte[]] $Salt, [string] $Label, [byte[]] $Ikm) {
                if ( -not $Salt ) { $Salt = [byte[]]::new($(if ( $Hash -eq 'SHA384' ) { 48 } else { 64 })) }
                Get-Hmac -Hash $Hash -Key $Salt -Data ([byte[]]($hpkeLabel + $SuiteId + [System.Text.Encoding]::ASCII.GetBytes($Label) + $Ikm))
            }

            # hkdf-expand with the hpke label
            function Get-LabeledExpand([string] $Hash, [byte[]] $SuiteId, [byte[]] $Prk, [string] $Label, [byte[]] $Info, [int] $Length) {
                $labeledInfo = [byte[]]([byte[]](($Length -shr 8), ($Length -band 0xff)) + $hpkeLabel + $SuiteId + [System.Text.Encoding]::ASCII.GetBytes($Label) + $Info)
                $okm = [byte[]]@()
                $t = [byte[]]@()
                for ($counter = 1; $okm.Length -lt $Length; $counter++) {
                    $t = Get-Hmac -Hash $Hash -Key $Prk -Data ([byte[]]($t + $labeledInfo + [byte]$counter))
                    $okm = [byte[]]($okm + $t)
                }
                [byte[]]$okm[0..($Length - 1)]
            }

            # dhkem encap with an ephemeral key pair
            $x9 = [Org.BouncyCastle.Asn1.X9.ECNamedCurveTable]::GetByName('P-384')
            $domain = [Org.BouncyCastle.Crypto.Parameters.ECDomainParameters]::new($x9.Curve, $x9.G, $x9.N, $x9.H)
            try {
                $recipientKey = [Org.BouncyCastle.Crypto.Parameters.ECPublicKeyParameters]::new($x9.Curve.DecodePoint($publicKeyBytes), $domain)
            }
            catch {
                throw "The data encryption key is not a valid P-384 public key.  $_"
            }

            $generator = [Org.BouncyCastle.Crypto.Generators.ECKeyPairGenerator]::new()
            $generator.Init([Org.BouncyCastle.Crypto.Parameters.ECKeyGenerationParameters]::new($domain, $random))
            $ephemeral = $generator.GenerateKeyPair()

            $agreement = [Org.BouncyCastle.Crypto.Agreement.ECDHBasicAgreement]::new()
            $agreement.Init($ephemeral.Private)
            $dh = [Org.BouncyCastle.Utilities.BigIntegers]::AsUnsignedByteArray(48, $agreement.CalculateAgreement($recipientKey))
            $enc = $ephemeral.Public.Q.GetEncoded($false)

            $eaePrk = Get-LabeledExtract -Hash 'SHA384' -SuiteId $kemSuiteId -Label 'eae_prk' -Ikm $dh
            $sharedSecret = Get-LabeledExpand -Hash 'SHA384' -SuiteId $kemSuiteId -Prk $eaePrk -Label 'shared_secret' -Info ([byte[]]($enc + $publicKeyBytes)) -Length 48

            # key schedule, base mode with no psk
            $pskIdHash = Get-LabeledExtract -Hash 'SHA512' -SuiteId $hpkeSuiteId -Label 'psk_id_hash' -Ikm @()
            $infoHash = Get-LabeledExtract -Hash 'SHA512' -SuiteId $hpkeSuiteId -Label 'info_hash' -Ikm $info
            $keyScheduleContext = [byte[]]([byte[]](0x00) + $pskIdHash + $infoHash)
            $secret = Get-LabeledExtract -Hash 'SHA512' -SuiteId $hpkeSuiteId -Salt $sharedSecret -Label 'secret' -Ikm @()
            $key = Get-LabeledExpand -Hash 'SHA512' -SuiteId $hpkeSuiteId -Prk $secret -Label 'key' -Info $keyScheduleContext -Length 32
            $baseNonce = Get-LabeledExpand -Hash 'SHA512' -SuiteId $hpkeSuiteId -Prk $secret -Label 'base_nonce' -Info $keyScheduleContext -Length 12

            # first and only message so the nonce is the base nonce
            $gcm = [Org.BouncyCastle.Crypto.Modes.GcmBlockCipher]::new([Org.BouncyCastle.Crypto.Engines.AesEngine]::new())
            $gcm.Init($true, [Org.BouncyCastle.Crypto.Parameters.AeadParameters]::new([Org.BouncyCastle.Crypto.Parameters.KeyParameter]::new($key), 128, $baseNonce, $info))
            $ciphertext = [byte[]]::new($gcm.GetOutputSize($plaintext.Length))
            $written = $gcm.ProcessBytes($plaintext, 0, $plaintext.Length, $ciphertext, 0)
            $null = $gcm.DoFinal($ciphertext, $written)

            # enc || ciphertext and tag
            return [System.Convert]::ToBase64String([byte[]]($enc + $ciphertext))
        }

        default {
            throw ('Data encryption key algorithm {0} is not supported.  Supported algorithms are ED25519 and VSAT_HPKE.' -f $KeyAlgorithm)
        }
    }
}
