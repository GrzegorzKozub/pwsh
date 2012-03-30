$MaximumHistoryCount = 32767

$historyFile = Join-Path $HOME "WindowsPowerShellHistory.xml"
Register-EngineEvent PowerShell.Exiting { Get-History -Count $MaximumHistoryCount | Group-Object CommandLine | ForEach-Object { $_.Group[0] } | Export-Clixml $historyFile } -SupportEvent

if (Test-Path $historyFile) 
{ 
    Import-CliXml $historyFile | Add-History 
}

Push-Location
cd $(Split-Path $PROFILE)

. .\Attach-Image.ps1
. .\Import-Certificate.ps1
. .\Optimize-Processes.ps1
. .\Set-Proxy.ps1
. .\Set-VisualStudioVars.ps1

Pop-Location

Import-Module posh-git
