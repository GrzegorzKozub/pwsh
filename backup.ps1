$backup = (Get-Volume | Where-Object { $_.FileSystemLabel -eq "Backup" }).DriveLetter
if (!$backup) {
  Write-Host "`e[31mCan't find backup drive`e[0m"
  exit 1
}

$source = "D:\"
$target = Join-Path -Path "${backup}:" -ChildPath "Windows"
Write-Host "Backup `e[36m$source`e[0m to `e[36m$target`e[0m"

$rcloneArgs = @(
  "sync",
  "--copy-links",
  "--exclude", '$RECYCLE.BIN/**',
  "--exclude", "Movies/**",
  "--exclude", "System Volume Information/**",
  "--exclude", "**/.local/share/wezterm/**",
  "--exclude", "**/AppData/Local/NVIDIA/**",
  "--progress"
)

if ($env:COMPUTERNAME -eq "drifter") {
  $rcloneArgs += "--exclude", "Apps/**"
  $rcloneArgs += "--exclude", "Users/**"
}

rclone @rcloneArgs $source $target
