param (
  [Switch] $ShowOverlay,
  [Switch] $HideOverlay,
  [Switch] $Dev,
  [Switch] $Prod
)

$path = "HKLM:\SOFTWARE\NVIDIA Corporation\Global\NGXCore"
$name = "ShowDlssIndicator"

if ($ShowOverlay) {
  sudo {
    if (!(Test-Path -Path $args[0])) { New-Item -Path $args[0] | Out-Null }
    New-ItemProperty -Path $args[0] -Name $args[1] `
      -PropertyType DWord -Value 1024 `
      -Force | Out-Null
  } -args @($path, $name)
}

if ($HideOverlay) {
  sudo {
    Remove-ItemProperty -Path $args[0] -Name $args[1] -ErrorAction SilentlyContinue
  } -args @($path, $name)
}

$driver = "C:\ProgramData\NVIDIA\NGX\models\dlss\versions\20317440\files\160_E658700.bin"
$dlss = "D:\Software\DLSS\dev\nvngx_dlss.dll"

if ($Dev) {
  New-Item -Path $(Split-Path -Path $driver -Parent) -ItemType Directory -Force | Out-Null
  Copy-Item -Path $dlss -Destination $driver
}

if ($Prod) {
  Remove-Item -Path $driver -ErrorAction SilentlyContinue
  Write-Host "`e[33mEffective on the following game start`e[0m"
}

