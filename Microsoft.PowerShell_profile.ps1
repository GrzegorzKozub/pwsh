﻿Import-Module posh-git

. _rg.ps1

chcp 65001 | Out-Null # support utf-8 in iex

$env:MY_THEME="gruvbox-dark" # vim and nvim theme

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

Set-PSReadLineOption -Colors @{
  "Command" = [ConsoleColor]::DarkGreen
  "Comment" = [ConsoleColor]::DarkGray
  "ContinuationPrompt" = [ConsoleColor]::DarkBlue
  "Default" = [ConsoleColor]::White
  "Emphasis" = [ConsoleColor]::Red
  "Error" = [ConsoleColor]::DarkRed
  "InlinePrediction" = [ConsoleColor]::Black
  "Keyword" = [ConsoleColor]::DarkYellow
  "Member" = [ConsoleColor]::DarkYellow
  "Number" = [ConsoleColor]::DarkMagenta
  "Operator" = [ConsoleColor]::White
  "Parameter" = [ConsoleColor]::DarkBlue
  "Selection" = [ConsoleColor]::White
  "String" = [ConsoleColor]::Magenta
  "Type" = [ConsoleColor]::DarkGreen
  "Variable" = [ConsoleColor]::Red
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
$GitPromptSettings.BranchBehindStatusSymbol.ForegroundColor = $([ConsoleColor]::Red)
$GitPromptSettings.BranchColor.ForegroundColor = $([ConsoleColor]::DarkBlue)
$GitPromptSettings.BranchGoneStatusSymbol.ForegroundColor = $([ConsoleColor]::DarkRed)
$GitPromptSettings.BranchIdenticalStatusSymbol.ForegroundColor = $([ConsoleColor]::DarkBlue)
$GitPromptSettings.BranchIdenticalStatusSymbol.Text = ""
$GitPromptSettings.DelimStatus.Text = ""
$GitPromptSettings.IndexColor.ForegroundColor = $([ConsoleColor]::DarkGreen)
$GitPromptSettings.LocalStagedStatusSymbol.Text = ""
$GitPromptSettings.LocalWorkingStatusSymbol.Text = ""
$GitPromptSettings.WorkingColor.ForegroundColor = $([ConsoleColor]::Red)

function RunningAsAdmin {
  return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

$promptColor = if (RunningAsAdmin) { [ConsoleColor]::DarkRed } else { [ConsoleColor]::DarkBlue }

function prompt {
  $exitCode = $LASTEXITCODE
  $path = $(Get-Location).Path
  if ($path -eq $Home) {
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

