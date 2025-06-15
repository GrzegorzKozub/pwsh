$dirs =
  "D:\Code\keys",
  "D:\Code\notes",
  "D:\Code\pass",
  "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadline",
  "$env:USERPROFILE\Pictures\Wallpapers"

foreach ($dir in $dirs) {
  if (Test-Path -Path $dir) {
    Push-Location -Path $dir
    if (Test-Path -Path "sync.ps1") { ./sync.ps1 }
    Pop-Location
  }
}

