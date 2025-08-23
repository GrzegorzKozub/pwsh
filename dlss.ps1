param (
  [Switch] $Hide
)

$path = "HKLM:\SOFTWARE\NVIDIA Corporation\Global\NGXCore"
if (!(Test-Path -Path $path)) {New-Item -Path $path -Force | Out-Null }

New-ItemProperty `
  -Path $path `
  -Name "ShowDlssIndicator" `
  -PropertyType DWord `
  -Value 1024 -Force `
  | Out-Null
