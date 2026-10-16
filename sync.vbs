' not needed; "sync" scheduled task uses `conhost.exe --headless` now
CreateObject("WScript.Shell").Run "pwsh.exe -WindowStyle Hidden -NoLogo -NonInteractive -NoProfile -Command ~\Documents\PowerShell\sync.ps1", 0, true
