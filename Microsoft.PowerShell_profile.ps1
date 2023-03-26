try { . _fd.ps1; . _lf.ps1; . _rg.ps1 } catch { }

# https://github.com/PowerShell/PowerShell/issues/18778
$PSStyle.FileInfo.Directory = "`e[34m"

# https://github.com/PowerShell/PSReadLine/issues/2866
$OutputEncoding = [Console]::OutputEncoding = [Console]::InputEncoding = [System.Text.UTF8Encoding]::new()

chcp 65001 | Out-Null # support utf-8 in iex

$env:MY_THEME="gruvbox-dark" # neovim theme
$env:TERM="xterm-256color" # fix neovim clear screen on exit

Set-Alias -Name vim -Value nvim

$Host.PrivateData.DebugForegroundColor = [ConsoleColor]::DarkGray
$Host.PrivateData.ErrorForegroundColor = [ConsoleColor]::DarkRed
$Host.PrivateData.ProgressBackgroundColor = [ConsoleColor]::Gray
$Host.PrivateData.ProgressForegroundColor = [ConsoleColor]::Black
$Host.PrivateData.VerboseForegroundColor = [ConsoleColor]::Black
$Host.PrivateData.WarningForegroundColor = [ConsoleColor]::DarkYellow

Set-PSReadlineOption -BellStyle None
Set-PSReadLineOption -EditMode Vi
Set-PSReadLineOption -PredictionSource History

Set-PSReadLineOption -ViModeIndicator Script -ViModeChangeHandler {
  Write-Host -NoNewLine "`e[$(if ($args[0] -eq 'Command') { '1' } else { '0' }) q"
}

Set-PSReadLineOption -Colors @{
  "Command" = [ConsoleColor]::DarkGreen
  "Comment" = [ConsoleColor]::DarkGray
  "ContinuationPrompt" = [ConsoleColor]::DarkBlue
  "Default" = [ConsoleColor]::White
  "Emphasis" = [ConsoleColor]::DarkYellow
  "Error" = [ConsoleColor]::DarkRed
  "InlinePrediction" = [ConsoleColor]::Black
  "Keyword" = [ConsoleColor]::DarkYellow
  "Member" = [ConsoleColor]::DarkYellow
  "Number" = [ConsoleColor]::White
  "Operator" = [ConsoleColor]::White
  "Parameter" = [ConsoleColor]::DarkBlue
  "Selection" = [ConsoleColor]::White
  "String" = [ConsoleColor]::DarkMagenta
  "Type" = [ConsoleColor]::DarkGreen
  "Variable" = [ConsoleColor]::DarkRed
}

Set-PSReadlineKeyHandler -Key ctrl+r -Function ReverseSearchHistory -ViMode Command
Set-PSReadlineKeyHandler -Key ctrl+r -Function ReverseSearchHistory -ViMode Insert

if (Get-Command lf -ErrorAction SilentlyContinue) {

  Set-PSReadLineKeyHandler -Chord "escape,l" -ViMode Command -ScriptBlock {
    $tempFile = New-TemporaryFile
    &lf -last-dir-path $tempFile.FullName
    if (Test-Path -PathType Leaf $tempFile) {
      $dir = Get-Content -Path $tempFile
      Remove-Item -Path $tempFile
      if ((Test-Path -PathType Container "$dir") -and "$dir" -ne "$pwd") {
        Set-Location -Path "$dir"
      }
    }
    [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
  }

}

if (Get-Command starship -ErrorAction SilentlyContinue) {

  $env:STARSHIP_CONFIG = "$env:USERPROFILE\Documents\PowerShell\starship.toml"
  $env:STARSHIP_CACHE = $env:TEMP

  function Invoke-Starship-TransientFunction { &starship module character }
  Invoke-Expression ( &starship init powershell )
  Enable-TransientPrompt

}

function RunningAsAdmin {
  return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

