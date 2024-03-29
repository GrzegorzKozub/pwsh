﻿# modules

Import-Module -Name "posh-git"
Import-Module -Name "PSFzf"

# profile options

$script:useStarship = $false
$script:useTransientPrompt = $true
$script:showCmdDurationAndErrCode = $true # does not affect starship

# stop on errors

$ErrorActionPreference = "Stop"

# psreadline

Set-PSReadlineOption -BellStyle None
Set-PSReadLineOption -MaximumHistoryCount 10000
Set-PSReadLineOption -PredictionSource History

[Console]::OutputEncoding = [Console]::InputEncoding = [Text.Encoding]::UTF8 # https://github.com/PowerShell/PSReadLine/issues/2866

# aliases

Set-Alias -Name la -Value ls

# vi mode

# https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences

if ($env:WT_SESSION) { Write-Host -NoNewLine "`e[6 q" }

Set-PSReadLineOption -EditMode Vi -ViModeIndicator Script -ViModeChangeHandler {
  Write-Host -NoNewLine "`e[$(if ($args[0] -eq 'Command') { '2' } else { '6' }) q"
}

Set-PSReadLineKeyHandler -ViMode Command -Chord "v,v" -Function ViEditVisually # was v by default

# fzf

$env:FZF_DEFAULT_OPTS="
  --color dark,bg+:-1,fg:8,fg+:-1,hl:3,hl+:3
  --color spinner:-1,info:-1,prompt:5,pointer:7,marker:7
  --ellipsis '…'
  --height 50%
  --layout reverse-list
  --margin 0,0,0,0
  --marker '• '
  --no-bold
  --no-info
  --no-scrollbar
  --pointer '●'
  --prompt '●• '
  --tabstop 2
"

Set-PsFzfOption `
  -PSReadlineChordReverseHistory "ctrl+r" `
  -PSReadlineChordProvider "ctrl+t" `
  -PSReadlineChordSetLocation "alt+c"

# less

$env:LESS = "--quit-if-one-screen --RAW-CONTROL-CHARS --squeeze-blank-lines --use-color -DPw" # -DSkY -Ddy -Dsm -Dub
$env:LESSHISTFILE = "-"
$env:PAGER = "less --quit-if-one-screen --RAW-CONTROL-CHARS --squeeze-blank-lines --use-color -DPw" # -DSkY -Ddy -Dsm -Dub

# lf

Set-PSReadLineKeyHandler -Chord "escape,l" -ViMode Command -ScriptBlock {
  l.ps1
  [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
  Write-Host -NoNewLine "`e[2 q"
}

# neovim

$env:EDITOR = $env:VISUAL = "nvim"
# $env:TERM = "xterm-256color" # clear screen when neovim exits

Set-Alias -Name vim -Value nvim

# dir shortcuts

