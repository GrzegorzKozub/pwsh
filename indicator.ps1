param ([Switch] $Hide)

$path = "HKLM:\SOFTWARE\NVIDIA Corporation\Global\NGXCore"
$name = "ShowDlssIndicator"

if ($Hide) {
  Remove-ItemProperty -Path $path -Name $name -ErrorAction SilentlyContinue
} else {
  if (!(Test-Path -Path $path)) { New-Item -Path $path | Out-Null }
  New-ItemProperty -Path $path -Name $name `
    -PropertyType DWord -Value 1024 `
    -Force | Out-Null
}

