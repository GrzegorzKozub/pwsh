# C:\Windows\System32\conhost.exe --headless pwsh.exe -NoLogo -NoProfile -NonInteractive -File %USERPROFILE%\Documents\PowerShell\game.ps1 %command%
# C:\Windows\System32\conhost.exe --headless pwsh.exe -NoLogo -NoProfile -NonInteractive -File %USERPROFILE%\Documents\PowerShell\game.ps1 D:\Apps\Python\pythonw.exe er-patcher --rate 240 -vcafs -- %command%

function WaitFor ($condition, $seconds = 10) {
  $timeout = (Get-Date).AddSeconds($seconds)
  while (!(& $condition) -and (Get-Date) -lt $timeout) { Start-Sleep -Milliseconds 250 }
}

# hdr

$enableHdr = [bool]((hdr.exe status) -match 'hdr off')
if ($enableHdr) { hdr.exe on | Out-Null }

# windows.ahk

$windows = 'windows'
$stopWindows = (Get-ScheduledTask $windows -ErrorAction SilentlyContinue).State -eq 'Running'

if ($stopWindows) {
  Stop-ScheduledTask $windows
  WaitFor { !(Get-Process 'AutoHotkey64' -ErrorAction SilentlyContinue) }
}

# rtss

$rtss = 'RivaTuner Statistics Server'
$startRtss = !(Get-Process 'RTSS' -ErrorAction SilentlyContinue)

if ($startRtss) {
  Start-ScheduledTask $rtss
  WaitFor { Get-Process 'RTSS' -ErrorAction SilentlyContinue }
}

# launcher

$launchers = @(
  'C:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\upc.exe'
)

function Launchers ($except = @()) {
  Get-Process | Where-Object { $_.Path -and $launchers -contains $_.Path -and $except -notcontains $_.Path }
}

$runningLaunchers = @(Launchers | ForEach-Object Path)

# game

$game = $args |
  ForEach-Object { if ($_ -match '^(.+\\steamapps\\common\\[^\\]+)\\') { $Matches[1] + '\' } } |
  Select-Object -First 1

function GameRunning {
  [bool](Get-Process | Where-Object { $_.Path -and $_.Path.StartsWith($game, 'OrdinalIgnoreCase') })
}

# main

try {

  $command, $arguments = $args
  & $command @arguments | Out-Null

  if ($game) { do { Start-Sleep 5 } while (GameRunning) }

} finally {

  if ($enableHdr) { hdr.exe off | Out-Null }
  if ($stopWindows) { Start-ScheduledTask $windows }
  if ($startRtss) { Stop-ScheduledTask $rtss }

  if (Launchers $runningLaunchers) {
    Start-Sleep 5 # save sync
    Launchers $runningLaunchers | ForEach-Object { [void]$_.CloseMainWindow() }
    WaitFor { !(Launchers $runningLaunchers) } 10
    Launchers $runningLaunchers | Stop-Process -Force -ErrorAction SilentlyContinue
  }

}
