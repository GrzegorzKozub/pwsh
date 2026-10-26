$backup = (Get-Volume | Where-Object { $_.FileSystemLabel -eq "Backup" }).DriveLetter
if (!$backup) { throw "Can't find backup drive" }

$source = "D:\"
$target = Join-Path "${backup}:" "Backup\Windows"
Write-Host "`e[37mBackup `e[36m$source`e[37m to `e[36m$target`e[0m"

$rcloneArgs = @(
  "sync",
  "--copy-links", "--create-empty-src-dirs", "--delete-excluded",
  "--filter", "+ /Backup/**",
  "--filter", "+ /Music/**",
  "--filter", "+ /Reflect/**",
  "--filter", "+ /Snaps/**",
  "--filter", "+ /Software/**",
  "--filter", "+ /Win/**",
  "--filter", "- *",
  "--progress"
)

rclone @rcloneArgs $source $target
