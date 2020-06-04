Import-Module Admin
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

# Enable UTF-8 support for Interactive Elixir
chcp 65001 | Out-Null

Get-ChildItem `
  (Split-Path $PROFILE) `
  -Filter "*-*.ps1" |
ForEach-Object { . $_.FullName }

$backgroundColor = "Black"
$separatorColor = "DarkGray"

if ($Host.PrivateData -ne $null) {
  $Host.PrivateData.DebugBackgroundColor = $backgroundColor
  $Host.PrivateData.DebugForegroundColor = "DarkGray"
  $Host.PrivateData.ErrorBackgroundColor = $backgroundColor
  $Host.PrivateData.ErrorForegroundColor = "DarkRed"
  $Host.PrivateData.ProgressBackgroundColor = "DarkGray"
  $Host.PrivateData.ProgressForegroundColor = "White"
  $Host.PrivateData.VerboseBackgroundColor = $backgroundColor
  $Host.PrivateData.VerboseForegroundColor = "Gray"
  $Host.PrivateData.WarningBackgroundColor = $backgroundColor
  $Host.PrivateData.WarningForegroundColor = "DarkYellow"
}

Set-PSReadLineKeyHandler -Chord Ctrl+Shift+E -ScriptBlock {
  [Microsoft.PowerShell.PSConsoleReadLine]::Copy()
  $temp = (New-TemporaryFile).FullName
  Get-ClipboardText > $temp
  gvim $temp | Out-Null
  Get-Content -Path $temp | Set-ClipboardText
  [Microsoft.PowerShell.PSConsoleReadLine]::DeleteLine()
  [Microsoft.PowerShell.PSConsoleReadLine]::Paste()
  Remove-Item -Path $temp -ErrorAction SilentlyContinue
}

Set-PSReadlineOption -BellStyle None
Set-PSReadLineOption -Colors @{
  "Command" = "DarkYellow"
  "Comment" = "DarkGray"
  "ContinuationPrompt" = "DarkGray"
  "Default" = "Gray"
  "Emphasis" = "Yellow"
  "Error" = "DarkRed"
  "Keyword" = "DarkBlue"
  "Member" = "DarkBlue"
  "Number" = "White"
  "Operator" = "DarkCyan"
  "Parameter" = "DarkGray"
  "String" = "DarkGreen"
  "Type" = "Blue"
  "Variable" = "DarkMagenta"
}

$GitPromptSettings.AfterForegroundColor = $separatorColor
$GitPromptSettings.AfterText = ""
$GitPromptSettings.BeforeForegroundColor = $separatorColor
$GitPromptSettings.BeforeIndexForegroundColor = $separatorColor
$GitPromptSettings.BeforeIndexText = ""
$GitPromptSettings.BeforeText = " "
$GitPromptSettings.BranchAheadStatusForegroundColor = "DarkGreen"
$GitPromptSettings.BranchBehindAndAheadStatusForegroundColor = "DarkYellow"
$GitPromptSettings.BranchBehindStatusForegroundColor = "DarkRed"
$GitPromptSettings.BranchForegroundColor = "DarkBlue"
$GitPromptSettings.BranchGoneStatusForegroundColor = "Red"
$GitPromptSettings.BranchIdenticalStatusToForegroundColor = "DarkBlue"
$GitPromptSettings.DefaultForegroundColor = "Gray"
$GitPromptSettings.DelimForegroundColor = $separatorColor
$GitPromptSettings.DelimText = ""
$GitPromptSettings.EnableWindowTitle = ""
$GitPromptSettings.IndexForegroundColor = "DarkGreen"
$GitPromptSettings.LocalStagedStatusSymbol = ""
$GitPromptSettings.LocalWorkingStatusSymbol = ""

Remove-Variable backgroundColor
Remove-Variable separatorColor

$prompt = @{
  User = $env:USERNAME.ToLower()
  Host = $env:COMPUTERNAME.ToLower()
  UserColor = if (RunningAsAdmin) { "DarkRed" } else { "DarkGreen" }
}

function Prompt {

  $location = Get-Location
  $path = $location.Path

  if ($path -eq $Home) {
    $path = "~"
  } elseif ($path.Length -ge 64) {
    $path = $path.Substring($path.LastIndexOf("\") + 1, $path.Length - $path.LastIndexOf("\") - 1)
  }

  $Host.UI.RawUI.WindowTitle = "$path"

  $Host.UI.RawUI.BackgroundColor = "Black"
  $Host.UI.RawUI.ForegroundColor = "Gray"

  Write-Host $prompt.User -ForegroundColor $prompt.UserColor -NoNewLine
  Write-Host "@" -ForegroundColor "DarkGray" -NoNewLine
  Write-Host $prompt.Host -ForegroundColor "DarkYellow" -NoNewLine

  Write-Host " $path" -ForegroundColor "DarkCyan" -NoNewLine

  if ($VisualStudio) {
    Write-Host " vs" -ForegroundColor "DarkMagenta" -NoNewLine
  }

  if ($location.Provider.Name -eq "FileSystem") {
    Write-VcsStatus
  }

  Write-Host
  Write-Host ">" -ForegroundColor "DarkGray" -NoNewLine

  return " "
}

if ($Host.Version.Major -ge 6 -and $env:ConEmuPID) {
  # First Write-Host call with -ForegroundColor param permanently sets $host.UI.RawUI.ForegroundColor
  Write-Host ""
  Clear-Host
}

