param (
  [Parameter(Mandatory, Position = 0)]
  [ValidateSet('Brave')]
  [String] $App
)

if ($App -eq 'Brave') {
  if (Get-Process 'brave' -ErrorAction SilentlyContinue) { throw "Brave is running" }
  $userData = Join-Path "D:" $env:LOCALAPPDATA.TrimStart("C:") "BraveSoftware\Brave-Origin\User Data"
  if (!(Test-Path $userData)) { return }
  Get-ChildItem $userData -Directory |
    Where-Object { $_.Name -eq "Default" -or $_.Name -match "^Profile \d+$" } |
    ForEach-Object { Join-Path $_.FullName "Cache"; Join-Path $_.FullName "Code Cache" } |
    Where-Object { Test-Path $_ } |
    Remove-Item -Recurse -Force
}
