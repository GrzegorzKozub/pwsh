$image = Join-Path -Path $env:USERPROFILE -ChildPath "Pictures\Wallpapers\gruvbox.jpg"

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

  $personalization = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"

  # New-Item -Path $personalization -Force | Out-Null

  New-ItemProperty -Path $personalization `
    -Name "LockScreenImagePath" -PropertyType "String" -Value $image -Force | Out-Null
  New-ItemProperty -Path $personalization `
    -Name "LockScreenImageStatus" -PropertyType "DWord" -Value 1 -Force | Out-Null

  # Remove-Item -Path $personalization -ErrorAction SilentlyContinue

}
