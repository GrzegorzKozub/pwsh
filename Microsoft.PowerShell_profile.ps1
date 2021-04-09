Import-Module ClipboardText
Import-Module posh-git
Import-Module posh-docker

Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
  param ($commandName, $wordToComplete, $cursorPosition)
  dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
    [System.Management.Automation.CompletionResult]::new($_, $_, "ParameterValue", $_)
  }
}

. _rg.ps1

chcp 65001 | Out-Null # support UTF-8 in iex

Set-PSReadlineOption -BellStyle None
Set-PSReadLineOption -PredictionSource History

Set-PSReadLineOption -Colors @{
  "Command" = "DarkGreen"
  "Comment" = "Cyan"
  "ContinuationPrompt" = "Cyan"
  "Default" = "Yellow"
  "Emphasis" = "Red"
  "Error" = "DarkRed"
  "InlinePrediction" = "White"
  "Keyword" = "DarkYellow"
  "Member" = "DarkYellow"
  "Number" = "DarkMagenta"
  "Operator" = "Cyan"
  "Parameter" = "DarkBlue"
  "Selection" = "White"
  "String" = "Magenta"
  "Type" = "DarkGreen"
  "Variable" = "Red"
}

$Host.PrivateData.DebugForegroundColor = "Cyan"
$Host.PrivateData.ErrorForegroundColor = "DarkRed"
$Host.PrivateData.ProgressBackgroundColor = "Blue"
$Host.PrivateData.ProgressForegroundColor = "White"
$Host.PrivateData.VerboseForegroundColor = "Yellow"
$Host.PrivateData.WarningForegroundColor = "DarkYellow"

$GitPromptSettings.AfterStatus = ""
$GitPromptSettings.BeforeStatus = ""
$GitPromptSettings.BranchAheadStatusSymbol.ForegroundColor = "DarkGreen"
$GitPromptSettings.BranchBehindAndAheadStatusSymbol.ForegroundColor = "DarkRed"
$GitPromptSettings.BranchBehindStatusSymbol.ForegroundColor = "Red"
$GitPromptSettings.BranchColor.ForegroundColor = "DarkBlue"
$GitPromptSettings.BranchGoneStatusSymbol.ForegroundColor = "DarkRed"
$GitPromptSettings.BranchIdenticalStatusSymbol.ForegroundColor = "DarkBlue"
$GitPromptSettings.BranchIdenticalStatusSymbol.Text = ""
$GitPromptSettings.DelimStatus.Text = ""
$GitPromptSettings.IndexColor.ForegroundColor = "DarkGreen"
$GitPromptSettings.LocalStagedStatusSymbol.Text = ""
$GitPromptSettings.LocalWorkingStatusSymbol.Text = ""
$GitPromptSettings.WorkingColor.ForegroundColor = "Red"

function RunningAsAdmin {
  return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

$promptColor = if (RunningAsAdmin) { "DarkRed" } else { "DarkBlue" }

function Prompt {
  $location = Get-Location
  $path = $location.Path
  if ($path -eq $Home) {
    $path = "~"
  } elseif ($path.Length -ge 60) {
    $path = $path.Substring($path.LastIndexOf("\") + 1, $path.Length - $path.LastIndexOf("\") - 1)
  }
  $Host.UI.RawUI.WindowTitle = "$path"
  Write-Host "$path" -ForegroundColor "DarkCyan" -NoNewLine
  if ($location.Provider.Name -eq "FileSystem") { Write-Host $(Write-VcsStatus) -NoNewLine }
  Write-Host
  Write-Host "●•" -ForegroundColor $promptColor -NoNewLine
  return " "
}

