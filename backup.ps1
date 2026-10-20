$backup = (Get-Volume | Where-Object { $_.FileSystemLabel -eq "Backup" }).DriveLetter
if (!$backup) { throw "Can't find backup drive" }

$source = "D:\"
$target = Join-Path "${backup}:" "Backup\Windows"
Write-Host "Backup `e[36m$source`e[0m to `e[36m$target`e[0m"

$rcloneArgs = @(
  "sync",
  "--copy-links", "--create-empty-src-dirs", "--delete-excluded",
  "--filter", "- **/$env:USERNAME/.local/share/wezterm/**",
  "--filter", "- **/$env:USERNAME/.ssh/**",
  "--filter", "- **/AppData/Local/BraveSoftware/**",
  "--filter", "- **/AppData/Local/Microsoft/**",
  "--filter", "- **/AppData/Local/NVIDIA/**",
  "--filter", "- **/AppData/Roaming/TIDAL/**",
  "--filter", "+ /Apps/**",
  "--filter", "+ /Code/**",
  "--filter", "+ /Images/**",
  "--filter", "+ /Music/**",
  "--filter", "+ /Reflect/**",
  "--filter", "+ /Software/**",
  "--filter", "+ /Users/**",
  "--filter", "+ /Win/**",
  "--filter", "- *",
  "--progress"
)

rclone @rcloneArgs $source $target
