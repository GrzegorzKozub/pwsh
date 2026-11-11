# runs a command with rtss started for its duration, e.g. as steam launch options
# (steam requires the first token to be a full path to an existing file):
# C:\Windows\System32\conhost.exe --headless D:\Apps\PowerShell\pwsh.exe -NoLogo -NoProfile -NonInteractive -File C:\Users\Greg\Documents\PowerShell\rtss.ps1 %command%
# C:\Windows\System32\conhost.exe --headless D:\Apps\PowerShell\pwsh.exe -NoLogo -NoProfile -NonInteractive -File C:\Users\Greg\Documents\PowerShell\rtss.ps1 D:\Apps\Python\pythonw.exe er-patcher --rate 240 -vcafs -- %command%

# rtss requires admin so it's started through a task registered with highest privileges
$task = 'RivaTuner Statistics Server'
$command, $arguments = $args

# leave rtss alone if it was already running
$started = !(Get-Process 'RTSS' -ErrorAction SilentlyContinue)

if ($started) {
  Start-ScheduledTask $task
  $timeout = (Get-Date).AddSeconds(10)
  while (!(Get-Process 'RTSS' -ErrorAction SilentlyContinue) -and (Get-Date) -lt $timeout) {
    Start-Sleep -Milliseconds 250
  }
}

try {
  # piping makes it wait for gui apps too
  & $command @arguments | Out-Null
} finally {
  if ($started) { Stop-ScheduledTask $task }
}
