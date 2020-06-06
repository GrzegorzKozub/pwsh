function Update-Resources {
  param (
    [ValidateNotNullOrEmpty()] [string] $ExeDir,
    [ValidateNotNullOrEmpty()] [string] $ResourceDir = ".\resources"
  )

  $resourceHacker = Get-Command "resourcehacker.exe" -ErrorAction SilentlyContinue

  if (!$resourceHacker) {
    Write-Error "Resource Hacker not found"
    return
  }

  foreach ($script in Get-ChildItem $ResourceDir"\*.ini") {
    $exeFile = [IO.Path]::GetFileNameWithoutExtension($script) + ".exe"

    Copy-Item $ExeDir"\"$exeFile $ResourceDir"\"$exeFile

    Push-Location
    Set-Location $ResourceDir

    Start-Process -FilePath "$($resourceHacker.Definition)" -ArgumentList "-Script $($script)" -Wait

    $logFile = $exeFile.Replace(".exe", ".log")

    if (Get-Content $logFile | Select-String -Pattern "S.?u.?c.?c.?e.?s.?s.?!") {
      Remove-Item $logFile
    } else {
      Write-Error "Resource Hacker failed; see $logFile"
    }

    Pop-Location

    Move-Item $ExeDir"\"$exeFile $ExeDir"\"$exeFile".original" -Force
    Move-Item $ResourceDir"\"$exeFile $ExeDir -Force
  }
}

