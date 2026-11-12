BeforeAll {
    . $PSScriptRoot/../VenafiPS/Private/Initialize-BouncyCastle.ps1
    . $PSScriptRoot/../VenafiPS/Private/ConvertTo-DekEncryptedString.ps1
    $script:BouncyCastlePath = "$PSScriptRoot/../VenafiPS/lib/BouncyCastle.Cryptography.dll"
    Initialize-BouncyCastle

    # test only key pairs along with ciphertexts of 'Sup3rS3cur3Passw0rd!' created by independent implementations,
    # golang.org/x/crypto/nacl/box SealAnonymous and go crypto/hpke, to validate the decryption helpers below
    $fixture = @{
        Plaintext      = 'Sup3rS3cur3Passw0rd!'
        CompanyId      = 'e2d60b61-9a8c-4a3a-985c-92498bd1fc77'
        X25519Public   = 'hLAr8Lr8Y0zZTZA8mtna4z0oZ9zVz6no9jLK7hZ5bUc='
        X25519Private  = 'UTB6I6s1NswvfIqihJp4Pq+4I8wGsFlfZ2YR/A0shm4='
        SealedBox      = '014z+tYjs5xqyYRUvVv342PjRoX3AxrO6G1ibsLEJw5krxZW5kUU5BO/PLsOIQY0FkAYNgmVE7DfF4lVy6W4R6XWS2U='
        P384Public     = 'BNtO1f4LMlCUwPVCAoQolgRs4ppjkaUHEhrIGzhk0M+AkSn00gZQtg8fKAM2c0UXX2NgTuO3oG+vu41fsix54nvIG4z6BkvQ+gfNiUMxtAP7JAuVpEiZ5tymLaXh/f2lUg=='
        P384Private    = 'KOs5Xnu6S//xTtIdVlTw3bTqEd4F1qnZnpzQ3rt1o+EbFovXTRt1BLKM3VDqcCdM'
        HpkeCiphertext = 'BCUcf6AwDuUXyvV1Nc2P9hFXsAlA1hgNanGLNLoOpme9YXrTS5GNbNS0PHctX3jHvGWzJamEQ4bvHjTsSF4FbCe7LgfxXdstvtaRjTd+naN1JTUJ/3H61KA82RAnVdnnkW2FL+6IxfNpvFVeInSY8Gg3J6F9Ii3onwCUbRttFXLNYFFKkQ=='
    }

    function Get-Slice([byte[]] $Bytes, [int] $Start, [int] $Length = ($Bytes.Length - $Start)) {
        $out = [byte[]]::new($Length)
        [System.Array]::Copy($Bytes, $Start, $out, 0, $Length)
        , $out
    }

    # hsalsa20 from the salsa20 quarter round definition
    function Get-HSalsa20([byte[]] $Key, [byte[]] $Nonce) {
        $x = [int64[]]::new(16)
        $x[0], $x[5], $x[10], $x[15] = 0x61707865, 0x3320646e, 0x79622d32, 0x6b206574
        for ($i = 0; $i -lt 4; $i++) {
            $x[1 + $i] = [System.BitConverter]::ToUInt32($Key, $i * 4)
            $x[11 + $i] = [System.BitConverter]::ToUInt32($Key, 16 + $i * 4)
            $x[6 + $i] = [System.BitConverter]::ToUInt32($Nonce, $i * 4)
        }
        # 0xFFFFFFFF is an int32 of -1 in powershell
        $mask = [int64]4294967295
        function rotl([int64] $v, [int] $n) { (($v -shl $n) -bor ($v -shr (32 - $n))) -band $mask }
        function quarter([int] $a, [int] $b, [int] $c, [int] $d) {
            $x[$b] = $x[$b] -bxor (rotl (($x[$a] + $x[$d]) -band $mask) 7)
            $x[$c] = $x[$c] -bxor (rotl (($x[$b] + $x[$a]) -band $mask) 9)
            $x[$d] = $x[$d] -bxor (rotl (($x[$c] + $x[$b]) -band $mask) 13)
            $x[$a] = $x[$a] -bxor (rotl (($x[$d] + $x[$c]) -band $mask) 18)
        }
        for ($round = 0; $round -lt 10; $round++) {
            quarter 0 4 8 12; quarter 5 9 13 1; quarter 10 14 2 6; quarter 15 3 7 11
            quarter 0 1 2 3; quarter 5 6 7 4; quarter 10 11 8 9; quarter 15 12 13 14
        }
        $out = [System.Collections.Generic.List[byte]]::new()
        foreach ($w in 0, 5, 10, 15, 6, 7, 8, 9) { $out.AddRange([System.BitConverter]::GetBytes([uint32]$x[$w])) }
        , $out.ToArray()
    }

    # libsodium crypto_box_seal_open
    function Open-SealedBox([string] $Ciphertext, [string] $PublicKey, [string] $PrivateKey) {
        $ct = [System.Convert]::FromBase64String($Ciphertext)
        $pk = [System.Convert]::FromBase64String($PublicKey)
        $sk = [System.Convert]::FromBase64String($PrivateKey)
        $epk = Get-Slice $ct 0 32
        $mac = Get-Slice $ct 32 16
        $body = Get-Slice $ct 48

        $shared = [byte[]]::new(32)
        $null = [Org.BouncyCastle.Math.EC.Rfc7748.X25519]::CalculateAgreement($sk, 0, $epk, 0, $shared, 0)
        $boxKey = Get-HSalsa20 -Key $shared -Nonce ([byte[]]::new(16))

        $nonce = [byte[]]::new(24)
        $blake = [Org.BouncyCastle.Crypto.Digests.Blake2bDigest]::new(192)
        $blake.BlockUpdate($epk, 0, 32)
        $blake.BlockUpdate($pk, 0, 32)
        $null = $blake.DoFinal($nonce, 0)

        $xsalsa = [Org.BouncyCastle.Crypto.Engines.XSalsa20Engine]::new()
        $xsalsa.Init($false, [Org.BouncyCastle.Crypto.Parameters.ParametersWithIV]::new([Org.BouncyCastle.Crypto.Parameters.KeyParameter]::new($boxKey), $nonce))
        $polyKey = [byte[]]::new(32)
        $xsalsa.ProcessBytes([byte[]]::new(32), 0, 32, $polyKey, 0)

        $expectedMac = [byte[]]::new(16)
        $poly = [Org.BouncyCastle.Crypto.Macs.Poly1305]::new()
        $poly.Init([Org.BouncyCastle.Crypto.Parameters.KeyParameter]::new($polyKey))
        $poly.BlockUpdate($body, 0, $body.Length)
        $null = $poly.DoFinal($expectedMac, 0)
        if ( [System.Convert]::ToBase64String($expectedMac) -ne [System.Convert]::ToBase64String($mac) ) { throw 'sealed box authentication failed' }

        $pt = [byte[]]::new($body.Length)
        $xsalsa.ProcessBytes($body, 0, $body.Length, $pt, 0)
        [System.Text.Encoding]::UTF8.GetString($pt)
    }

    function Get-TestHmac([string] $Hash, [byte[]] $Key, [byte[]] $Data) {
        $hmac = if ( $Hash -eq 'SHA384' ) { [System.Security.Cryptography.HMACSHA384]::new($Key) } else { [System.Security.Cryptography.HMACSHA512]::new($Key) }
        try { , $hmac.ComputeHash($Data) } finally { $hmac.Dispose() }
    }

    # rfc 9180 labeled extract and expand
    function Get-TestExtract([string] $Hash, [byte[]] $Suite, [byte[]] $Salt, [string] $Label, [byte[]] $Ikm) {
        if ( -not $Salt ) { $Salt = [byte[]]::new($(if ( $Hash -eq 'SHA384' ) { 48 } else { 64 })) }
        $data = [System.Collections.Generic.List[byte]]::new()
        $data.AddRange([System.Text.Encoding]::ASCII.GetBytes('HPKE-v1')); $data.AddRange($Suite); $data.AddRange([System.Text.Encoding]::ASCII.GetBytes($Label)); $data.AddRange($Ikm)
        Get-TestHmac $Hash $Salt $data.ToArray()
    }

    function Get-TestExpand([string] $Hash, [byte[]] $Suite, [byte[]] $Prk, [string] $Label, [byte[]] $Info, [int] $Length) {
        $labeled = [System.Collections.Generic.List[byte]]::new()
        $labeled.AddRange([byte[]](0, $Length)); $labeled.AddRange([System.Text.Encoding]::ASCII.GetBytes('HPKE-v1')); $labeled.AddRange($Suite); $labeled.AddRange([System.Text.Encoding]::ASCII.GetBytes($Label)); $labeled.AddRange($Info)
        $okm = [System.Collections.Generic.List[byte]]::new()
        $t = [byte[]]@()
        for ($i = 1; $okm.Count -lt $Length; $i++) {
            $block = [System.Collections.Generic.List[byte]]::new()
            $block.AddRange($t); $block.AddRange($labeled); $block.Add([byte]$i)
            $t = Get-TestHmac $Hash $Prk $block.ToArray()
            $okm.AddRange($t)
        }
        , $okm.GetRange(0, $Length).ToArray()
    }

    # rfc 9180 base mode open, DHKEM(P-384, HKDF-SHA384), HKDF-SHA512, AES-256-GCM, info is also the aad
    function Open-Hpke([string] $Ciphertext, [string] $PublicKey, [string] $PrivateKey, [string] $Info) {
        $ct = [System.Convert]::FromBase64String($Ciphertext)
        $pkR = [System.Convert]::FromBase64String($PublicKey)
        $enc = Get-Slice $ct 0 97
        $body = Get-Slice $ct 97
        $infoBytes = [System.Text.Encoding]::UTF8.GetBytes($Info)

        $x9 = [Org.BouncyCastle.Asn1.X9.ECNamedCurveTable]::GetByName('P-384')
        $d = [Org.BouncyCastle.Math.BigInteger]::new(1, [System.Convert]::FromBase64String($PrivateKey))
        $dh = $x9.Curve.DecodePoint($enc).Multiply($d).Normalize().AffineXCoord.GetEncoded()

        $kemSuite = [byte[]](0x4b, 0x45, 0x4d, 0x00, 0x11)
        $hpkeSuite = [byte[]](0x48, 0x50, 0x4b, 0x45, 0x00, 0x11, 0x00, 0x03, 0x00, 0x02)
        $kemContext = [byte[]]($enc + $pkR)
        $eaePrk = Get-TestExtract 'SHA384' $kemSuite $null 'eae_prk' $dh
        $sharedSecret = Get-TestExpand 'SHA384' $kemSuite $eaePrk 'shared_secret' $kemContext 48

        $context = [byte[]]([byte[]](0) + (Get-TestExtract 'SHA512' $hpkeSuite $null 'psk_id_hash' @()) + (Get-TestExtract 'SHA512' $hpkeSuite $null 'info_hash' $infoBytes))
        $secret = Get-TestExtract 'SHA512' $hpkeSuite $sharedSecret 'secret' @()
        $key = Get-TestExpand 'SHA512' $hpkeSuite $secret 'key' $context 32
        $nonce = Get-TestExpand 'SHA512' $hpkeSuite $secret 'base_nonce' $context 12

        $gcm = [Org.BouncyCastle.Crypto.Modes.GcmBlockCipher]::new([Org.BouncyCastle.Crypto.Engines.AesEngine]::new())
        $gcm.Init($false, [Org.BouncyCastle.Crypto.Parameters.AeadParameters]::new([Org.BouncyCastle.Crypto.Parameters.KeyParameter]::new($key), 128, $nonce, $infoBytes))
        $pt = [byte[]]::new($gcm.GetOutputSize($body.Length))
        $written = $gcm.ProcessBytes($body, 0, $body.Length, $pt, 0)
        $written += $gcm.DoFinal($pt, $written)
        [System.Text.Encoding]::UTF8.GetString($pt, 0, $written)
    }
}

