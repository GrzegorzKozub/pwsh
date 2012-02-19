function Optimize-Processes
{
    $processes = "checkforupdates coemsgdisplay com4qlbex hpqwmiex ida nvdkit query bluescreenevts radalert radconct radexecd radntfyc radpinit radpnlwr radrexxw radsched radskman radstgms radtray rimwbem"
    $processes.Split() | ForEach-Object { Get-Process $_ -ErrorAction SilentlyContinue } | ForEach-Object { $_.PriorityClass = "Idle" }

    Get-Process | Where-Object { $_.Company -eq "McAfee, Inc." } | Stop-Process -Force
}

Set-Alias op Optimize-Processes
