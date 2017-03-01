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

    $totalPaths = $paths.Length

    $systemRoot = "%SystemRoot%"
    $windows = Get-Content Env:SystemRoot
    $programFiles = Get-Content Env:ProgramFiles
    $programFilesx86 = Get-Content Env:"ProgramFiles(x86)"
    $apps = "C:\Apps"
    $userProfile = Get-Content Env:USERPROFILE

    $windowsPaths = $paths | Where-Object { $_ -like "$systemRoot*" -or $_ -like "$windows*" }
    $programFilesPaths = $paths | Where-Object { $_ -like "*$programFiles\*" } | Sort-Object
    $programFilesx86Paths = $paths | Where-Object { $_ -like "*$programFilesx86\*" } | Sort-Object
    $appsPaths = $paths | Where-Object { $_ -like "*$apps\*" } | Sort-Object
    $userProfilePaths = $paths | Where-Object { $_ -like "*$userProfile\*" } | Sort-Object

    $windowsPaths = $windowsPaths | ForEach-Object { $_ -replace $windows.Replace("\", "\\"), $systemRoot }

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

    $key.SetValue("Path", $path, "ExpandString")
    $key.Dispose()

    function GetPath ($scope) {
        return [System.Environment]::GetEnvironmentVariable("Path", $scope) 
    }

    $env:Path = $(GetPath "Machine") + ";" + $(GetPath "User")
}

Set-Alias path Update-Path
