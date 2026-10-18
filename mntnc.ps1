#requires -RunAsAdministrator

param (
  [Switch] $Fix,
  [Switch] $Chkdsk,
  [Switch] $Defrag,
  [Switch] $DismComponents,
  [Switch] $DismImage,
  [Switch] $Sfc
)

function Run($checkCmd, $fixCmd) {
  $cmd = $Fix -and $fixCmd ? $fixCmd : $checkCmd
  Write-Host "`e[37m`n$cmd`e[0m"
  Invoke-Expression $cmd
}

function Drives {
  return Get-PSDrive -PSProvider FileSystem | Where-Object Name -ne Temp
}

if ($Chkdsk) {
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

if ($DismComponents) {
  Run `
    "DISM.exe /Online /Cleanup-Image /AnalyzeComponentStore" `
    "DISM.exe /Online /Cleanup-Image /StartComponentCleanup" # /ResetBase
}

if ($DismImage) {
  Run `
    "DISM.exe /Online /Cleanup-Image /ScanHealth" `
    "DISM.exe /Online /Cleanup-Image /RestoreHealth"
}

if ($Sfc) {
  Run `
    "sfc /VERIFYONLY" `
    "sfc /SCANNOW"
}
