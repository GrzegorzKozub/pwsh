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
        $Remove,

        [Parameter(Position = 6)]
        [switch]
        $Pack,

        [Parameter(Position = 7)]
        [switch]
        $Parallel,

        [Parameter(Position = 8)]
        [string]
        $Source,

        [Parameter(Position = 9)]
        [string]
        $Target
    )

    if (!(Test-Admin)) {
        Write-Error "Must run as admin"
        return
    }

    $time = [Diagnostics.Stopwatch]::StartNew()

    $essentials = "7-Zip", "Common", "Git"

    $other = "clink",
             "ConEmu",
             "docker",
             "dotnet",
             "Dropbox",
             "Go",
             "IrfanView",
             "KeePass",
             "MinGW",
             "MSYS2",
             "Node.js",
             "OBS",
             "paint.net",
             "Perl",
             "Python",
             "Resource Hacker",
             "Ruby",
             "SumatraPDF",
             "Total Commander",
             "Vim",
             "Visual Studio Code",
             "Yarn"

    if ($env:COMPUTERNAME -eq "Drifter") {
        $other = $other + "MaxxAudioPro"
    }

    if ($env:COMPUTERNAME -eq "Turing") {
        $other = $other + "NVIDIA Inspector" + "MSI Afterburner"
    }

    function DeployApps ($apps) {
        foreach ($app in $apps) {
            Deploy-App -App $app -SkipUnzip: $SkipUnzip -SkipC: $SkipC -SkipD: $SkipD -SkipPs1: $SkipPs1 -SkipReg: $SkipReg -Remove: $Remove -Pack: $Pack -Parallel: $Parallel -Source: $Source -Target: $Target
        }
    }

    DeployApps $essentials
    DeployApps $other

    $time.Stop()
    Write-Host "All done in $($time.Elapsed.ToString("mm\:ss\.fff"))" -ForegroundColor DarkGray
}

