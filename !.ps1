# random wallpaper + lock screen
& (Join-Path -Path $PSScriptRoot -ChildPath "wall.ps1")

# accent color -> orange

$accentKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent"
$dwmKey = "HKCU:\Software\Microsoft\Windows\DWM"

if (-not (Test-Path -Path $accentKey)) { New-Item -Path $accentKey -Force | Out-Null }

# ABGR / ARGB packing for RGB(255,165,0)
$accentAbgr = 0xFF00A5FF
$colorizationArgb = 0xFFFFA500

New-ItemProperty -Path $accentKey -Name "AccentColorMenu" -PropertyType "DWord" -Value $accentAbgr -Force | Out-Null

New-ItemProperty -Path $dwmKey -Name "AccentColor" -PropertyType "DWord" -Value $accentAbgr -Force | Out-Null
New-ItemProperty -Path $dwmKey -Name "ColorizationColor" -PropertyType "DWord" -Value $colorizationArgb -Force | Out-Null
New-ItemProperty -Path $dwmKey -Name "ColorizationAfterglow" -PropertyType "DWord" -Value $colorizationArgb -Force | Out-Null
New-ItemProperty -Path $dwmKey -Name "AutoColorization" -PropertyType "DWord" -Value 0 -Force | Out-Null

Stop-Process -Name explorer -Force

# night light: turn off (schedule then has nothing to trigger)

$sid = ([System.Security.Principal.WindowsIdentity]::GetCurrent()).User.Value
$nightLightOff = [byte[]](2,0,0,0,147,250,216,91,185,109,210,1,0,0,0,0,67,66,1,0,208,10,2,198,20,202,236,227,222,149,183,155,233,1,0)

$nightLightPaths = @(
  "HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\DefaultAccount\Current\default`$windows.data.bluelightreduction.bluelightreductionstate\Current"
  "HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultAccount\$sid\Current\`$`$windows.data.bluelightreduction.bluelightreductionstate\Current"
)

foreach ($path in $nightLightPaths) {
  if (-not (Test-Path -Path $path)) { New-Item -Path $path -Force | Out-Null }
  New-ItemProperty -Path $path -Name "Data" -PropertyType "Binary" -Value $nightLightOff -Force | Out-Null
}

# smart app control: off

sudo {

  $key = "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy"
  Set-ItemProperty -Path $key -Name "VerifiedAndReputablePolicyState" -Value 0 -Force
  CiTool.exe -r | Out-Null

}
