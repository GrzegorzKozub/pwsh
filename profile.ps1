$null = New-PSDrive -Name Script -PSProvider FileSystem -Root $(Split-Path $Profile)

$MaximumHistoryCount = 1024

. Script:\Get-Colors.ps1
. Script:\Run-Elevated.ps1
. Script:\Set-VisualStudioVars.ps1

Import-Module posh-git
