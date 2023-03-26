Import-Module posh-git

. _lf.ps1
. _rg.ps1

# https://github.com/PowerShell/PSReadLine/issues/2866
$OutputEncoding = [Console]::OutputEncoding = [Console]::InputEncoding = [System.Text.UTF8Encoding]::new()

chcp 65001 | Out-Null # support utf-8 in iex

$env:MY_THEME="gruvbox-dark" # set vim and nvim theme
$env:TERM="xterm-256color" # fix nvim clear screen on exit

Set-Alias -Name vim -Value nvim

Set-PSReadlineOption -BellStyle None
Set-PSReadLineOption -EditMode Vi
Set-PSReadLineOption -PredictionSource History

Set-PSReadLineOption -ViModeIndicator Script -ViModeChangeHandler {
  if ($args[0] -eq "Command") {
    Write-Host -NoNewLine "`e[1 q"
  } else {
    Write-Host -NoNewLine "`e[0 q"
  }
}

Set-PSReadlineKeyHandler -Key ctrl+r -Function ReverseSearchHistory -ViMode Command
Set-PSReadlineKeyHandler -Key ctrl+r -Function ReverseSearchHistory -ViMode Insert

Set-PSReadLineKeyHandler -Chord "escape,l" -ViMode Command -ScriptBlock {
  $tempFile = New-TemporaryFile
  Start-Process -FilePath "lf" -ArgumentList "-last-dir-path", $tempFile.FullName -Wait
  if (Test-Path -PathType Leaf $tempFile) {
    $dir = Get-Content -Path $tempFile
    Remove-Item -Path $tempFile
    if ((Test-Path -PathType Container "$dir") -and "$dir" -ne "$pwd") {
      Set-Location -Path "$dir"
    }
  }
  [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
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

$Host.PrivateData.DebugForegroundColor = [ConsoleColor]::DarkGray
$Host.PrivateData.ErrorForegroundColor = [ConsoleColor]::DarkRed
$Host.PrivateData.ProgressBackgroundColor = [ConsoleColor]::Gray
$Host.PrivateData.ProgressForegroundColor = [ConsoleColor]::Black
$Host.PrivateData.VerboseForegroundColor = [ConsoleColor]::Black
$Host.PrivateData.WarningForegroundColor = [ConsoleColor]::DarkYellow

$GitPromptSettings.AfterStatus = ""
$GitPromptSettings.BeforeStatus = ""
$GitPromptSettings.BranchAheadStatusSymbol.ForegroundColor = $([ConsoleColor]::DarkGreen)
$GitPromptSettings.BranchBehindAndAheadStatusSymbol.ForegroundColor = $([ConsoleColor]::DarkRed)
$GitPromptSettings.BranchBehindStatusSymbol.ForegroundColor = $([ConsoleColor]::DarkRed)
$GitPromptSettings.BranchColor.ForegroundColor = $([ConsoleColor]::DarkBlue)
$GitPromptSettings.BranchGoneStatusSymbol.ForegroundColor = $([ConsoleColor]::DarkRed)
$GitPromptSettings.BranchIdenticalStatusSymbol.ForegroundColor = $([ConsoleColor]::DarkBlue)
$GitPromptSettings.BranchIdenticalStatusSymbol.Text = ""
$GitPromptSettings.DelimStatus.Text = ""
$GitPromptSettings.IndexColor.ForegroundColor = $([ConsoleColor]::DarkGreen)
$GitPromptSettings.LocalStagedStatusSymbol.Text = ""
$GitPromptSettings.LocalWorkingStatusSymbol.Text = ""
$GitPromptSettings.WorkingColor.ForegroundColor = $([ConsoleColor]::DarkRed)

function RunningAsAdmin {
  return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

$promptColor = if (RunningAsAdmin) { [ConsoleColor]::DarkRed } else { [ConsoleColor]::DarkBlue }

function prompt1 {
  $exitCode = $LASTEXITCODE
  $path = $(Get-Location).Path
  if ($path -eq $HOME) {
    $path = "~"
  } elseif ($path.Length -ge 64) {
    $path = $path.Substring($path.LastIndexOf("\") + 1, $path.Length - $path.LastIndexOf("\") - 1)
  }
  $Host.UI.RawUI.WindowTitle = "$path"
  $prompt = Write-Prompt $path -ForegroundColor $([ConsoleColor]::DarkCyan)
  $prompt += Write-VcsStatus
  $prompt += Write-Prompt $([System.Environment]::NewLine)
  $prompt += Write-Prompt "●•" -ForegroundColor $promptColor
  $prompt += Write-Prompt " "
  $LASTEXITCODE = $exitCode
  $prompt
}

# https://github.com/PowerShell/PowerShell/issues/18778
$PSStyle.FileInfo.Directory = "`e[34m"


function Invoke-Starship-TransientFunction {
  &starship module character
}

$env:STARSHIP_CONFIG = "$HOME\Documents\PowerShell\starship.toml"
$env:STARSHIP_CACHE = "$HOME\AppData\Local\Temp"
Invoke-Expression (&starship init powershell)
Enable-TransientPrompt

