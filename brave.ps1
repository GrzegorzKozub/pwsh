param (
  [Switch] $Backup,
  [Switch] $Restore
)

if (Get-Process -Name brave -ErrorAction SilentlyContinue) { throw "Brave is running" }

$config = Join-Path -Path $env:LOCALAPPDATA -ChildPath "BraveSoftware"
$config = Join-Path -Path "D:" -ChildPath $config.TrimStart("C:")

foreach ($brave in "Brave-Browser", "Brave-Origin-Nightly") {
  $profile = Join-Path -Path $config -ChildPath $brave
  if (!(Test-Path -Path $profile)) { continue }
  $currentProfile = Join-Path -Path $profile -ChildPath "User Data"
  $backupProfile = Join-Path -Path $profile -ChildPath "User Data.backup"
  if ($Backup) { rclone sync $currentProfile $backupProfile }
  if ($Restore) { rclone sync $backupProfile $currentProfile }
}

if ($Backup) {
  $zip = "D:\Software\Brave.zip"
  Remove-Item -Path $zip -ErrorAction SilentlyContinue -Force
  7z a $zip $config | Out-Null
}

