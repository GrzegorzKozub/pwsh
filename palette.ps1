$colors = @(
  [System.ConsoleColor]::Black,
  [System.ConsoleColor]::DarkRed,
  [System.ConsoleColor]::DarkGreen,
  [System.ConsoleColor]::DarkYellow,
  [System.ConsoleColor]::DarkBlue,
  [System.ConsoleColor]::DarkMagenta,
  [System.ConsoleColor]::DarkCyan,
  [System.ConsoleColor]::Gray,
 
  [System.ConsoleColor]::DarkGray,
  [System.ConsoleColor]::Red,
  [System.ConsoleColor]::Green,
  [System.ConsoleColor]::Yellow,
  [System.ConsoleColor]::Blue,
  [System.ConsoleColor]::Magenta,
  [System.ConsoleColor]::Cyan,
  [System.ConsoleColor]::White
)

for ($i = 0; $i -lt $colors.Length; $i++) {
  Write-Host ■ -ForegroundColor $colors[$i] -NoNewline
  Write-Host " " -NoNewline
  Write-Host $i.ToString().PadLeft(2, "0") -ForegroundColor $colors[$i] -NoNewline
  Write-Host " " -NoNewline
  Write-Host $colors[$i] -ForegroundColor $colors[$i]
}

