function Set-VisualStudioEnvironment {
    if ($VisualStudio -ne $null) {
        Write-Error "Visual Studio environment already set for $VisualStudio edition"
        return
    }

    $vsPath = Join-Path ${Env:ProgramFiles(x86)} "Microsoft Visual Studio\2019"

    if (!(Test-Path $vsPath)) {
        Write-Error "Visual Studio not found"
        return
    }

    $editionPrios = "Enterprise", "Professional", "Community"
    $foundEditions = @() + (Get-ChildItem $vsPath -Directory -Name)

    foreach ($prio in $editionPrios) {
        foreach ($found in $foundEditions) {
            if ($found -eq $prio) {
                $edition = $found
                break
            }
        }
    }

    if (!$edition) {
        Write-Error "Could not select edition"
        return
    }

    $batPath = Join-Path (Join-Path $vsPath $edition) "Common7\Tools\VsDevCmd.bat"
    $tempPath = [IO.Path]::GetTempFileName()
    cmd /c "`"$batPath`" && set > `"$tempPath`"" | Out-Null

    foreach ($command in (Get-Content $tempPath)) {
        if ($command -match "^(.*?)=(.*)$") {
            Set-Content "Env:\$($matches[1])" $matches[2]
        }
    }

    Remove-Item $tempPath
    $global:VisualStudio = $edition
}

Set-Alias vs Set-VisualStudioEnvironment

