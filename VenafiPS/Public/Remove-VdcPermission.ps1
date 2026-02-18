function Remove-VdcPermission {
    <#
    .SYNOPSIS
    Remove permissions from Certificate Manager, Self-Hosted objects

    .DESCRIPTION
    Remove permissions from Certificate Manager, Self-Hosted objects
    You can opt to remove permissions for a specific user or all assigned

    .PARAMETER Path
    Full path to an object.  You can also pipe in a TppObject

    .PARAMETER Guid
    Guid that represents an object

    .PARAMETER IdentityId
    Prefixed Universal Id of the user or group to have their permissions removed

    .PARAMETER VenafiSession
    Authentication for the function.
    The value defaults to the script session object $VenafiSession created by New-VenafiSession.

    .INPUTS
    Path, Guid, IdentityId

    .OUTPUTS
    None

    .EXAMPLE
    Find-VdcObject -Path '\VED\Policy\My folder' | Remove-VdcPermission
    Remove all permissions from a specific object

    .EXAMPLE
    Find-VdcObject -Path '\VED' -Recursive | Remove-VdcPermission -IdentityId 'AD+blah:879s8d7f9a8ds7f9s8d7f9'
    Remove all permissions for a specific user

    .LINK
    https://venafi.github.io/VenafiPS/functions/Remove-VdcPermission/

    .LINK
    https://github.com/Venafi/VenafiPS/blob/main/VenafiPS/Public/Remove-VdcPermission.ps1

    .LINK
    https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-DELETE-Permissions-object-guid-principal.php

    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High', DefaultParameterSetName = 'ByGuid')]
    [Alias('Remove-TppPermission')]

    param (

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'ByPath')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if ( $_ | Test-TppDnPath ) {
                    $true
                } else {
                    throw "'$_' is not a valid DN path"
                }
            })]
        [String[]] $Path,

        [Parameter(Mandatory, ParameterSetName = 'ByGuid', ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('ObjectGuid')]
        [guid[]] $Guid,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript( {
                if ( $_ | Test-VdcIdentityFormat -Format 'Universal' ) {
                    $true
                } else {
                    throw "'$_' is not a valid Prefixed Universal Id format.  See https://docs.venafi.com/Docs/current/TopNav/Content/SDK/WebSDK/r-SDK-IdentityInformation.php."
                }
            })]
        [Alias('PrefixedUniversalId')]
        [string[]] $IdentityId,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject] $VenafiSession
    )

    begin {
        Test-VenafiSession $PSCmdlet.MyInvocation

        $params = @{
            Method     = 'Delete'
            UriLeaf    = 'placeholder'
        }
    }

    process {

        Write-Verbose ('Parameter set: {0}' -f $PSCmdLet.ParameterSetName)

        if ( $PSCmdLet.ParameterSetName -eq 'ByPath' ) {
            $inputObject = $Path
        } else {
            $inputObject = $Guid
        }

        foreach ($thisInputObject in $inputObject) {
            if ( $PSCmdLet.ParameterSetName -eq 'ByPath' ) {
                $thisGuid = $thisInputObject | ConvertTo-VdcObject | Select-Object -ExpandProperty Guid
            } else {
                $thisGuid = $thisInputObject
            }

            $uriBase = "Permissions/object/{$thisGuid}"
            $params.UriLeaf = $uriBase

            if ( $PSBoundParameters.ContainsKey('IdentityId') ) {
                $identities = $IdentityId
            } else {
                # get list of identities permissioned to this object
                $getParams = $params.Clone()
                $getParams.Method = 'Get'
                $identities = Invoke-VenafiRestMethod @getParams
            }

            foreach ( $thisIdentity in $identities ) {

                $params.UriLeaf = $uriBase

                if ( $thisIdentity.StartsWith('local:') ) {
                    # format of local is local:universalId
                    $type, $id = $thisIdentity.Split(':')
                    $params.UriLeaf += "/local/$id"
                } else {
                    # external source, eg. AD, LDAP
                    # format is type+name:universalId
                    $type, $name, $id = $thisIdentity -Split { $_ -in '+', ':' }
                    $params.UriLeaf += "/$type/$name/$id"
                }

                if ( $PSCmdlet.ShouldProcess($thisGuid, "Remove permissions for $thisIdentity") ) {
                    try {
                        Invoke-VenafiRestMethod @params
                    } catch {
                        Write-Error ("Failed to remove permissions on path $thisGuid, user/group $thisIdentity.  $_")
                    }
                }
            }
        }
    }
}


