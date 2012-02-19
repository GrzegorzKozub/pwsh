$MaximumHistoryCount = 32767

$historyFile = Join-Path $HOME "WindowsPowerShellHistory.xml"
Register-EngineEvent PowerShell.Exiting { Get-History | group CommandLine | foreach { $_.group[0] } | Export-CliXml $historyFile } -SupportEvent

if (Test-Path $historyFile) 
{ 
    Import-CliXml $historyFile | Add-History 
}

Push-Location
cd $(Split-Path $PROFILE)

. .\Get-Colors.ps1
. .\Optimize-Processes.ps1
. .\Set-Proxy.ps1
. .\Set-VisualStudioVars.ps1

Pop-Location

Import-Module posh-git
