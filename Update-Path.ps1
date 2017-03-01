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

    if ($Target -eq "Machine") {
        $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SYSTEM\CurrentControlSet\Control\Session Manager\Environment", $true)
    } else {
        $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("Environment", $true)
    }

    $path = $key.GetValue("Path", $null, "DoNotExpandEnvironmentNames")

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

    $paths = $paths | Sort-Object
    $totalPaths = $paths.Length

    function GetPathsByDir ($envVar) {
        $dir = Get-Content $("Env:\" + $envVar)
        return $paths | 
            Where-Object { $_ -like "%$envVar%*" -or $_ -like "$dir*" } |
            ForEach-Object { $_ -replace $dir.Replace("\", "\\"), "%$envVar%" }
    }

    $windowsPaths = GetPathsByDir "SystemRoot"
    $programFilesPaths = GetPathsByDir "ProgramFiles"
    $programFilesx86Paths = GetPathsByDir "ProgramFiles(x86)"
    $userProfilePaths = GetPathsByDir "USERPROFILE"

    $appsPaths = $paths | Where-Object { $_ -like "*C:\Apps\*" }

    foreach ($folder in $Diminish.Split(",") | Sort-Object) {
        $appsPaths = @() + `
            $($appsPaths | Where-Object { $_ -notlike "*\$folder*" }) + `
            $($appsPaths | Where-Object { $_ -like "*\$folder*" })
    }

    $paths = @() + $windowsPaths + $programFilesPaths + $programFilesx86Paths + $appsPaths + $userProfilePaths
    $paths = $paths | Where-Object { $_ -ne $null }

    if ($paths.Length -lt $totalPaths) {
        Write-Error "Unsupported location"
        return
    }

    $path = $paths -Join ";"

    $key.SetValue("Path", $path, "ExpandString")
    $key.Dispose()

    function GetPath ($scope) {
        return [System.Environment]::GetEnvironmentVariable("Path", $scope) 
    }

    $env:Path = $(GetPath "Machine") + ";" + $(GetPath "User")
}

Set-Alias path Update-Path
