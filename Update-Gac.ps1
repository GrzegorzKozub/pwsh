function Update-Gac {
    Set-Alias ngen (Join-Path ([System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()) ngen.exe)

    [AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.Location -ne $null } | ForEach-Object {
        $assemblyName = Split-Path $_.Location -Leaf
        if ([System.Runtime.InteropServices.RuntimeEnvironment]::FromGlobalAccessCache($_)) {
            Write-Host "Already in Native Images Cache: $assemblyName."
        } else {
            Write-Host "Generating native images for: $assemblyName."
            ngen $_.Location | ForEach-Object { "`t$_" }
        }
    }
}

Set-Alias ugac Update-Gac
