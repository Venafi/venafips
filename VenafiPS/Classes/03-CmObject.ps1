class CmObject {

    [string] $Path
    [string] $TypeName
    [guid] $Guid
    [string] $Name
    [string] $ParentPath

    # Construct from all values — no API call
    CmObject([string] $Path, [guid] $Guid, [string] $TypeName) {
        $this._init($Path, $Guid, $TypeName)
    }

    # Construct from Path — resolves Guid and TypeName via API
    CmObject([string] $Path) {
        $response = Invoke-TrustRestMethod -Method Post -UriLeaf 'config/DnToGuid' -Body @{ ObjectDN = ($Path | ConvertTo-CmFullPath) }

        switch ($response.Result) {
            1 { $this._init($Path, $response.Guid, $response.ClassName) }
            7 { throw [System.UnauthorizedAccessException]::new($response.Error) }
            400 { throw [System.Management.Automation.ItemNotFoundException]::new($response.Error) }
            default { throw $response.Error }
        }
    }

    # Construct from Guid — resolves Path and TypeName via API
    CmObject([guid] $Guid) {
        $response = Invoke-TrustRestMethod -Method Post -UriLeaf 'config/GuidToDN' -Body @{ ObjectGUID = "{$Guid}" }

        switch ($response.Result) {
            1 { $this._init($response.ObjectDN, $Guid, $response.ClassName) }
            7 { throw [System.UnauthorizedAccessException]::new($response.Error) }
            400 { throw [System.Management.Automation.ItemNotFoundException]::new($response.Error) }
            default { throw $response.Error }
        }
    }

    hidden [void] _init([string] $path, [object] $guid, [string] $typeName) {
        $this.Path = $path.Replace('\\', '\')
        $this.Guid = [guid] $guid
        $this.TypeName = $typeName
        $this.Name = $this.Path.TrimEnd('\').Split('\')[-1]
        $this.ParentPath = $this.Path.Substring(0, $this.Path.LastIndexOf("\$($this.Name)"))
    }

    [string] ToString() {
        return $this.Path
    }
}
