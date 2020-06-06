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
    "7-Zip",
    "Common",
    "Git",
    "AWS",
    "Drive",
    "Elixir",
    "Erlang",
    "Go",
    "ImageMagick",
    "IrfanView",
    "JPEGView",
    "KeePass",
    "MinGW",
    "MSYS2",
    "Node.js",
    "OpenSSH",
    "Perl",
    "PowerShell",
    "Python",
    "Ruby",
    "SumatraPDF",
    "Total Commander",
    "Vim",
    "NeoVim",
    "Visual Studio Code",
    "Windows Terminal",
    "WSLtty"

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

