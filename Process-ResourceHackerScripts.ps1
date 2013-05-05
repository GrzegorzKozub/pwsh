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

    $reshacker = Get-Command reshacker -ErrorAction SilentlyContinue
    
    if ($reshacker) {
        Write-Verbose "Using Resource Hacker located at $($reshacker.Definition)."
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

        reshacker -Script $resourceHackerScript
        Wait-Process -Name reshacker

        $logFileName = $executableFileName.Replace(".exe", ".log")

        if (Get-Content $logFileName | Select-String "Commands completed") {
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

Set-Alias prhs Process-ResourceHackerScripts

