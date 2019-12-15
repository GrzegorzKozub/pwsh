# Does not deploy Windows, Chrome and Visual Studio

Import-Module Admin

function Deploy-All {
  [CmdletBinding()]

  param (
    [Parameter(Position = 0)]
    [switch]
    $SkipUnzip,

    [Parameter(Position = 1)]
    [switch]
    $SkipC,

    [Parameter(Position = 2)]
    [switch]
    $SkipD,

    [Parameter(Position = 3)]
    [switch]
    $SkipPs1,

    [Parameter(Position = 4)]
    [switch]
    $SkipReg,

    [Parameter(Position = 5)]
    [switch]
    $Update,

    [Parameter(Position = 6)]
    [switch]
    $Remove,

    [Parameter(Position = 7)]
    [switch]
    $Pack,

    [Parameter(Position = 8)]
    [switch]
    $Parallel,

    [Parameter(Position = 9)]
    [string]
    $Source,

    [Parameter(Position = 10)]
    [string]
    $Target
  )

  AssertRunningAsAdmin

  $time = [Diagnostics.Stopwatch]::StartNew()

  $essentials = "7-Zip", "Common", "Git"

  $other = "AWS",
       "docker",
       "dotnet",
       "Dropbox",
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
    $other = $other + "MaxxAudioPro"
  }

  if ($env:COMPUTERNAME -eq "Turing") {
    $other = $other + "MSI Afterburner" + "NVIDIA" + "RivaTuner Statistics Server"
  }

  function DeployApps ($apps) {
    foreach ($app in $apps) {
      Deploy-App -App $app -SkipUnzip: $SkipUnzip -SkipC: $SkipC -SkipD: $SkipD -SkipPs1: $SkipPs1 -SkipReg: $SkipReg -Update: $Update -Remove: $Remove -Pack: $Pack -Parallel: $Parallel -Source: $Source -Target: $Target
    }
  }

  DeployApps $essentials
  DeployApps $other

  $time.Stop()
  Write-Host "All done in $($time.Elapsed.ToString("mm\:ss\.fff"))" -ForegroundColor DarkGray
}

