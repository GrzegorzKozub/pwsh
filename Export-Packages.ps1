function Export-Packages {
    [CmdletBinding()]

    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [string]
        $To
    )

    function Log ($from, $to) {
        Write-Host "Mirror " -NoNewLine
        Write-Host $from -NoNewLine -ForegroundColor DarkCyan
        Write-Host " to " -NoNewLine
        Write-Host $to -ForegroundColor DarkCyan
    }

    function Mirror ($from, $to) {
        Log $from $to
        $robocopy = Start-Process `
            -FilePath "robocopy.exe" `
            -ArgumentList $from, $to, "/MIR", "/R:3", "/W:5", "/NOOFFLOAD", "/J", "/NP", "/NDL" `
            -WindowStyle Hidden `
            -PassThru `
            -Wait
        if ($robocopy.ExitCode -gt 3) {
            throw "Robocopy finished with $($robocopy.ExitCode)"
        }
    }

    function CreateCopy ($from, $to) {
        Log $from $to
        New-Item -Path ([IO.Path]::GetDirectoryName($to)) -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
        Copy-Item $from $to
    }

    $dropbox = "D:\Dropbox"

    $autoHotkeyGit = "Git\AutoHotkey.git"
    $windowsPowerShellGit = "Git\WindowsPowerShell.git"
    $packages = "Packages"
    $packagesPs1 = "Windows\packages.ps1"

    Mirror (Join-Path $dropbox $autoHotkeyGit) (Join-Path $To $autoHotkeyGit)
    Mirror (Join-Path $dropbox $windowsPowerShellGit) (Join-Path $To $windowsPowerShellGit)
    Mirror (Join-Path $dropbox $packages) (Join-Path $To $packages)
    CreateCopy (Join-Path $dropbox $packagesPs1) (Join-Path $To $packagesPs1)
}

