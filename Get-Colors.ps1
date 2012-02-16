function Get-Colors
{
    [Enum]::GetValues([ConsoleColor]) | ForEach-Object { Write-Host $_ -ForegroundColor $_ }           
}

Set-Alias colors Get-Colors
