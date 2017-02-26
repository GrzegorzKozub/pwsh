function Update-Path {
    [CmdletBinding()]

    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Dir,

        [Parameter(Position = 1)]
        [ValidateSet("Machine", "User")]
        [string]
        $Target = "Machine",

        [Parameter(Position = 2)]
        [switch]
        $Remove = $false,

        [Parameter(Position = 3)]
        [string]
        $Diminish = "Git"
    )

    $rapidee = Get-Command rapidee -ErrorAction SilentlyContinue
    
    if (!$rapidee) {
        Write-Error "Rapid Environment Editor not found"
        return
    }

    $path = [Environment]::GetEnvironmentVariable("Path", $Target)
    $paths = @()

    if ($path -ne $null) {
        $paths = @() + $($path.Split(";") | Where-Object { $_ -ne $null -and $_ -ne "" })
    }

    $Dir = $Dir.TrimEnd("\")
    $valueExists = $paths | Where-Object { $_ -eq $Dir }

    if ($Remove) {
        if (!$valueExists) {
            Write-Warning "$Dir not found in $Target Path"
            return
        }

        $paths = $paths | Where-Object { $_ -ne $Dir }

    } else {
        if ($valueExists) {
            Write-Warning "$Dir already added to $Target Path"
            return
        }

        $paths += $Dir
    }

    $totalPaths = $paths.Length

    $windows = Get-Content Env:SystemRoot
    $programFiles = Get-Content Env:ProgramFiles
    $programFilesx86 = Get-Content Env:"ProgramFiles(x86)"
    $apps = "C:\Apps"
    $userProfile = Get-Content Env:USERPROFILE

    $windowsPaths = $paths | Where-Object { $_ -like "*$windows\*" -or $_ -eq $windows }
    $programFilesPaths = $paths | Where-Object { $_ -like "*$programFiles\*" } | Sort-Object
    $programFilesx86Paths = $paths | Where-Object { $_ -like "*$programFilesx86\*" } | Sort-Object
    $appsPaths = $paths | Where-Object { $_ -like "*$apps\*" } | Sort-Object
    $userProfilePaths = $paths | Where-Object { $_ -like "*$userProfile\*" } | Sort-Object

    $windowsPaths = $windowsPaths | ForEach-Object { $_ -replace $windows.Replace("\", "\\"), "%SystemRoot%" }

    foreach ($folder in $Diminish.Split(",") | Sort-Object) {
        $appsPaths = @() + $($appsPaths | Where-Object { $_ -notlike "*\$folder*" }) + $($appsPaths | Where-Object { $_ -like "*\$folder*" })
    }

    $paths = @() + $windowsPaths + $programFilesPaths + $programFilesx86Paths + $appsPaths + $userProfilePaths
    $paths = $paths | Where-Object { $_ -ne $null }

    if ($paths.Length -lt $totalPaths) {
        Write-Error "Unsupported location"
        return
    }

    $path = $paths -Join ";"

    if ($Target -eq "Machine") {
        Start-Process -FilePath "$($rapidee.Definition)" -ArgumentList "-s", "-e", "-m", "Path", """$path""" -Wait
    } else {
        Start-Process -FilePath "$($rapidee.Definition)" -ArgumentList "-s", "-e", "Path", """$path""" -Wait
    }
}

Set-Alias path Update-Path
