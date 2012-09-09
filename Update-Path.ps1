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

    $valueExists = $pathArray | Where-Object { $_ -eq $Value }

    if ($Delete) {
        if (!$valueExists) {
            Write-Error "The value $Value does not exist in the $Target scope Path environment variable."
            return
        }
        
        $path = $( $pathArray | Where-Object { $_ -ne $Value } ) -Join ";"

    } else {
        if ($valueExists) {
            Write-Error "The value $Value already exists in the $Target scope Path environment variable."
            return
        }

        $path = $path + ";" + $Value
    }

    [Environment]::SetEnvironmentVariable("Path", $path, $Target)
}

Set-Alias path Update-Path