Describe 'ConvertTo-DekEncryptedString' -Tags 'Unit' {

    Context 'Test decryption helpers' {

        It 'Should open a sealed box created by nacl/box' {
            Open-SealedBox -Ciphertext $fixture.SealedBox -PublicKey $fixture.X25519Public -PrivateKey $fixture.X25519Private | Should -BeExactly $fixture.Plaintext
        }

        It 'Should open an HPKE ciphertext created by crypto/hpke' {
            Open-Hpke -Ciphertext $fixture.HpkeCiphertext -PublicKey $fixture.P384Public -PrivateKey $fixture.P384Private -Info $fixture.CompanyId | Should -BeExactly $fixture.Plaintext
        }
    }

    Context 'ED25519' {

        It 'Should encrypt <Name> so it can be opened as a sealed box' -ForEach @(
            @{ Name = 'a password'; Text = 'Sup3rS3cur3Passw0rd!' }
            @{ Name = 'a single character'; Text = 'x' }
            @{ Name = 'a multi block string'; Text = ('p' * 200) }
            @{ Name = 'unicode'; Text = "unicod$([char]0x00e9) $([char]0x2713) $([char]0x5bc6)$([char]0x7801)" }
        ) {
            $result = ConvertTo-DekEncryptedString -Text $Text -PublicKey $fixture.X25519Public -KeyAlgorithm 'ED25519'
            [System.Convert]::FromBase64String($result).Length | Should -Be (48 + [System.Text.Encoding]::UTF8.GetByteCount($Text))
            Open-SealedBox -Ciphertext $result -PublicKey $fixture.X25519Public -PrivateKey $fixture.X25519Private | Should -BeExactly $Text
        }

        It 'Should default to ED25519 when no algorithm is provided' {
            $result = ConvertTo-DekEncryptedString -Text 'abc' -PublicKey $fixture.X25519Public -KeyAlgorithm ''
            Open-SealedBox -Ciphertext $result -PublicKey $fixture.X25519Public -PrivateKey $fixture.X25519Private | Should -BeExactly 'abc'
        }

        It 'Should use a new ephemeral key each time' {
            $first = ConvertTo-DekEncryptedString -Text 'abc' -PublicKey $fixture.X25519Public -KeyAlgorithm 'ED25519'
            $second = ConvertTo-DekEncryptedString -Text 'abc' -PublicKey $fixture.X25519Public -KeyAlgorithm 'ED25519'
            $first | Should -Not -Be $second
        }

        It 'Should throw when the key is not 32 bytes' {
            { ConvertTo-DekEncryptedString -Text 'abc' -PublicKey $fixture.P384Public -KeyAlgorithm 'ED25519' } | Should -Throw '*must be 32 bytes*97 bytes*'
        }
    }

    Context 'VSAT_HPKE' {

        It 'Should encrypt <Name> so it can be opened with HPKE' -ForEach @(
            @{ Name = 'a password'; Text = 'Sup3rS3cur3Passw0rd!' }
            @{ Name = 'a single character'; Text = 'x' }
            @{ Name = 'a multi block string'; Text = ('p' * 200) }
            @{ Name = 'unicode'; Text = "unicod$([char]0x00e9) $([char]0x2713) $([char]0x5bc6)$([char]0x7801)" }
        ) {
            $result = ConvertTo-DekEncryptedString -Text $Text -PublicKey $fixture.P384Public -KeyAlgorithm 'VSAT_HPKE' -CompanyId $fixture.CompanyId
            [System.Convert]::FromBase64String($result).Length | Should -Be (97 + [System.Text.Encoding]::UTF8.GetByteCount($Text) + 16)
            Open-Hpke -Ciphertext $result -PublicKey $fixture.P384Public -PrivateKey $fixture.P384Private -Info $fixture.CompanyId | Should -BeExactly $Text
        }

        It 'Should use the lowercase company id' {
            $result = ConvertTo-DekEncryptedString -Text 'abc' -PublicKey $fixture.P384Public -KeyAlgorithm 'VSAT_HPKE' -CompanyId $fixture.CompanyId.ToUpper()
            Open-Hpke -Ciphertext $result -PublicKey $fixture.P384Public -PrivateKey $fixture.P384Private -Info $fixture.CompanyId | Should -BeExactly 'abc'
        }

        It 'Should bind the ciphertext to the company id' {
            $result = ConvertTo-DekEncryptedString -Text 'abc' -PublicKey $fixture.P384Public -KeyAlgorithm 'VSAT_HPKE' -CompanyId $fixture.CompanyId
            { Open-Hpke -Ciphertext $result -PublicKey $fixture.P384Public -PrivateKey $fixture.P384Private -Info ([guid]::NewGuid().ToString()) } | Should -Throw
        }

        It 'Should throw when the company id is not provided' {
            { ConvertTo-DekEncryptedString -Text 'abc' -PublicKey $fixture.P384Public -KeyAlgorithm 'VSAT_HPKE' } | Should -Throw '*company id is required*'
        }

        It 'Should throw when the key is not an uncompressed P-384 point' {
            { ConvertTo-DekEncryptedString -Text 'abc' -PublicKey $fixture.X25519Public -KeyAlgorithm 'VSAT_HPKE' -CompanyId $fixture.CompanyId } | Should -Throw '*97 byte uncompressed P-384*32 bytes*'
        }

        It 'Should throw when the key is not on the curve' {
            $notOnCurve = [byte[]]::new(97)
            $notOnCurve[0] = 4
            $notOnCurve[96] = 1
            { ConvertTo-DekEncryptedString -Text 'abc' -PublicKey ([System.Convert]::ToBase64String($notOnCurve)) -KeyAlgorithm 'VSAT_HPKE' -CompanyId $fixture.CompanyId } | Should -Throw '*not a valid P-384 public key*'
        }
    }

    It 'Should throw for an unsupported algorithm' {
        { ConvertTo-DekEncryptedString -Text 'abc' -PublicKey $fixture.X25519Public -KeyAlgorithm 'RSA' } | Should -Throw '*RSA is not supported*'
    }
}

Describe 'Initialize-BouncyCastle' -Tags 'Unit' {

    It 'Should load BouncyCastle v2 or greater' {
        $assembly = [System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.GetName().Name -eq 'BouncyCastle.Cryptography' }
        $assembly | Should -Not -BeNullOrEmpty
        $assembly.GetName().Version.Major | Should -BeGreaterOrEqual 2
    }

    It 'Should not throw when already loaded' {
        { Initialize-BouncyCastle } | Should -Not -Throw
    }
}
