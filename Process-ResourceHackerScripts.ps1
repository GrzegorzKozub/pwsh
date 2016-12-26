function Process-ResourceHackerScripts {
    [CmdletBinding()]

    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ExecutablesLocation,

        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ResourcesLocation = ".\Resources",

        [Parameter(Position = 2)]
        [ValidateNotNullOrEmpty()]
        [switch]
        $LeaveLogs = $false
    )

    $resourceHacker = Get-Command ResourceHacker -ErrorAction SilentlyContinue
    
    if ($resourceHacker) {
        Write-Verbose "Using Resource Hacker located at $($resourceHacker.Definition)."
    } else {
        Write-Error "Resource Hacker is not accessible using the PATH environment variable or a PowerShell alias."
        return
    }

    foreach ($resourceHackerScript in Get-ChildItem $ResourcesLocation"\*.ini") {
        $executableFileName = [IO.Path]::GetFileNameWithoutExtension($resourceHackerScript) + ".exe"
        Write-Verbose "Processing $executableFileName..."

        Copy-Item $ExecutablesLocation"\"$executableFileName $ResourcesLocation"\"$executableFileName

        Push-Location
        Set-Location $ResourcesLocation

        Start-Process -FilePath "$($resourceHacker.Definition)" -ArgumentList "-Script $($resourceHackerScript)" -Wait

        $logFileName = $executableFileName.Replace(".exe", ".log")

        if (Get-Content $logFileName | Select-String -Pattern "S.?u.?c.?c.?e.?s.?s.?!") {
            if (!$LeaveLogs) {
                Remove-Item $logFileName
            }
        } else {
            Write-Error "Resource Hacker has encountered errors. Examine $logFileName for details."
        }

        Pop-Location

        Move-Item $ExecutablesLocation"\"$executableFileName $ExecutablesLocation"\"$executableFileName".original" -Force
        Move-Item $ResourcesLocation"\"$executableFileName $ExecutablesLocation -Force
    }
}

