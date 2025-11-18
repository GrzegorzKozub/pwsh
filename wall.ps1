$dir = Join-Path -Path $env:USERPROFILE -ChildPath "Pictures\Wallpapers"
$image = Join-Path -Path $dir `
  -ChildPath (& (Join-Path -Path $dir -ChildPath "random.ps1"))

# wallpaper

Add-Type -TypeDefinition @"
using System.Runtime.InteropServices;
public class Wall {
  [DllImport("user32.dll", SetLastError = true)]
  public static extern bool SystemParametersInfo(long uAction, long uiParam, string pvParam, long fWinIni);
}
"@

$SPI_SETDESKWALLPAPER = 20
$SPIF_UPDATEINIFILE = 1
$SPIF_SENDWININICHANGE = 2

[Wall]::SystemParametersInfo( `
  $SPI_SETDESKWALLPAPER, 0, $image, `
  $SPIF_UPDATEINIFILE -bor $SPIF_SENDWININICHANGE `
) | Out-Null

# lock screen

sudo {

  $key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"

  if (-not (Test-Path -Path $key)) { New-Item -Path $key | Out-Null }

  New-ItemProperty -Path $key `
    -Name "LockScreenImagePath" -PropertyType "String" -Value $args `
    -Force | Out-Null

  New-ItemProperty -Path $key `
    -Name "LockScreenImageStatus" -PropertyType "DWord" -Value 1 `
    -Force | Out-Null

} -args $image

