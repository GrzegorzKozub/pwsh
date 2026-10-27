$dirs =
  'D:\Code\keys',
  'D:\Code\notes',
  'D:\Code\pass',
  "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadline",
  "$env:USERPROFILE\Pictures\Walls"

foreach ($dir in $dirs) {
  if (Test-Path $dir) {
    Push-Location $dir
    if (Test-Path 'sync.ps1') { ./sync.ps1 }
    Pop-Location
  }
}