$null = New-Module Go {
  function Go ($where) {
    Set-Location -Path $where
    [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
  }
  
  foreach ($mode in "Command", "Insert") {
    Set-PSReadLineKeyHandler -Chord "ctrl+g,d" -ViMode $mode -ScriptBlock { Go "~\Documents" }
    Set-PSReadLineKeyHandler -Chord "ctrl+g,l" -ViMode $mode -ScriptBlock { Go "~\Downloads" }

    Set-PSReadLineKeyHandler -Chord "ctrl+g,a" -ViMode $mode -ScriptBlock { Go "D:\Apps" }
    Set-PSReadLineKeyHandler -Chord "ctrl+g,u" -ViMode $mode -ScriptBlock { Go "D:\Users" }
    Set-PSReadLineKeyHandler -Chord "ctrl+g,w" -ViMode $mode -ScriptBlock { Go "D:\Win" }

    Set-PSReadLineKeyHandler -Chord "ctrl+g,c" -ViMode $mode -ScriptBlock { Go "D:\Code" }

    Set-PSReadLineKeyHandler -Chord "ctrl+g,g" -ViMode $mode -ScriptBlock { Go "E:\Games" }
  }

  Export-ModuleMember
}

# syntax highlighting

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

# style

$PSStyle.Formatting.Debug = $PSStyle.Foreground.White
$PSStyle.Formatting.Error = $PSStyle.Foreground.Red
$PSStyle.Formatting.ErrorAccent = "`e[31;1m" # bold red
$PSStyle.Formatting.Verbose = $PSStyle.Foreground.BrightBlack
$PSStyle.Formatting.Warning = $PSStyle.Foreground.Yellow

$PSStyle.Formatting.CustomTableHeaderLabel = $PSStyle.Foreground.White
$PSStyle.Formatting.FormatAccent = $PSStyle.Foreground.White
$PSStyle.Formatting.TableHeader = $PSStyle.Foreground.White

$PSStyle.Formatting.FeedbackName = $PSStyle.Foreground.BrightBlack
$PSStyle.Formatting.FeedbackText = $PSStyle.Foreground.White

$PSStyle.Progress.Style = $PSStyle.Foreground.White
$PSStyle.Progress.UseOSCIndicator = $true

$PSStyle.FileInfo.Directory = $PSStyle.Foreground.Blue # https://github.com/PowerShell/PowerShell/issues/18778
$PSStyle.FileInfo.Executable = $PSStyle.Foreground.Green
$PSStyle.FileInfo.SymbolicLink = $PSStyle.Foreground.Cyan

$PSStyle.FileInfo.Extension.Clear()

".7z", ".gz", ".rar", ".tar", ".zip" |
  ForEach-Object { $PSStyle.FileInfo.Extension.Add($_, $PSStyle.Foreground.Yellow) }
".cow", ".fsa", ".iso", ".wim" |
  ForEach-Object { $PSStyle.FileInfo.Extension.Add($_, $PSStyle.Foreground.Magenta) }
".dockerignore", ".editorconfig", ".gitattributes", ".gitignore", ".gitmodules" |
  ForEach-Object { $PSStyle.FileInfo.Extension.Add($_, $PSStyle.Foreground.White) }
".backup", ".bak", ".log", ".old", ".orig", ".original", ".part", ".swp", ".tmp" |
  ForEach-Object { $PSStyle.FileInfo.Extension.Add($_, $PSStyle.Foreground.BrightBlack) }

# prompt

function Osc7 {
  if ($env:WT_SESSION) {
    # https://learn.microsoft.com/en-us/windows/terminal/tutorials/new-tab-same-directory
    return "$([char]27)]9;9;`"$($location.ProviderPath)`"$([char]27)\"
  } elseif ($env:TERM_PROGRAM -eq "WezTerm") {
    # https://wezfurlong.org/wezterm/shell-integration.html?h=shell
    return "$([char]27)]7;file://${env:COMPUTERNAME}/$($location.ProviderPath -Replace "\\", "/")$([char]27)\"
  } else {
    return ""
  }
}

if ($script:useStarship -and (Get-Command starship -ErrorAction SilentlyContinue)) {

  $env:STARSHIP_CONFIG = "$HOME\Documents\PowerShell\starship.toml"
  $env:STARSHIP_CACHE = $env:TEMP

  function Invoke-Starship-PreCommand {
    $location = $executionContext.SessionState.Path.CurrentLocation
    if ($location.Provider.Name -eq "FileSystem") {
      $Host.UI.Write($(Osc7))
    }
    $path = $location.ProviderPath.Replace($HOME, "~")
    if ($path -ne "~" -and !$path.EndsWith("\")) {
      $lastSlash = $path.LastIndexOf("\")
      $path = $path.Substring($lastSlash + 1, $path.Length - $lastSlash - 1)
    }
    $Host.UI.RawUI.WindowTitle = $path
  }

  function Invoke-Starship-TransientFunction { &starship module character }

  # Invoke-Expression (&starship init powershell) # https://github.com/starship/starship/issues/2637
  &starship init powershell --print-full-init | Out-String | Invoke-Expression

  if ($script:useTransientPrompt) { Enable-TransientPrompt }

} else {

  Set-PSReadLineOption -ContinuationPrompt " • "

  $GitPromptSettings.AfterStatus = ""
  $GitPromptSettings.BeforeStatus = ""
  $GitPromptSettings.BranchAheadStatusSymbol.ForegroundColor = [ConsoleColor]::DarkGreen
  $GitPromptSettings.BranchBehindAndAheadStatusSymbol.ForegroundColor = [ConsoleColor]::DarkRed
  $GitPromptSettings.BranchBehindStatusSymbol.ForegroundColor = [ConsoleColor]::DarkRed
  $GitPromptSettings.BranchColor.ForegroundColor = [ConsoleColor]::DarkBlue
  $GitPromptSettings.BranchGoneStatusSymbol.ForegroundColor = [ConsoleColor]::DarkRed
  $GitPromptSettings.BranchIdenticalStatusSymbol.ForegroundColor = [ConsoleColor]::DarkBlue
  $GitPromptSettings.BranchIdenticalStatusSymbol.Text = ""
  $GitPromptSettings.BranchNameLimit = 32
  $GitPromptSettings.DelimStatus.Text = ""
  $GitPromptSettings.ErrorColor.ForegroundColor = [ConsoleColor]::DarkRed
  $GitPromptSettings.FileConflictedText = "?"
  $GitPromptSettings.IndexColor.ForegroundColor = [ConsoleColor]::DarkGreen
  $GitPromptSettings.LocalStagedStatusSymbol.Text = ""
  $GitPromptSettings.LocalWorkingStatusSymbol.Text = ""
  $GitPromptSettings.ShowStatusWhenZero = $false
  $GitPromptSettings.TruncatedBranchSuffix = "…"
  $GitPromptSettings.WorkingColor.ForegroundColor = [ConsoleColor]::DarkYellow

  if ([Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains "S-1-5-32-544") {
    $script:admin = "$([char]0x1B)[33m⛊$([char]0x1B)[0m "
  }

  if ($script:useTransientPrompt) {
    Set-PSReadLineKeyHandler -Key "enter" -ScriptBlock {
      try {
        $errors = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$null, [ref]$null, [ref]$errors, [ref]$null)
        if ($errors.Count -eq 0) {
          $script:transientPrompt = $true
          [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
        }
      } finally {
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
      }
    }
  }

  function prompt {
    $question = $global:?
    $exitCode = $global:LASTEXITCODE
    $char = "$([char]0x1B)[34m●•$([char]0x1B)[0m "
    if ($script:transientPrompt) {
      $script:transientPrompt = $false
      $char
    } else {
      $location = $executionContext.SessionState.Path.CurrentLocation
      $path = $location.ProviderPath.Replace($HOME, "~")
      if ($path -ne "~" -and !$path.EndsWith("\")) {
        $lastSlash = $path.LastIndexOf("\")
        $path = $path.Substring($lastSlash + 1, $path.Length - $lastSlash - 1)
      }
      $Host.UI.RawUI.WindowTitle = $path
      $path = "$([char]0x1B)[36m$path$([char]0x1B)[0m"
      $prompt = "$script:admin$path$(Write-VcsStatus)"
      if ($cmd = Get-History -Count 1) {
        $time = [math]::Round(($cmd.EndExecutionTime - $cmd.StartExecutionTime).TotalMilliseconds)
        if (!$question) {
          $cmdletErr = try { $global:error[0] | Where-Object { $_ -ne $null } | Select-Object -ExpandProperty InvocationInfo } catch { $null }
          $err = if ($null -ne $cmdletErr -and $cmd.CommandLine -eq $cmdletErr.Line) { 1 } else { $exitCode }
          $char = $char.Replace("[34m", "[31m")
        }
        if ($script:showCmdDurationAndErrCode -and ($time -gt 5000 -or $err)) {
          $prompt += "#"
          if ($time -gt 5000) {
            $time = [TimeSpan]::FromMilliseconds($time)
            $prompt += " $([char]0x1B)[35m"
            if ($time.Hours -gt 0) { $prompt += "$($time.Hours)h " }
            if ($time.Minutes -gt 0) { $prompt += "$($time.Minutes)m " }
            $prompt += "$($time.Seconds)s$([char]0x1B)[0m"
          }
          if ($err) { 
            $prompt += " $([char]0x1B)[30m$err$([char]0x1B)[0m"
          }
          $len = [RegEx]::Replace($prompt, "\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])", "").Length
          $pad = [System.String]::new(" ", $Host.UI.RawUI.WindowSize.Width - $len + 1)
          $prompt = $prompt.Replace("#", $pad)
        }
      }
      $prompt += "`n$char"
      if ($location.Provider.Name -eq "FileSystem") {
        $prompt = $(Osc7) + $prompt
      }
      Set-PSReadLineOption -ExtraPromptLineCount ($prompt.Split("`n").Length - 1)
      $prompt
    }
    $global:LASTEXITCODE = $exitCode
    if ($global:? -ne $question) { if ($question) { 1 + 1 } else { Write-Error "" -ErrorAction Ignore } }
  }

}

# zoxide

$env:_ZO_FZF_OPTS = $env:FZF_DEFAULT_OPTS

Invoke-Expression -Command (& { (zoxide init --cmd cd powershell | Out-String) } )

