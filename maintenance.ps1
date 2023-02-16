param (
  [ValidateNotNullOrEmpty()] [string[]] $Tools = @("chkdsk", "defrag")
)

if (!(RunningAsAdmin)) {
  Write-Error "Must run as admin"
  break
}

$exit = 0

foreach (
  $drive in Get-PSDrive -PSProvider FileSystem |
    Where-Object -Property Name -NE Temp
) {
  if ($Tools -contains "chkdsk") { 
    chkdsk "${drive}:"
    if (!$?) { $exit = 1 }
  }
  if ($Tools -contains "defrag") {
    defrag "${drive}:" /Retrim
  }
}

if ($Tools -contains "dism") {
  DISM.exe /Online /Cleanup-Image /ScanHealth
  if (!$?) { $exit = 1 }
}

if ($Tools -contains "sfc") {
  sfc /VERIFYONLY
  if (!$?) { $exit = 1 }
}

exit $exit
