function _defer { # runs once from the prompt function (functions and aliases must be global)

  # stop on errors

  $ErrorActionPreference = "Stop"

  # psreadline

  Set-PSReadlineOption -BellStyle None
  Set-PSReadLineOption -MaximumHistoryCount 100000
  Set-PSReadLineOption -PredictionSource History

  [Console]::OutputEncoding = [Console]::InputEncoding = [Text.Encoding]::UTF8 # https://github.com/PowerShell/PSReadLine/issues/2866

  # terminal features

  if ($env:WT_SESSION) { # https://github.com/microsoft/terminal/issues/11057
    $env:COLORTERM = "truecolor" # fix bat color tint
    # $env:TERM = "xterm-256color" # clear screen when neovim exits
  }

  # vi mode

  # https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences

  if ($env:WT_SESSION) { Write-Host -NoNewLine "`e[6 q" }

  Set-PSReadLineOption -EditMode Vi
  Set-PSReadLineKeyHandler -ViMode Command -Chord "v,v" -Function ViEditVisually # was v by default

  # dir colors (eza, lf)

  $env:LS_COLORS = "rs=0:di=36:ln=34:pi=33:so=35:do=35:bd=33:cd=33:or=31:mi=0:tw=36:ow=36:st=36:ex=32:*.7z=33:*.gz=33:*.rar=33:*.tar=33:*.zip=33:*.cow=35:*.fsa=35:*.mrimg=35:*.mrimgx=35:*.wim=35:*.iso=35:*.ico=35:*.jpeg=35:*.jpg=35:*.png=35:*.svg=35:*.mp3=35:*.ogg=35:*.opus=35:*.mkv=35:*.mp4=35:*.webm=35:*.dockerignore=37:*.editorconfig=37:*.env=37:*.eslintrc=37:*.eslintrc.js=37:*.eslintrc.json=37:*.git=37:*.gitattributes=37:*.gitignore=37:*.gitkeep=37:*.gitmodules=37:*.lock=37:*.luacheckrc=37:*.luarc.json=37:*.npmrc=37:*.nvmrc=37:*.prettierignore=37:*.prettierrc=37:*.pylintrc=37:*.stylua.toml=37:*.taplo.toml=37:*.backup=90:*.bak=90:*.log=90:*.off=90:*.old=90:*.orig=90:*.original=90:*.part=90:*.swp=90:*.tmp=90"
  $env:LS_COLORS = $env:LS_COLORS + ":*.AppImage=32:*.nu=32:*.sh=32:*.zsh=32:*.bat=32:*.cmd=32:*.exe=32:*.ps1=32"

  # eza

  $env:EZA_COLORS = "oc=37:ur=37:uw=37:ux=37:ue=37:gr=37:gw=37:gx=37:tr=37:tw=37:tx=37:su=37:sf=37:xa=37:nb=90:nk=37:nm=33:ng=31:nt=91:uu=90:uR=31:un=37:gu=90:gR=31:gn=37:ga=32:gm=33:gd=31:gv=33:gt=33:gi=90:gc=91:Gm=34:Go=34:Gc=30:Gd=33:da=37:bO=31:mp=34;4:cr=33:do=0:tm=90:bu=0:sc=0:ff=37"
  $env:EZA_ICONS_AUTO = 1
  $env:EZA_WINDOWS_ATTRIBUTES="short"

  function global:ls { eza.exe --all --group-directories-first --no-permissions --no-quotes $args }
  function global:la { eza.exe --all --group-directories-first --no-permissions --no-quotes --long $args }

  Remove-Alias -Name ls

  # fd

  function global:fd { fd.exe --exclude .git --hidden $args }

  # fzf

  $env:FZF_DEFAULT_OPTS="
    --bind=ctrl-d:page-down,ctrl-u:page-up
    --bind=alt-j:preview-down,alt-k:preview-up
    --bind=alt-down:preview-down,alt-up:preview-up
    --bind=alt-d:preview-page-down,alt-u:preview-page-up
    --border none
    --color dark
    --color fg:bright-black,selected-fg:white,preview-fg:-1
    --color hl:yellow,selected-hl:yellow
    --color current-fg:-1,current-bg:-1,gutter:-1,current-hl:yellow
    --color info:bright-black
    --color border:bright-black
    --color prompt:magenta
    --color pointer:white,marker:white
    --ellipsis '…'
    --height 50%
    --layout reverse-list
    --margin 0
    --marker '• '
    --no-bold
    --no-info
    --no-scrollbar
    --no-separator
    --padding 0
    --pointer '●'
    --prompt '●• '
    --scroll-off 3
    --tabstop 2
  "

  function global:glo {
    $pager = git config core.pager
    git ls --color=always $args |
      fzf `
        --ansi `
        --bind='?:toggle-preview,alt-w:toggle-preview-wrap' `
        --height=100% `
        --preview "echo {} | cut -d' ' -f2 | xargs -I% git show --color=always % -- $args | $pager" `
        --preview-window='border:rounded,right:50%'
    return
  }

  # psfzf

  Import-Module -Name "PSFzf"
  Set-PsFzfOption `
    -PSReadlineChordReverseHistory "ctrl+r" `
    -PSReadlineChordProvider "ctrl+t" `
    -PSReadlineChordSetLocation "alt+c"

  # gsudo

  Set-Alias -Name sudo -Value gsudo -Scope Global

  # less

  $env:LESS = "--quit-if-one-screen --RAW-CONTROL-CHARS --squeeze-blank-lines --use-color -DEr -DPw" # -DSkY -Ddy -Dsm -Dub
  $env:LESSHISTFILE = "-"
  $env:PAGER = "less --quit-if-one-screen --RAW-CONTROL-CHARS --squeeze-blank-lines --use-color -DEr -DPw" # -DSkY -Ddy -Dsm -Dub

  # yazi

  function global:_cd {
    param ([scriptblock]$Cmd)
    $tempFile = New-TemporaryFile
    & $Cmd $tempFile.FullName
    if (Test-Path -PathType Leaf $tempFile) {
      $dir = Get-Content -Path $tempFile
      Remove-Item -Path $tempFile
      if ((Test-Path -PathType Container "$dir") -and "$dir" -ne "$pwd") {
        Set-Location -Path "$dir"
      }
    }
  }

  function global:l { _cd -Cmd { yazi.exe --cwd-file $args[0] } }
  function global:y { _cd -Cmd { yazi.exe --cwd-file $args[0] } }

  # neovim

  $env:EDITOR = $env:VISUAL = "nvim"

  Set-Alias -Name vim -Value nvim -Scope Global
  Set-Alias -Name v -Value nvim -Scope Global

  # vscode

  Set-Alias -Name c -Value code -Scope Global

  # shutdown

  function global:shutdn { shutdown /t 0 /s }
  function global:reboot { shutdown /t 0 /r }
  function global:reflect { shutdown /t 0 /r /o }

  # syntax highlighting

  Set-PSReadLineOption -Colors @{
    "Command" = [ConsoleColor]::DarkGreen
    "Comment" = [ConsoleColor]::Black
    "ContinuationPrompt" = [ConsoleColor]::DarkBlue
    "Default" = [ConsoleColor]::White
    "Emphasis" = [ConsoleColor]::DarkYellow
    "Error" = [ConsoleColor]::DarkRed
    "InlinePrediction" = [ConsoleColor]::DarkGray
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

  $PSStyle.FileInfo.Directory = $PSStyle.Foreground.Cyan
  $PSStyle.FileInfo.Executable = $PSStyle.Foreground.Green
  $PSStyle.FileInfo.SymbolicLink = $PSStyle.Foreground.Blue

  $PSStyle.FileInfo.Extension.Clear()

  ".ps1" |
    ForEach-Object { $PSStyle.FileInfo.Extension.Add($_, $PSStyle.Foreground.Green) }
  ".7z", ".gz", ".rar", ".tar", ".zip" |
    ForEach-Object { $PSStyle.FileInfo.Extension.Add($_, $PSStyle.Foreground.Yellow) }
  ".cow", ".fsa", ".mrimg", ".wim" |
    ForEach-Object { $PSStyle.FileInfo.Extension.Add($_, $PSStyle.Foreground.Magenta) }
  ".iso" |
    ForEach-Object { $PSStyle.FileInfo.Extension.Add($_, $PSStyle.Foreground.Magenta) }
  ".ico", ".jpeg", ".jpg", ".png", ".svg" |
    ForEach-Object { $PSStyle.FileInfo.Extension.Add($_, $PSStyle.Foreground.Magenta) }
  ".mp3", ".ogg", ".opus" |
    ForEach-Object { $PSStyle.FileInfo.Extension.Add($_, $PSStyle.Foreground.Magenta) }
  ".mkv", ".mp4", ".webm" |
    ForEach-Object { $PSStyle.FileInfo.Extension.Add($_, $PSStyle.Foreground.Magenta) }
  ".dockerignore", ".editorconfig", ".env", ".eslintrc", ".git", ".gitattributes", ".gitignore", ".gitkeep", ".gitmodules", ".lock", ".luacheckrc", ".npmrc", ".nvmrc", ".prettierignore", ".prettierrc", ".pylintrc" |
    ForEach-Object { $PSStyle.FileInfo.Extension.Add($_, $PSStyle.Foreground.White) }
  ".backup", ".bak", ".log", ".off", ".old", ".orig", ".original", ".part", ".swp", ".tmp" |
    ForEach-Object { $PSStyle.FileInfo.Extension.Add($_, $PSStyle.Foreground.BrightBlack) }

  # vi mode indicator

  Set-PSReadLineOption -ViModeIndicator Script -ViModeChangeHandler {
    Write-Host -NoNewLine "`e[$(if ($args[0] -eq 'Command') { '2' } else { '6' }) q"
  }

  # zoxide

  $env:_ZO_FZF_OPTS = $env:FZF_DEFAULT_OPTS
  Invoke-Expression -Command (& { (zoxide init --cmd cd powershell | Out-String) } )

  # completion

  try {
    . _bat.ps1
    . _fd.ps1
    . _hyperfine.ps1
    . _rg.ps1
    . _yazi.ps1
    . _zoxide.ps1
  } catch {}

} # _defer ends

# prompt

Set-PSReadLineOption -ContinuationPrompt " • "
Set-PSReadLineOption -PromptText "`e[34m●• `e[0m", "`e[31m●• `e[0m"

if ([Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains "S-1-5-32-544") {
  $script:admin = "$([char]0x1B)[33m⛊$([char]0x1B)[0m "
}

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

if (Get-Command "git" -ErrorAction SilentlyContinue) {
  function _git {
    if (!(Test-Path -Path ".git")) { return "" }
    # https://git-scm.com/docs/git-status#_porcelain_format_version_2
    $status = git status --porcelain=2 --branch --show-stash # --ignore-submodule
    foreach ($line in $status) {
      if ($line -match "# branch.oid (.*)") { $commit = $Matches[1] }
      if ($line -match "# branch.head (.*)") { $branch = $Matches[1] }
      if ($line -match "# branch.ab \+(.*) \-(.*)") {
        if ($Matches[1] -gt 0) { $ahead = $Matches[1] }
        if ($Matches[2] -gt 0) { $behind = $Matches[2] }
      }
      if ($line -match "# stash (.*)") { $stash = $Matches[1] }
      if ($line -match "[12] ([\.AMD])([\.AMD])") {
        if ($Matches[1] -ne ".") { $staged++ }
        if ($Matches[2] -ne ".") { $unstaged++ }
      }
      if ($line -match "u .*") { $unmerged++ }
      if ($line -match "\? .*") { $untracked++ }
    }
    if ($branch -match "(detached)") {
      $branchOrCommit = "`e[33m$(-join $commit[0..6])`e[0m "
    } else {
      if ($branch.Length -gt 32) { $branch = "$(-join $branch[0..3])…" }
      $branchOrCommit = "`e[34m$branch`e[0m "
    }
    $behind = if ($behind) { "`e[33m↓$behind`e[0m " } else { "" }
    $ahead = if ($ahead) { "`e[32m↑$ahead`e[0m " } else { "" }
    $stash = if ($stash) { "`e[35m←$stash`e[0m " } else { "" }
    $unmerged = if ($unmerged) { "`e[31m?$unmerged`e[0m " } else { "" }
    $staged = if ($staged) { "`e[32m+$staged`e[0m " } else { "" }
    $unstaged = if ($unstaged) { "`e[33m~$unstaged`e[0m " } else { "" }
    $untracked = if ($untracked) { "`e[31m*$untracked`e[0m " } else { "" }
    return " $branchOrCommit$behind$ahead$stash$unmerged$staged$unstaged$untracked"
  }
} else { function _git { return "" } }

function _osc7 {
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
    $prompt = "$script:admin$path$(_git)"
    if ($cmd = Get-History -Count 1) {
      $time = [math]::Round(($cmd.EndExecutionTime - $cmd.StartExecutionTime).TotalMilliseconds)
      if (!$question) {
        $cmdletErr = try { $global:error[0] | Where-Object { $_ -ne $null } | Select-Object -ExpandProperty InvocationInfo } catch { $null }
        $err = if ($null -ne $cmdletErr -and $cmd.CommandLine -eq $cmdletErr.Line) { 1 } else { $exitCode }
        $char = $char.Replace("[34m", "[31m")
      }
      if ($time -gt 5000 -or $err) {
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
      $prompt = $(_osc7) + $prompt
    }
    Set-PSReadLineOption -ExtraPromptLineCount ($prompt.Split("`n").Length - 1)
    $prompt
  }
  $global:LASTEXITCODE = $exitCode
  if ($global:? -ne $question) { if ($question) { 1 + 1 } else { Write-Error "" -ErrorAction Ignore } }
  if (!$script:delayedDone) { _defer; $script:delayedDone = $true }
}