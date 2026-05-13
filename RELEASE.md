## v7.0 — NGTS Support, TrustClient, Function Rename

### NGTS Platform Support
- Full support for Palo Alto Networks Next-Generation Trust Security (NGTS)
- `New-TrustClient -NgtsCredential` to create an NGTS session.  The TSG ID is parsed from the service account username by default; use `-Tsg` to override.
- NGTS uses OAuth2 client credentials authentication (service account format: `user@{tsgId}.iam.panserviceaccount.com`)

### Session Architecture
- `VenafiSession` PSObject replaced with strongly-typed `TrustClient` class
  - Properties: `Platform` (CM, CMS, NGTS), `AuthType` (BearerToken, ApiKey), built-in validation
  - Automatic token refresh for CM (via refresh token) and NGTS (via credentials) sessions
- `New-VenafiSession` renamed to `New-TrustClient` (`New-VenafiSession` alias preserved)
- `Invoke-VenafiRestMethod` renamed to `Invoke-TrustRestMethod` (alias preserved)
- Removed: `Test-VenafiSession`, `Get-VenafiSession`, `Test-VdcToken`, `Revoke-VdcToken`

### Function Rename
- `-Vdc` functions → `-Cm` (Certificate Manager Self-Hosted), e.g. `Get-VdcCertificate` → `Get-CmCertificate`
- `-Vc` functions specific to CMSaaS → `-Cms`, e.g. `Get-VcApplication` → `Get-CmsApplication`
- `-Vc` functions that work on both CMSaaS and NGTS → `-Trust`, e.g. `Find-VcCertificate` → `Find-TrustCertificate`
- Backward-compatible `-Vdc` and `-Vc` aliases are preserved
- `-Tpp` aliases have been dropped

### Enhanced Functions
- `Set-TrustMachine` — Update machine name, connection details, and associated satellite.  Use with `-PassThru` and pipe to `Invoke-TrustWorkflow -Workflow 'Test'`.
- `Set-TrustMachineIdentity` — Update machine identity certificate, binding, and keystore details with partial update support.  Use with `-PassThru` and pipe to `Invoke-TrustCertificateAction -Provision`.
- `Get-TrustCertificate` — Automatically searches trusted CA certificates when a cert isn't found.  Accepts an array of certificate IDs via pipeline to retrieve the full chain from `New-TrustCertificate`.
- `New-TrustCertificate`:
  - `-Application` is optional, not applicable to NGTS
  - `-IssuingTemplate` is mandatory
  - `-Wait` to poll until certificate is issued or fails
  - `-PassThru` to return the certificate object
  - DNS SANs default to the common name if not explicitly provided
  - Fix SAN hashtable initialization when providing SAN parameters
- `Invoke-TrustCertificateAction`:
  - `-Recover` action to recover retired certificates
  - `-Provision -MachineIdentity` to provision to a specific machine identity
  - `-AdditionalParameters` for custom renewal request parameters
- `Find-TrustMachineIdentity` — New `-Machine` and `-Certificate` filter parameters

### Removed Functions
- `ConvertTo-VdcGuid` — previously deprecated, use `Get-CmObject` instead
- `ConvertTo-VdcPath` — previously deprecated, use `Get-CmObject` instead
- `Search-VdcHistory` — previously deprecated, use `Get-CmCertificate -IncludePreviousVersions` and pipe to `Export-CmVaultObject`
- `Get-VdcVersion`, `Revoke-VdcToken`, `Test-VdcToken`

### Removed Parameters
- `New-TrustClient` (was `New-VenafiSession`) — Removed `KeyCredential` and `KeyIntegrated` parameter sets (key-based CM authentication, previously deprecated)
- `New-CmPolicy` (was `New-VdcPolicy`) — Removed `-Description`, use `-Attribute @{'Description'='my description'}` instead
- `Set-CmCredential` (was `Set-VdcCredential`) — Removed `-Value` hashtable parameter, use specific credential type parameters instead
