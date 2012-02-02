param (
    [string]$BuildSqlScript = $(Read-Host -Prompt "Give me the path to your build SQL script"),
    [string]$TfsSqlsFolder = $(Read-Host -Prompt "Give me the path to your TFS repository SQLs"), 
    [switch]$Simulate
)

Write-Host

if (-Not $Simulate)
{
    Write-Host "WARNING!"
    Write-Host "I will Check Out and remove GRANTs (not the ones with REFERENCES) from" 
    Write-Host "each SQL in your TFS-mapped folder that is also in your build SQL script."    
    Write-Host
    
    $goAhead = $(Read-Host -Prompt "You sure you want me to do that? [y/n]")
    
    if ($goAhead -Eq "n")
    {
        Write-Host "You've changed your mind."
        Write-Host
        return
    }
}
else
{
    Write-Host "Simulation mode. Will merely list the SQLs that would be updated."    
}

Write-Host

foreach ($sqlFile in $(Get-ChildItem $TfsSqlsFolder -Recurse -Filter *.sql))
{
    $pattern = "^\s*(GRANT)\s+(?!REFERENCES).*$"

    if ((Select-String -Path $BuildSqlScript -Pattern "\\${sqlFile}" -Quiet) -And `
        (Select-String -Path $sqlFile -Pattern $pattern -Quiet)) 
    {
        $dirty = $True
        
        if ($Simulate)
        {
            Write-Host "${sqlFile}"
            continue
        }
    
        Write-Host "Checking out ${sqlFile}..."
        
        & "c:\Program Files (x86)\Microsoft Visual Studio 10.0\Common7\IDE\TF.exe" checkout $sqlFile.FullName > $Null
        
        Write-Host "Removing GRANTs from ${sqlFile}..."
        
        (Get-Content $sqlFile.FullName) |  
        Foreach-Object { if ($_ -IMatch $pattern) { "-- $_" } else { $_ } } | 
        Set-Content $sqlFile.FullName

        Write-Host "Done updating ${sqlFile}."
    }
}

if ($dirty)
{
    if (-Not $Simulate)
    {
        Write-Host
        Write-Host "I've made some changes."
        Write-Host "Be sure to manually Check In the updated SQLs inside Visual Studio."    
    }    
}
else
{
    Write-Host "No changes, luckily."
}

Write-Host

