# C:\Windows\System32\conhost.exe --headless pwsh.exe -NoLogo -NoProfile -NonInteractive -File %USERPROFILE%\Documents\PowerShell\game.ps1 %command%
# C:\Windows\System32\conhost.exe --headless pwsh.exe -NoLogo -NoProfile -NonInteractive -File %USERPROFILE%\Documents\PowerShell\game.ps1 D:\Apps\Python\pythonw.exe er-patcher --rate 240 -vcafs -- %command%

$windows = 'windows'
$rtss = 'RivaTuner Statistics Server'

$enableHdr = [bool]((hdr.exe status) -match 'supported=true enabled=false')
$stopWindows = (Get-ScheduledTask $windows -ErrorAction SilentlyContinue).State -eq 'Running'
$startRtss = !(Get-Process 'RTSS' -ErrorAction SilentlyContinue)

if ($enableHdr) { hdr.exe on | Out-Null }

function WaitFor ($condition) {
  $timeout = (Get-Date).AddSeconds(10)
  while (!(& $condition) -and (Get-Date) -lt $timeout) { Start-Sleep -Milliseconds 250 }
}

if ($stopWindows) {
  Stop-ScheduledTask $windows
  WaitFor { !(Get-Process 'AutoHotkey64' -ErrorAction SilentlyContinue) }
}

if ($startRtss) {
  Start-ScheduledTask $rtss
  WaitFor { Get-Process 'RTSS' -ErrorAction SilentlyContinue }
}

try {

  $command, $arguments = $args
  & $command @arguments | Out-Null

} finally {

  if ($enableHdr) { hdr.exe off | Out-Null }
  if ($stopWindows) { Start-ScheduledTask $windows }
  if ($startRtss) { Stop-ScheduledTask $rtss }

}
