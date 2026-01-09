param ([Switch] $Disable)

$driver = "C:\ProgramData\NVIDIA\NGX\models\dlss\versions\20317440\files\160_E658700.bin"
$dev = "D:\Software\DLSS\dev\nvngx_dlss.dll"

if ($Disable) {
  if (Test-Path -Path "$driver.original") {
    Move-Item -Path "$driver.original" -Destination $driver -Force
  }
} else {
  if (!(Test-Path -Path "$driver.original")) {
    Copy-Item -Path $driver -Destination "$driver.original"
    Copy-Item -Path $dev -Destination $driver
  }
}

