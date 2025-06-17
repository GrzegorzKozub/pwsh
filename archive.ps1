$backup = (Get-Volume | Where-Object { $_.FileSystemLabel -eq "Backup" }).DriveLetter
if (!$backup) { throw "Can't find Backup drive" }
$target = Join-Path -Path "${backup}:" -ChildPath "Windows"

$dirs = "D:\Images", "D:\Reflect", "D:\Software", "D:\Win"

foreach ($dir in $dirs) {
  $copy = Join-Path -Path $target -ChildPath (Split-Path -Path $dir -Leaf)
  Write-Host "Backup `e[36m$dir`e[0m to `e[36m$copy`e[0m"
  rclone sync --progress $dir $copy
}
