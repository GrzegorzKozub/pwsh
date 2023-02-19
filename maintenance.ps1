param (
  [string[]] $Drives = @(),
  [Switch] $Fix,
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
  if (($Drives.Length -ne 0) -and !($Drives -contains "${drive}:")) { continue }

  if ($Tools -contains "chkdsk") { 
    if ($Fix) { chkdsk /F "${drive}:" } else { chkdsk "${drive}:" }
    if (!$?) { $exit = 1 }
  }
  if ($Tools -contains "defrag") {
    defrag "${drive}:" /Retrim
  }
}

if ($Tools -contains "dism") {
  if ($Fix) { 
    DISM.exe /Online /Cleanup-Image /ScanHealth
  } else {
    DISM.exe /Online /Cleanup-Image /RestoreHealth
  }
  if (!$?) { $exit = 1 }
}

if ($Tools -contains "sfc") {
  if ($Fix) { sfc /SCANNOW } else { sfc /VERIFYONLY }
  if (!$?) { $exit = 1 }
}

exit $exit
