param (
  [Switch] $Backup,
  [Switch] $Restore
)

if (Get-Process brave -ErrorAction SilentlyContinue) { throw "Brave is running" }

$config = Join-Path $env:LOCALAPPDATA "BraveSoftware"
$config = Join-Path "D:" $config.TrimStart("C:")

foreach ($brave in "Brave-Browser", "Brave-Origin") {
  $profile = Join-Path $config $brave
  if (!(Test-Path $profile)) { continue }
  $currentProfile = Join-Path $profile "User Data"
  $backupProfile = Join-Path $profile "User Data.backup"
  if ($Backup) { rclone sync $currentProfile $backupProfile }
  if ($Restore) { rclone sync $backupProfile $currentProfile }
}

if ($Backup) {
  $zip = "D:\Software\Brave.zip"
  Remove-Item $zip -Force -ErrorAction SilentlyContinue
  7z a $zip $config | Out-Null
}

