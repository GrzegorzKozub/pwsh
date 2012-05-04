function Ssd-Game {
    [CmdletBinding()]

    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $GameFolder,

        [Parameter(Position = 1)]
        [switch]
        $CleanUp = $false
    )

    if (!(Get-Command junction -ErrorAction SilentlyContinue)) {
        Write-Error "The junction command is not accessible using the PATH environment variable or a PowerShell alias."
        return
    }

    $hddPaths = "d:\Games\Steam\steamapps\common\", `
                "d:\Games\Origin\games\", `
                "d:\Games\"

    $ssdPath = "c:\Games\"

    if (!(Test-Path $ssdPath)) {
        Write-Error "The $ssdPath folder does not exist."
        return
    }

    foreach ($hddPath in $hddPaths) {
        if (Test-Path $hddPath$GameFolder) {
            $source = $hddPath+$GameFolder
            $backup = $source+".original"
            $gameFolderValid = $true
            break
        }
    }

    if (!$gameFolderValid) {
        Write-Error "The $GameFolder folder was not found in the known HDD game locations."
        return
    }

    $destination = $ssdPath+$GameFolder

    if ((!$CleanUp -and ((Test-Path $destination) -or (Test-Path $backup))) -or ($CleanUp -and !((Test-Path $destination) -and (Test-Path $backup)))) {
        Write-Error "Inconsistent source, destination and backup folder states. The -CleanUp switch was $(if ($CleanUp) {'on'} else {'off'})."
        return
    }

    if (!$CleanUp) {
        Copy-Item -Path $source -Destination $destination -Recurse -ErrorAction Stop
        Rename-Item -Path $source -NewName $backup -ErrorAction Stop
        junction $source $destination | Out-Null
    } else {
        junction -d $source | Out-Null
        Rename-Item -Path $backup -NewName $source -ErrorAction Stop
        Remove-Item -Path $destination -Recurse -ErrorAction Stop
    }
}

Set-Alias ssd Ssd-Game
