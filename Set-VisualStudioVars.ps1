function Set-VisualStudioVars($Version = "10.0")
{
    if ([intptr]::Size -eq 8)
    {
        $path = "HKLM:SOFTWARE\Wow6432Node\Microsoft\VisualStudio\" + $Version
    }
    else
    {
        $path = "HKLM:SOFTWARE\Microsoft\VisualStudio\" + $Version
    }

    $key = Get-ItemProperty $path
    $batchFile = $key.InstallDir.Replace("IDE\", "Tools\vsvars32.bat")
    $command = "`"$batchFile`" & set"
    
    cmd /c $command | ForEach-Object { $varName, $varValue = $_.Split('='); Set-Item -Path Env:$varName -Value $varValue }
}

Set-Alias vs Set-VisualStudioVars
