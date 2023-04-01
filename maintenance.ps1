param (
  [string[]] $Drives = @(),
  [Switch] $Fix,
  [ValidateNotNullOrEmpty()] [string[]] $Tools = @("chkdsk", "defrag")
)

function Admin {
  return [Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains "S-1-5-32-544"
}

if (!(Admin)) {
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
    DISM.exe /Online /Cleanup-Image /RestoreHealth
  } else {
    DISM.exe /Online /Cleanup-Image /ScanHealth
  }
  if (!$?) { $exit = 1 }
}

if ($Tools -contains "sfc") {
  if ($Fix) { sfc /SCANNOW } else { sfc /VERIFYONLY }
  if (!$?) { $exit = 1 }
}

exit $exit
