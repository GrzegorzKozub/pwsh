$MaximumHistoryCount = 32767

$historyFile = Join-Path $HOME "WindowsPowerShellHistory.xml"
Register-EngineEvent PowerShell.Exiting { 
    Get-History -Count $MaximumHistoryCount |
    Group-Object CommandLine |
    ForEach-Object { $_.Group[0] } |
    Export-Clixml $historyFile 
} -SupportEvent

if (Test-Path $historyFile) {
    Import-CliXml $historyFile | Add-History 
}

Get-ChildItem $(Join-Path $(Split-Path $PROFILE) *.ps1) `
    -Exclude $(Split-Path $PROFILE.CurrentUserAllHosts -Leaf), $(Split-Path $PROFILE.CurrentUserCurrentHost -Leaf) |
    ForEach-Object { . $_ }

Import-Module posh-git
