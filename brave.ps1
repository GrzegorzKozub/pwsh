param (
  [Switch] $Backup,
  [Switch] $Restore
)

if (Get-Process -Name brave -ErrorAction SilentlyContinue) { throw "Brave is running" }

$zip = "D:\Software\Brave.zip"
$profiles = Join-Path -Path $env:LOCALAPPDATA -ChildPath "BraveSoftware\Brave-Browser"
$currentProfile = Join-Path -Path $profiles -ChildPath "User Data" 
$backupProfile = Join-Path -Path $profiles -ChildPath "User Data.backup" 

function Duplicate ($from, $to) {
  Remove-Item -Path $to -ErrorAction SilentlyContinue -Force -Recurse
  Copy-Item -Path $from -Destination $to -Recurse
}

function Zip {
  Remove-Item -Path $zip -ErrorAction SilentlyContinue -Force
  7z a $zip $currentProfile $backupProfile
}

if ($Backup) { Duplicate $currentProfile $backupProfile; Zip; archive.ps1 }
if ($Restore) { Duplicate $backupProfile $currentProfile }

