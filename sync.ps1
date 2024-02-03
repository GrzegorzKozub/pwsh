function Sync ($path) {
  if (Test-Path -Path $path) {
    Push-Location -Path $path
    if (Test-Path -Path "sync.ps1") { ./sync.ps1 }
    Pop-Location
  }
}

$dirs =
  "D:\Code\keys",
  "D:\Code\notes",
  "D:\Code\passwords",
  "D:\Reflect",
  "D:\Win",
  "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadline"

foreach ($dir in $dirs) { Sync $dir }

