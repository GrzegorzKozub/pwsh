param (
  [Switch] $Chkdsk,
  [Switch] $Defrag,
  [Switch] $Fix
)

if (!([Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains "S-1-5-32-544")) {
  Write-Error "Must run as admin"
  break
}

function Log($tool, $drive) {
  $nl = [Environment]::NewLine
  $esc = [char]27
  $msg = "$nl$esc[1mRunning $tool"
  if ($drive) { $msg += " for ${drive}:" }
  $msg += "$esc[0m$nl"
  Write-Host -Object $msg -ForegroundColor DarkYellow
}

$exit = 0
$drives = Get-PSDrive -PSProvider FileSystem | Where-Object -Property Name -ne Temp

if ($Chkdsk) {
  foreach ($drive in $drives) {
    if ($Fix) {
      Log "chkdsk /F" $drive
      chkdsk /F "${drive}:"
    } else {
      Log "chkdsk" $drive
      chkdsk "${drive}:"
    }
    if (!$?) { $exit = 1 }
  }
}

if ($Defrag) {
  foreach ($drive in $drives) {
    Log "defrag /Retrim" $drive
    defrag "${drive}:" /Retrim
    if (!$?) { $exit = 1 }
  }
}

# if ($Tools -contains "dism") {
#   if ($Fix) { 
#     DISM.exe /Online /Cleanup-Image /RestoreHealth
#     DISM.exe /Online /Cleanup-Image /StartComponentCleanup # /ResetBase
#   } else {
#     DISM.exe /Online /Cleanup-Image /ScanHealth
#     DISM.exe /Online /Cleanup-Image /AnalyzeComponentStore
#   }
#   if (!$?) { $exit = 1 }
# }
#
# if ($Tools -contains "sfc") {
#   if ($Fix) { sfc /SCANNOW } else { sfc /VERIFYONLY }
#   if (!$?) { $exit = 1 }
# }

exit $exit
