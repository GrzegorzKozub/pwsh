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

    $essentials = "7-Zip", "Git", "Windows"

    $other = "Chrome",
             "clink",
             "Common",
             "ConEmu",
             "dotnet",
             "Dropbox",
             "GnuWin",
             "IrfanView",
             "KeePass",
             "MinGW",
             "Node.Js",
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
        $other = $other + "NVIDIA Inspector"
    }

    if ($device -eq "XPS") {
        $other = $other + "MaxxAudioPro" + "ThrottleStop"
    }

    function Process ($apps) {
        foreach ($app in $apps) {
            Deploy-App -App $app -Remove: $Remove -SkipC: $SkipC -SkipD: $SkipD -SkipPs1: $SkipPs1 -SkipReg: $SkipReg
        }
    }

    Process $essentials
    Process $other
}

