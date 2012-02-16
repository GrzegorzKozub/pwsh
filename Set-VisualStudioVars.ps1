function Set-VisualStudioVars($version = "10.0")
{
    if ([intptr]::Size -eq 8)
    {
        $registryKeyPath = "HKLM:SOFTWARE\Wow6432Node\Microsoft\VisualStudio\" + $version
    }
    else
    {
        $registryKeyPath = "HKLM:SOFTWARE\Microsoft\VisualStudio\" + $version
    }

    $registryKey = Get-ItemProperty $registryKeyPath
    $batchFilePath = $registryKey.InstallDir.Replace("IDE\", "Tools\vsvars32.bat")
    $command = "`"$batchFilePath`" & set"
    
    cmd /c $command | ForEach-Object { $varName, $varValue = $_.Split('='); Set-Item -Path Env:$varName -Value $varValue }
}

Set-Alias vs Set-VisualStudioVars
