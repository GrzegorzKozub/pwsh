$MaximumHistoryCount = 32767

$historyFile = Join-Path $HOME "WindowsPowerShellHistory.xml"
Register-EngineEvent PowerShell.Exiting { Get-History -Count $MaximumHistoryCount | Group-Object CommandLine | ForEach-Object { $_.Group[0] } | Export-Clixml $historyFile } -SupportEvent

if (Test-Path $historyFile) {
    Import-CliXml $historyFile | Add-History 
}

Push-Location
cd $(Split-Path $PROFILE)

. .\Attach-Image.ps1
. .\Encrypt-Config.ps1
. .\Generate-Certificate.ps1
. .\Import-Certificate.ps1
. .\Set-Proxy.ps1
. .\Set-VisualStudioVars.ps1
. .\Ssd-Game.ps1
. .\Update-Path.ps1

Pop-Location

Import-Module posh-git
