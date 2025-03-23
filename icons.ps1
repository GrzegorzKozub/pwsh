$lib = "mingw-w64-ucrt-x86_64-librsvg"
pacman -Qq $lib | Out-Null
if ($LASTEXITCODE -ne 0) { pacman -S --noconfirm $lib }

function Png($svg, $png, $size) {
  if ($size) {
    &rsvg-convert --width $size --height $size "$svg.svg" > "$png.png"
  } else {
    &rsvg-convert "$svg.svg" > "$png.png"
  }
}

function Ico($ico) { &magick *.png "$ico.ico" }

function Cleanup() {
  foreach ($size in 256, 128, 64, 48, 32, 24, 16) {
    Remove-Item -Path "$size.png", "$size.svg" -ErrorAction SilentlyContinue
  }
}

function Papirus($app, $cat, $icon) {
  $url = "https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-icon-theme/refs/heads/master/Papirus"
  foreach ($size in 64, 48, 32, 24, 16) {
    Invoke-WebRequest -Uri "$url/$($size)x$($size)/$cat/$icon.svg" -OutFile "$size.svg"
    Png $size $size
  }
  foreach ($size in 256, 128) { Png 64 $size $size }
  Ico $app
  Cleanup
}

function Gnome($app, $path, $icon) {
  # https://download.gnome.org/sources/gnome-icon-theme/2.20/gnome-icon-theme-2.20.0.tar.bz2
  $url = "https://upload.wikimedia.org/wikipedia/commons"
  Invoke-WebRequest -Uri "$url/$path/$icon.svg" -OutFile "256.svg"
  foreach ($size in 256, 128, 64, 48, 32, 24, 16) { Png 256 $size $size }
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

Gnome "paint.net" "f/fe/" "Gnome-applications-graphics"
Papirus "Steam" "apps" "steam"
Papirus "SumatraPDF" "mimetypes" "application-pdf"

Gnome "Total Commander" "3/38" "Gnome-media-floppy"
Papirus "Total Commander 2" "devices" "media-floppy"

Papirus "Visual Studio Code" "apps" "vscode"

Papirus "WezTerm" "apps" "utilities-terminal"
Papirus "WezTerm (Admin)" "apps" "utilities-terminal_su"

Papirus "Zed" "apps" "zed"
