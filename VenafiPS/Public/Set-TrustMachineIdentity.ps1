function Set-TrustMachineIdentity {
    <#
    .SYNOPSIS
    Update an existing machine identity

    .DESCRIPTION
    Update an existing machine identity, including associated certificate, binding details, and keystore details.

    .PARAMETER MachineIdentity
    Machine identity ID

    .PARAMETER Certificate
    Set the certificate associated with the machine identity.
    You can provide the certificate name or ID.
    If multiple certificates are found with the same name, an error will be thrown unless you use -Force to specify you want to use the current version of the certificate.

    .PARAMETER Binding
    Binding details to update. Provide a hashtable with the same structure as the binding object returned by Get-TrustMachineIdentity.
    You can provide a partial hashtable with only the values to change.

    .PARAMETER Keystore
    Keystore details to update. Provide a hashtable with the same structure as the keystore object returned by Get-TrustMachineIdentity.
    You can provide a partial hashtable with only the values to change.

    .PARAMETER Force
    When used with -Certificate, resolve the certificate using only the current version.

    .PARAMETER PassThru
    Return the updated machine identity object

    .PARAMETER TrustClient
    Authentication for the function.
    The value defaults to the script session object $TrustClient created by New-TrustClient.

    .INPUTS
    Machine

    .EXAMPLE
    Set-TrustMachineIdentity -MachineIdentity 3f4d8db9-6f83-4c9b-9a53-6f8e2a9d6d2b -Certificate 'web01.example.com'

    Update the certificate associated with a machine identity.

    .EXAMPLE
    Set-TrustMachineIdentity -MachineIdentity 3f4d8db9-6f83-4c9b-9a53-6f8e2a9d6d2b -Certificate 'web01.example.com' -Force

    Update the machine identity certificate and use only the current certificate version when multiple versions exist.

    .EXAMPLE
    Set-TrustMachineIdentity -MachineIdentity 3f4d8db9-6f83-4c9b-9a53-6f8e2a9d6d2b -Binding @{ 'port' = 8443 } -PassThru

    Update one binding value and return the updated machine identity object.

    .EXAMPLE
    Set-TrustMachineIdentity -MachineIdentity 3f4d8db9-6f83-4c9b-9a53-6f8e2a9d6d2b -Keystore @{ 'alias' = 'new-alias' }

    Update one keystore value while keeping other existing keystore values unchanged.

    .EXAMPLE
    Set-TrustMachineIdentity -MachineIdentity 3f4d8db9-6f83-4c9b-9a53-6f8e2a9d6d2b -Binding @{ 'port' = 8443 } -PassThru | Invoke-TrustCertificateAction -Provision

    Update one binding value and provision the certificate with the new binding details in one pipeline.

    #>

    [CmdletBinding(SupportsShouldProcess)]
    [Alias('Set-VcMachineIdentity')]

    param (

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('machineIdentityId')]
        [string] $MachineIdentity,

        [Parameter()]
        [string] $Certificate,

        [Parameter()]
        [hashtable] $Binding,

        [Parameter()]
        [hashtable] $Keystore,

        [Parameter()]
        [switch] $Force,

        [Parameter()]
        [switch] $PassThru,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [TrustClient] $TrustClient
    )

    begin {

        if ( $Certificate ) {
            $certLookup = if ( $Force ) {
                Find-TrustCertificate -Name $Certificate -VersionType CURRENT
            }
            else {
                Find-TrustCertificate -Name $Certificate
            }

            $certificateId = switch ($certLookup.Count) {
                1 {
                    $certLookup.certificateId
                }
                { $_ -gt 1 } {
                    throw [System.InvalidOperationException]::new("Multiple certificates found with name '$Certificate'. Use -Force to specify you want to use the current version of the certificate.")
                }
                0 {
                    throw [System.Management.Automation.ItemNotFoundException]::new("Certificate '$Certificate' not found.")
                }
            }
        }
    }

    process {

        $thisMI = Get-TrustData -Type MachineIdentity -InputObject $MachineIdentity -Object

        if ( -not $thisMI ) {
            Write-Error "Machine identity '$MachineIdentity' not found."
            continue
        }

        $params = @{
            Method  = 'Patch'
            UriLeaf = "machineidentities/$($thisMI.machineIdentityId)"
        }

        $body = @{}

        switch ($PSBoundParameters.Keys) {
            'Certificate' {
                if ( $certificateId ) {
                    $body.certificateId = $certificateId
                }
            }

            'Binding' {
                $currentBinding = @{}

                # get existing binding details and update with provided values as opposed to requiring the whole object be provided
                if ( $thisMI.binding ) {
                    $currentBinding = $thisMI.binding | ConvertTo-Hashtable -Recurse
                }

                foreach ( $key in $Binding.Keys ) {
                    if ( $Binding[$key] -is [hashtable] -and $currentBinding.ContainsKey($key) -and $currentBinding[$key] -is [hashtable] ) {
                        foreach ( $nestedKey in $Binding[$key].Keys ) {
                            $currentBinding[$key][$nestedKey] = $Binding[$key][$nestedKey]
                        }
                    }
                    else {
                        $currentBinding[$key] = $Binding[$key]
                    }
                }

                $body.binding = $currentBinding
            }

            'Keystore' {

                $currentKeystore = @{}

                # get existing keystore details and update with provided values as opposed to requiring the whole object be provided
                if ( $thisMI.keystore ) {
                    $currentKeystore = $thisMI.keystore | ConvertTo-Hashtable -Recurse
                }

                foreach ( $key in $Keystore.Keys ) {
                    if ( $Keystore[$key] -is [hashtable] -and $currentKeystore.ContainsKey($key) -and $currentKeystore[$key] -is [hashtable] ) {
                        foreach ( $nestedKey in $Keystore[$key].Keys ) {
                            $currentKeystore[$key][$nestedKey] = $Keystore[$key][$nestedKey]
                        }
                    }
                    else {
                        $currentKeystore[$key] = $Keystore[$key]
                    }
                }

                $body.keystore = $currentKeystore
            }

        }

        if ( $body.Count -eq 0 ) {
            Write-Error "No updates provided. Please specify at least one property to update."
            return
        }

        $params.Body = $body

        if ( $PSCmdlet.ShouldProcess($thisMI.machineIdentityId, 'Update machine identity') ) {
            $response = Invoke-TrustRestMethod @params

            if ( $PassThru -and $response ) {
                $response | Get-TrustMachineIdentity
            }
        }
    }
}