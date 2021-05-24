foreach ($color in [enum]::GetValues([System.ConsoleColor])) {
  Write-Host "  " -BackgroundColor $color -NoNewline
  Write-Host $([int]$color).ToString().PadLeft(2, "0") -ForegroundColor $color -NoNewline
  Write-Host " " -NoNewline
}
Write-Host ""

