Import-Module Admin

function Get-WindowsIsoVersion {
  [CmdletBinding()]

  param (
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateScript({ Test-Path $_ })]
    [string]
    $IsoPath
  )

  if (!(RunningAsAdmin)) {
      Write-Error "Must run as admin"
      return
  }

  Mount-DiskImage -ImagePath $IsoPath | Out-Null
  (dism.exe /Get-WimInfo /WimFile:"e:\sources\install.esd" /Index:1 | Select-String -Pattern "Version : ").ToString().Split(".")[2]
  Dismount-DiskImage -ImagePath $IsoPath | Out-Null
}

