# https://github.com/GNOME/adwaita-icon-theme
# https://github.com/numixproject/numix-icon-theme-circle
# https://github.com/numixproject/numix-icon-theme-square
# https://github.com/vinceliuice/Colloid-icon-theme
# https://github.com/vinceliuice/Qogir-icon-theme
# https://github.com/vinceliuice/Tela-circle-icon-theme
# https://github.com/vinceliuice/Tela-icon-theme

$lib = "mingw-w64-ucrt-x86_64-librsvg"
pacman -Qq $lib 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { pacman -S --noconfirm $lib }

# stop on any failure (e.g. curl giving up) instead of building broken icons
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

function Png($svg, $png, $size) {
  if ($size) {
    rsvg-convert --width $size --height $size "$svg.svg" -o "$png.png"
  } else {
    rsvg-convert "$svg.svg" -o "$png.png"
  }
}

function Ico($ico) {
  magick 256.png 128.png 64.png 48.png 32.png 24.png 16.png "$ico.ico"
}

function Download($url, $file) {
  curl.exe -fsL --retry 32 --retry-all-errors --retry-delay 2 $url -o $file
}

function Cleanup() {
  foreach ($size in 256, 128, 64, 48, 32, 24, 16) {
    Remove-Item "$size.png", "$size.svg" -ErrorAction SilentlyContinue
  }
}

function Papirus($app, $cat, $icon) { # https://github.com/PapirusDevelopmentTeam/papirus-icon-theme
  $url = "https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-icon-theme/refs/heads/master/Papirus"
  foreach ($size in 64, 48, 32, 24, 16) {
    Download "$url/$($size)x$($size)/$cat/$icon.svg" "$size.svg"
    Png $size $size
  }
  foreach ($size in 256, 128) { Png 64 $size $size }
  Ico $app
  Cleanup
}

function Gnome2($app, $cat, $icon) { # https://github.com/Distrotech/gnome-icon-theme
  $url = "https://raw.githubusercontent.com/Distrotech/gnome-icon-theme/refs/heads/gnome-2-20/scalable"
  Download "$url/$cat/$icon.svg" "256.svg"
  foreach ($size in 256, 128, 64, 48, 32, 24, 16) { Png 256 $size $size }
  Ico $app
  Cleanup
}

function Gnome3($app, $cat, $icon) { # https://github.com/Distrotech/gnome-icon-theme
  $url = "https://raw.githubusercontent.com/Distrotech/gnome-icon-theme/refs/heads/gnome-3-12/gnome"
  foreach ($size in 256, 48, 32, 24, 16) {
    Download "$url/$($size)x$($size)/$cat/$icon.png" "$size.png"
  }
  foreach ($size in 128, 64) { magick 256.png -resize "$($size)x$($size)" "$size.png" }
  Ico $app
  Cleanup
}

Papirus "Afterburner" "apps" "blackmagicraw-speedtest"
Papirus "Brave" "apps" "brave"
Papirus "Edge" "apps" "microsoft-edge"

Papirus "KeePassXC" "apps" "keepassxc"
Papirus "KeePassXC 2" "apps" "accessories-safe"

Papirus "mpv" "apps" "mpv"

Papirus "NVIDIA" "apps" "nvidia"
Papirus "NVIDIA 2" "apps" "com.leinardi.gwe"
Papirus "NVIDIA 3" "apps" "geforcenow"

Papirus "OBS" "apps" "obs"
Papirus "Obsidian" "apps" "obsidian"

Gnome2 "paint.net" "categories" "applications-graphics"
Gnome3 "paint.net 2" "categories" "applications-graphics"

Papirus "Steam" "apps" "steam"
Papirus "SumatraPDF" "mimetypes" "application-pdf"

Gnome2 "Total Commander" "devices" "media-floppy"
Gnome3 "Total Commander 2" "devices" "media-floppy"
Papirus "Total Commander 3" "devices" "media-floppy"

Papirus "Visual Studio Code" "apps" "vscode"

Papirus "WezTerm" "apps" "utilities-terminal"
Papirus "WezTerm 2" "apps" "utilities-terminal_su"

Papirus "Zed" "apps" "zed"
Papirus "TIDAL" "apps" "tidal-hifi"
