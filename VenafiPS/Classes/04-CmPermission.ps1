class CmPermission {

    [bool] $IsAssociateAllowed
    [bool] $IsCreateAllowed
    [bool] $IsDeleteAllowed
    [bool] $IsManagePermissionsAllowed
    [bool] $IsPolicyWriteAllowed
    [bool] $IsPrivateKeyReadAllowed
    [bool] $IsPrivateKeyWriteAllowed
    [bool] $IsReadAllowed
    [bool] $IsRenameAllowed
    [bool] $IsRevokeAllowed
    [bool] $IsViewAllowed
    [bool] $IsWriteAllowed

    CmPermission () {
        $this.IsAssociateAllowed = $false
        $this.IsCreateAllowed = $false
        $this.IsDeleteAllowed = $false
        $this.IsManagePermissionsAllowed = $false
        $this.IsPolicyWriteAllowed = $false
        $this.IsPrivateKeyReadAllowed = $false
        $this.IsPrivateKeyWriteAllowed = $false
        $this.IsReadAllowed = $false
        $this.IsRenameAllowed = $false
        $this.IsRevokeAllowed = $false
        $this.IsViewAllowed = $false
        $this.IsWriteAllowed = $false
    }

    CmPermission ([pscustomobject] $InputObject) {
        $this.IsAssociateAllowed = $InputObject.IsAssociateAllowed
        $this.IsCreateAllowed = $InputObject.IsCreateAllowed
        $this.IsDeleteAllowed = $InputObject.IsDeleteAllowed
        $this.IsManagePermissionsAllowed = $InputObject.IsManagePermissionsAllowed
        $this.IsPolicyWriteAllowed = $InputObject.IsPolicyWriteAllowed
        $this.IsPrivateKeyReadAllowed = $InputObject.IsPrivateKeyReadAllowed
        $this.IsPrivateKeyWriteAllowed = $InputObject.IsPrivateKeyWriteAllowed
        $this.IsReadAllowed = $InputObject.IsReadAllowed
        $this.IsRenameAllowed = $InputObject.IsRenameAllowed
        $this.IsRevokeAllowed = $InputObject.IsRevokeAllowed
        $this.IsViewAllowed = $InputObject.IsViewAllowed
        $this.IsWriteAllowed = $InputObject.IsWriteAllowed
    }

    [HashTable] ToHashtable() {

        $hash = @{}
        $propNames = $this | Get-Member | Where-Object { $_.MemberType -eq 'Property' } | Select-Object -ExpandProperty Name

        foreach ($prop in $propNames) {
            if ($this.GetType().GetProperty($prop)) {
                $hash.Add($prop, $this.$prop)
            }
        }

        return $hash
    }
}


