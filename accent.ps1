param ([Switch] $Reset)

function Dword ([Int64] $Value) {
  [BitConverter]::ToInt32([BitConverter]::GetBytes([UInt32] ($Value -band 0xFFFFFFFFL)), 0)
}

$accent = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent"
$dwm = "HKCU:\Software\Microsoft\Windows\DWM"

$current = (Get-ItemProperty -Path $dwm -Name "AccentColor").AccentColor
$target = [UInt32] ($(if ($Reset) { 0xffd77800L } else { 0xff1050caL }) -band 0xFFFFFFFFL)
if ($current -eq $target) { return }

if ($Reset) {

  Remove-ItemProperty -Path $accent -Name "AccentColorMenu" -ErrorAction SilentlyContinue
  Remove-ItemProperty -Path $accent -Name "AccentPalette" -ErrorAction SilentlyContinue
  Remove-ItemProperty -Path $accent -Name "StartColorMenu" -ErrorAction SilentlyContinue

  Set-ItemProperty -Path $dwm -Name "AccentColor" -Type DWord -Value (Dword 0xffd77800)
  Set-ItemProperty -Path $dwm -Name "ColorizationAfterglow" -Type DWord -Value (Dword 0xc40078d7)
  Set-ItemProperty -Path $dwm -Name "ColorizationColor" -Type DWord -Value (Dword 0xc40078d7)

} else {

  $accentPalette = [Byte[]] (
    0xf5, 0xc0, 0x7c, 0x00, 0xf0, 0x93, 0x46, 0x00,
    0xe4, 0x60, 0x12, 0x00, 0xca, 0x50, 0x10, 0x00,
    0xb6, 0x44, 0x0e, 0x00, 0x87, 0x28, 0x08, 0x00,
    0x5c, 0x0e, 0x03, 0x00, 0x52, 0x5e, 0x54, 0x00
  )

  Set-ItemProperty -Path $accent -Name "AccentColorMenu" -Type DWord -Value (Dword 0xff1050ca)
  Set-ItemProperty -Path $accent -Name "AccentPalette" -Type Binary -Value $accentPalette
  Set-ItemProperty -Path $accent -Name "StartColorMenu" -Type DWord -Value (Dword 0xff0e44b6)

  Set-ItemProperty -Path $dwm -Name "AccentColor" -Type DWord -Value (Dword 0xff1050ca)
  Set-ItemProperty -Path $dwm -Name "ColorizationAfterglow" -Type DWord -Value (Dword 0xc4ca5010)
  Set-ItemProperty -Path $dwm -Name "ColorizationColor" -Type DWord -Value (Dword 0xc4ca5010)

}

Stop-Process -Name "explorer"

# param ( [Switch] $Reset)
# sudo {
#   Start-Process -FilePath "regedit.exe" -ArgumentList "/s", $args[0] -Wait
# } -args $(Join-Path `
#     -Path $PSScriptRoot `
#     -ChildPath $(if ($Reset) { "blue.reg" } else { "orange.reg" }))
