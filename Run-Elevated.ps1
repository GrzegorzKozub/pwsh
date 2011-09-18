function Run-Elevated
{
    param($Command = $(throw "The CommandName parameter was not specified."), $Parameters)

    $processStartInfo = New-Object System.Diagnostics.ProcessStartInfo $Command
    $processStartInfo.Arguments = $Parameters
    $processStartInfo.Verb = "runas"
    
    [System.Diagnostics.Process]::Start($processStartInfo)    
}

Set-Alias elevate Run-Elevated