$backup = (Get-Volume | Where-Object { $_.FileSystemLabel -eq "Backup" }).DriveLetter
if (!$backup) { throw "Can't find Backup drive" }
$target = Join-Path -Path "${backup}:" -ChildPath "Windows"

$dirs = "D:\Images", "D:\Reflect", "D:\Software", "D:\Win"

foreach ($dir in $dirs) {
   # change to escape sequences and use better names

    $to = Join-Path -Path $target -ChildPath (Split-Path -Path $dir -Leaf)
    Write-Host -Object "Backup " -NoNewLine -ForegroundColor DarkGray
    Write-Host -Object $dir -NoNewline -ForegroundColor DarkCyan
    Write-Host -Object " to " -NoNewLine -ForegroundColor DarkGray
    Write-Host -Object $to -ForegroundColor DarkCyan
  rclone sync --progress `
    $dir `
    $to
}
