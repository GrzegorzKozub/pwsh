param (
  [Switch] $Backup,
  [Switch] $Restore
)

if (Get-Process -Name brave -ErrorAction SilentlyContinue) { throw "Brave is running" }

$zip = "D:\Software\Brave.zip"
$profiles = Join-Path -Path $env:LOCALAPPDATA -ChildPath "BraveSoftware\Brave-Browser"
$currentProfile = Join-Path -Path $profiles -ChildPath "User Data"
$backupProfile = Join-Path -Path $profiles -ChildPath "User Data.backup"

if ($Backup) {
  rclone sync $currentProfile $backupProfile
  Remove-Item -Path $zip -ErrorAction SilentlyContinue -Force
  7z a $zip $currentProfile $backupProfile | Out-Null
}

if ($Restore) { rclone sync $backupProfile $currentProfile }

