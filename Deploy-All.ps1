Import-Module Admin

function Deploy-All {
  param (
    [switch] $SkipUnzip, [switch] $SkipC, [switch] $SkipD, [switch] $SkipPs1, [switch] $SkipReg,
    [switch] $Update, [switch] $Remove, [switch] $Pack,
    [switch] $Parallel,
    [string] $Source, [string] $Target
  )

  AssertRunningAsAdmin

  $time = [Diagnostics.Stopwatch]::StartNew()

  $apps =
    "7-Zip", "Common", "Git",
    "MinGW", "MSYS2",
    "AWS", "OpenSSH",
    "PowerShell", "Windows Terminal", "WSLtty",
    "Erlang", "Elixir", "Go", "Node.js", "Perl", "Python", "Ruby",
    "ImageMagick", "IrfanView", "JPEGView",
    "Vim", "NeoVim", "Visual Studio Code",
    "Drive", "Chrome", "KeePass", "SumatraPDF", "Total Commander"

  if ($env:COMPUTERNAME -eq "Drifter") {
    $apps = $apps + "MaxxAudioPro"
  }

  if ($env:COMPUTERNAME -eq "Turing") {
    $apps = $apps + "MSI Afterburner" + "RivaTuner Statistics Server"
  }

  foreach ($app in $apps) {
    Deploy-App -App $app `
      -SkipUnzip: $SkipUnzip -SkipC: $SkipC -SkipD: $SkipD -SkipPs1: $SkipPs1 -SkipReg: $SkipReg `
      -Update: $Update -Remove: $Remove -Pack: $Pack `
      -Parallel: $Parallel `
      -Source: $Source -Target: $Target
  }

  $time.Stop()
  Write-Host "All done in $($time.Elapsed.ToString("mm\:ss\.fff"))" -ForegroundColor DarkGray
}

