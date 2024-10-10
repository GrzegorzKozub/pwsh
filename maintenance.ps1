param (
  [Switch] $ChkDsk,
  [Switch] $Defrag,
  [Switch] $Image,
  [Switch] $WinSxS,
  [Switch] $SFC,
  [Switch] $Fix
)

if (!([Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains "S-1-5-32-544")) {
  throw "Must run as admin"
}

function Run($checkCmd, $fixCmd) {
  if ($Fix -and $fixCmd) { $cmd = $fixCmd } else { $cmd = $checkCmd }
  Write-Host -Object "$([Environment]::NewLine)$cmd" -ForegroundColor DarkGray
  Invoke-Expression -Command $cmd
}

function Drives {
  return Get-PSDrive -PSProvider FileSystem | Where-Object -Property Name -ne Temp
}

if ($ChkDsk) {
  foreach ($drive in Drives) {
    Run `
      "chkdsk ${drive}:" `
      "chkdsk /F ${drive}:"
  }
}

if ($Defrag) {
  foreach ($drive in Drives) {
    Run "defrag /Retrim ${drive}:"
  }
}

if ($Image) {
  Run `
    "DISM.exe /Online /Cleanup-Image /ScanHealth" `
    "DISM.exe /Online /Cleanup-Image /RestoreHealth"
}

if ($WinSxS) {
  Run `
    "DISM.exe /Online /Cleanup-Image /AnalyzeComponentStore" `
    "DISM.exe /Online /Cleanup-Image /StartComponentCleanup" # /ResetBase
}

if ($SFC) {
  Run `
    "sfc /VERIFYONLY" `
    "sfc /SCANNOW"
}
