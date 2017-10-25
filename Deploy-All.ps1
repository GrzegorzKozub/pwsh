function Deploy-All {
    [CmdletBinding()]
    
    param (
        [Parameter(Position = 0)]
        [switch]
        $SkipExtract = $false,

        [Parameter(Position = 1)]
        [switch]
        $SkipC = $false,

        [Parameter(Position = 2)]
        [switch]
        $SkipD = $false,

        [Parameter(Position = 3)]
        [switch]
        $SkipPs1 = $false,

        [Parameter(Position = 4)]
        [switch]
        $SkipReg = $false,

        [Parameter(Position = 5)]
        [switch]
        $Remove = $false,

        [Parameter(Position = 6)]
        [switch]
        $Pack = $false,

        [Parameter(Position = 7)]
        [switch]
        $Parallel = $false
    )

    if (!(Test-Admin)) {
        Write-Error "Must run as admin"
        return
    }

    $time = [Diagnostics.Stopwatch]::StartNew()

    $essentials = "7-Zip", "Common", "Git"

    $other = "Chrome",
             "clink",
             "ConEmu",
             "Docker",
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
             "SyncBackPro",
             "Total Commander",
             "Vim",
             "Visual Studio Code",
             "Yarn"

    $device = Get-Content Env:\COMPUTERNAME

    if ($device -eq "Slut") {
        $other = $other + "NVIDIA" + "NVIDIA Inspector" + "Realtek"
    }

    if ($device -eq "Drifter") {
        $other = $other + "MaxxAudioPro"
    }

    function DeployApps ($apps) {
        foreach ($app in $apps) {
            Deploy-App -App $app -SkipExtract: $SkipExtract -SkipC: $SkipC -SkipD: $SkipD -SkipPs1: $SkipPs1 -SkipReg: $SkipReg -Remove: $Remove -Pack: $Pack -Parallel: $Parallel
        }
    }

    DeployApps $essentials
    DeployApps $other

    $time.Stop()
    Write-Host "All done in $($time.Elapsed.ToString("mm\:ss\.fff"))"
}

