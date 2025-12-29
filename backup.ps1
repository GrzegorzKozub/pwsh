$backup = (Get-Volume | Where-Object { $_.FileSystemLabel -eq "Backup" }).DriveLetter
if (!$backup) {
  Write-Host "`e[31mCan't find backup drive`e[0m"
  exit 1
}

$target = Join-Path -Path "${backup}:" -ChildPath "Windows"
$dirs = "D:\Images", "D:\Music", "D:\Reflect", "D:\Software", "D:\Win"

if ($env:COMPUTERNAME -eq "player" -or $env:COMPUTERNAME -eq "worker") {
  $dirs = $dirs + "D:\Apps" + "D:\Code" + "D:\Users"
}

if ($env:COMPUTERNAME -eq "player") {
  $dirs = $dirs + "D:\Backup"
}

foreach ($dir in $dirs) {
  $copy = Join-Path -Path $target -ChildPath (Split-Path -Path $dir -Leaf)
  Write-Host "Backup `e[36m$dir`e[0m to `e[36m$copy`e[0m"
  rclone sync `
    --copy-links `
    --exclude '**/.local/share/wezterm/**' `
    --exclude '**/AppData/Local/NVIDIA/**' `
    --progress `
    $dir $copy
}
