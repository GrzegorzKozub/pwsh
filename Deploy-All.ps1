function Deploy-All {
  param (
    [switch] $SkipC, [switch] $SkipD, [switch] $SkipPs1, [switch] $SkipReg,
    [switch] $Remove, [switch] $Pack
  )

  $time = [Diagnostics.Stopwatch]::StartNew()

  $apps =
    "7-Zip", "Common", "Git",
    "MinGW", "MSYS2",
    "Erlang", "Elixir", "Go", "Node.js", "Perl", "Python", "Ruby",
    "AWS", "OpenSSH",
    "PowerShell", "Windows Terminal", "WSLtty",
    "ImageMagick", "IrfanView", "JPEGView",
    "Vim", "NeoVim", "Visual Studio Code",
    "Chrome", "KeePass", "SumatraPDF", "Total Commander"

  if ($env:COMPUTERNAME -eq "Drifter") {
    $apps = $apps + "MaxxAudioPro"
  }

  if ($env:COMPUTERNAME -eq "Turing") {
    $apps = $apps + "MSI Afterburner" + "RivaTuner Statistics Server"
  }

  foreach ($app in $apps) {
    Deploy-App -App $app `
      -SkipC: $SkipC -SkipD: $SkipD -SkipPs1: $SkipPs1 -SkipReg: $SkipReg `
      -Remove: $Remove -Pack: $Pack
  }

  $time.Stop()
  Write-Host "All done in $($time.Elapsed.ToString("mm\:ss\.fff"))" -ForegroundColor DarkGray
}

