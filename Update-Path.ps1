function Update-Path {
    [CmdletBinding()]

    param (
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("User", "Machine")]
        [string]
        $Target = "User",

        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Value,

        [Parameter(Position = 2)]
        [switch]
        $Delete = $false
    )

    $path = [Environment]::GetEnvironmentVariable("Path", $Target)
    $pathArray = $path.Split(";")

    if (!$Value) {
        $pathArray
        return
    }

    $Value = $Value.TrimEnd("\")
    $valueExists = $pathArray | Where-Object { $_ -eq $Value }

    if ($Delete) {
        if (!$valueExists) {
            Write-Error "The value $Value does not exist in the $Target scope Path environment variable."
            return
        }

        $pathArray = $pathArray | Where-Object { $_ -ne $Value }

    } else {
        if ($valueExists) {
            Write-Error "The value $Value already exists in the $Target scope Path environment variable."
            return
        }

        $pathArray += $Value
    }

    $windows = Get-Content Env:SystemRoot
    $programFiles = Get-Content Env:ProgramFiles
    $programFilesx86 = Get-Content Env:"ProgramFiles(x86)"
    $common = "C:\Common"
    $programs = "C:\Programs"
    $user = Get-Content Env:Home

    $windowsPaths = $pathArray | Where-Object { $_ -like "*$windows\*" -or $_ -eq $windows }
    $programFilesPaths = $pathArray | Where-Object { $_ -like "*$programFiles\*" } | Sort-Object
    $programFilesx86Paths = $pathArray | Where-Object { $_ -like "*$programFilesx86\*" } | Sort-Object
    $commonPaths = $pathArray | Where-Object { $_ -eq $common }
    $programsPaths = $pathArray | Where-Object { $_ -like "*$programs\*" } | Sort-Object
    $userPaths = $pathArray | Where-Object { $_ -like "*$user\*" } | Sort-Object

    $pathArray = @() + $windowsPaths + $programFilesPaths + $programFilesx86Paths + $commonPaths + $programsPaths + $userPaths
    $path = $( $pathArray | Where-Object { $_ -ne $null } ) -Join ";"

    [Environment]::SetEnvironmentVariable("Path", $path, $Target)
}

Set-Alias path Update-Path
