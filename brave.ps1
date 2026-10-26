param (
  [Switch] $ClearCache,
  [Switch] $Backup,
  [Switch] $Restore
)

if (($ClearCache, $Backup, $Restore -eq $true).Count -ne 1) { throw "Can either clear cache, backup or restore" }
if (Get-Process 'brave' -ErrorAction SilentlyContinue) { throw "Brave is running" }

$userData = Join-Path "D:" $env:LOCALAPPDATA.TrimStart("C:") "BraveSoftware\Brave-Origin\User Data"
if (!(Test-Path $userData)) { New-Item $userData -ItemType Directory | Out-Null }

$env:RESTIC_REPOSITORY = "D:\Snaps"
if (!(Test-Path $env:RESTIC_REPOSITORY)) { New-Item $env:RESTIC_REPOSITORY -ItemType Directory | Out-Null }

if ($Backup -or $ClearCache) {

  Get-ChildItem $userData -Directory |
    Where-Object { $_.Name -eq "Default" -or $_.Name -match "^Profile \d+$" } |
    ForEach-Object { Join-Path $_.FullName "Cache"; Join-Path $_.FullName "Code Cache" } |
    Where-Object { Test-Path $_ } |
    Remove-Item -Recurse -Force

}

if ($Backup) {

  if (!(Get-ChildItem $env:RESTIC_REPOSITORY -Force -ErrorAction SilentlyContinue)) {
    restic init --quiet
    if ($LASTEXITCODE) { throw "restic init failed" }
  }

  restic backup --quiet --skip-if-unchanged --tag 'brave' $userData
  if ($LASTEXITCODE) { throw "restic backup failed" }

  restic forget `
    --keep-within-daily 7d --keep-within-weekly 21d --keep-within-monthly 3m `
    --prune --quiet --tag brave
  if ($LASTEXITCODE) { throw "restic forget failed" }

}

if ($Restore) {

  restic restore --delete --quiet --tag 'brave' --target $userData `
    "latest:/$($userData.Replace(':', '').Replace('\', '/'))" | Out-Null
  if ($LASTEXITCODE) { throw "restic restore failed" }

}
