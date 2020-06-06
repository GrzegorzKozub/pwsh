Import-Module Admin

function Get-WindowsIsoVersion {
  param (
    [ValidateScript({ Test-Path $_ })] [string] $IsoPath
  )

  AssertRunningAsAdmin

  Mount-DiskImage -ImagePath $IsoPath | Out-Null
  (dism.exe /Get-WimInfo /WimFile:"e:\sources\install.esd" /Index:1 | Select-String -Pattern "Version : ").ToString().Split(".")[2]
  Dismount-DiskImage -ImagePath $IsoPath | Out-Null
}

