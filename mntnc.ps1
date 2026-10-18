#requires -RunAsAdministrator

param (
  [Switch] $Fix,
  [Switch] $Chkdsk,
  [Switch] $Cleanmgr,
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

if ($Cleanmgr) {
  $selected = @(
    "Delivery Optimization Files"
    "Device Driver Packages"
    "Recycle Bin"
    "Temporary Files"
    "Update Cleanup"
  )
  $sageset = 42
  foreach ($key in Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches") {
    $value = $key.PSChildName -in $selected ? 2 : 0
    Set-ItemProperty $key.PSPath "StateFlags$($sageset.ToString('D4'))" $value -Type DWord
  }
  Write-Host "`e[37m`ncleanmgr /sagerun:$sageset`e[0m"
  Start-Process cleanmgr "/sagerun:$sageset" -Wait
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
