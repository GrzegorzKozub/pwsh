function Set-VisualStudioVars {
    [CmdletBinding()]

    param (
        [Parameter(Position = 0)]
        [ValidateSet(14)]
        [int]
        $Version = 14
    )

    $path = "HKLM:SOFTWARE\"
    if ([intptr]::Size -eq 8) { $path += "Wow6432Node\" }
    $path += "Microsoft\VisualStudio\" + $Version + ".0"

    Write-Verbose "Reading settings from $path..."

    $key = Get-ItemProperty $path
    $batchFile = $key.InstallDir.Replace("IDE\", "Tools\VsDevCmd.bat")
    $command = "`"$batchFile`" & set"

    Write-Verbose "Executing $batchFile..."

    cmd /c $command | ForEach-Object {
        $varName, $varValue = $_.Split('=')
        Write-Verbose "$varName = $varValue"
        Set-Item -Path Env:$varName -Value $varValue
    }
}

Set-Alias vs Set-VisualStudioVars
