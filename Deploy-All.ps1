function Deploy-All {
    [CmdletBinding()]
    
    param (
        [Parameter(Position = 0)]
        [switch]
        $Remove = $false,

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
        $SkipReg = $false
    )

    if (!(Test-Admin)) {
        Write-Error "Must run as admin"
        return
    }

    $essentials = "7-Zip", "Git"

    $other = "Chrome",
             "clink",
             "Common",
             "ConEmu",
             "dotnet",
             "Dropbox",
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
             "Visual Studio Code"

    $device = Get-Content Env:\COMPUTERNAME

    if ($device -eq "Slut") {
        $other = $other + "NVIDIA" + "NVIDIA Inspector"
    }

    if ($device -eq "Drifter") {
        $other = $other + "MaxxAudioPro"
    }

    function Process ($apps) {
        foreach ($app in $apps) {
            Deploy-App -App $app -Remove: $Remove -SkipC: $SkipC -SkipD: $SkipD -SkipPs1: $SkipPs1 -SkipReg: $SkipReg
        }
    }

    Process $essentials
    Process $other
}

