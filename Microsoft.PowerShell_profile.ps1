Import-Module -Name "posh-git"
Import-Module -Name "PSFzf"

# https://github.com/PowerShell/PowerShell/issues/18778
$PSStyle.FileInfo.Directory = "`e[34m"

# https://github.com/PowerShell/PSReadLine/issues/2866
$OutputEncoding = [Console]::OutputEncoding = [Console]::InputEncoding = [System.Text.UTF8Encoding]::new()

$env:MY_THEME="gruvbox-dark" # set neovim theme
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

# Set-PSReadlineKeyHandler -Key "ctrl+r" -Function ReverseSearchHistory -ViMode Command
# Set-PSReadlineKeyHandler -Key "ctrl+r" -Function ReverseSearchHistory -ViMode Insert

Set-PsFzfOption -PSReadlineChordReverseHistory "ctrl+r" -PSReadlineChordSetLocation "ctrl+p"

if (Get-Command starship -ErrorAction SilentlyContinue) {

  $env:STARSHIP_CONFIG = "$env:USERPROFILE\Documents\PowerShell\starship.toml"
  $env:STARSHIP_CACHE = $env:TEMP

  function Invoke-Starship-PreCommand {
    $path = $(Get-Location).Path.Replace($env:USERPROFILE, "~")
    if ($path.Split("\").GetUpperBound(0) -ge 3) {
      $lastBackslash = $path.LastIndexOf("\")
      $path = $path.Substring($lastSlash + 1, $path.Length - $lastSlash - 1)
    }
    $Host.UI.RawUI.WindowTitle = $path
  }

  function Invoke-Starship-TransientFunction { &starship module character }

  # Invoke-Expression (&starship init powershell) # https://github.com/starship/starship/issues/2637
  &starship init powershell --print-full-init | Out-String | Invoke-Expression

  Enable-TransientPrompt

} else {

  # update based on https://github.com/starship/starship/blob/ee94c6ceac7b2ce6559af7074df9938f9bf96a58/src/init/starship.ps1

  $GitPromptSettings.AfterStatus = ""
  $GitPromptSettings.BeforeStatus = ""
  $GitPromptSettings.BranchAheadStatusSymbol.ForegroundColor = $([ConsoleColor]::DarkGreen)
  $GitPromptSettings.BranchBehindAndAheadStatusSymbol.ForegroundColor = $([ConsoleColor]::DarkRed)
  $GitPromptSettings.BranchBehindStatusSymbol.ForegroundColor = $([ConsoleColor]::DarkRed)
  $GitPromptSettings.BranchColor.ForegroundColor = $([ConsoleColor]::DarkBlue)
  $GitPromptSettings.BranchGoneStatusSymbol.ForegroundColor = $([ConsoleColor]::DarkRed)
  $GitPromptSettings.BranchIdenticalStatusSymbol.ForegroundColor = $([ConsoleColor]::DarkBlue)
  $GitPromptSettings.BranchIdenticalStatusSymbol.Text = ""
  $GitPromptSettings.BranchNameLimit = 32
  $GitPromptSettings.DelimStatus.Text = ""
  $GitPromptSettings.ErrorColor.ForegroundColor = $([ConsoleColor]::DarkRed)
  $GitPromptSettings.FileConflictedText = "?"
  $GitPromptSettings.IndexColor.ForegroundColor = $([ConsoleColor]::DarkGreen)
  $GitPromptSettings.LocalStagedStatusSymbol.Text = ""
  $GitPromptSettings.LocalWorkingStatusSymbol.Text = ""
  $GitPromptSettings.ShowStatusWhenZero = $False
  $GitPromptSettings.TruncatedBranchSuffix = "…"
  $GitPromptSettings.WorkingColor.ForegroundColor = $([ConsoleColor]::DarkYellow)


 function prompt  {
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
    $prompt += Write-Prompt "●•" -ForegroundColor $([ConsoleColor]::DarkBlue)
    $prompt += Write-Prompt " "
    $LASTEXITCODE = $exitCode
    $prompt
  }

}

