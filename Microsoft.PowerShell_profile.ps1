$BackgroundColor = "Black"
$Host.PrivateData.ErrorForegroundColor = "Red"
$Host.PrivateData.ErrorBackgroundColor = $BackgroundColor
$Host.PrivateData.WarningForegroundColor = "Magenta"
$Host.PrivateData.WarningBackgroundColor = $BackgroundColor
$Host.PrivateData.DebugForegroundColor = "Yellow"
$Host.PrivateData.DebugBackgroundColor = $BackgroundColor
$Host.PrivateData.VerboseForegroundColor = "Cyan"
$Host.PrivateData.VerboseBackgroundColor = $BackgroundColor
$Host.PrivateData.ProgressForegroundColor = "White"
$Host.PrivateData.ProgressBackgroundColor = "DarkGray"

function Prompt {
	$userColor = "DarkGreen"
    
	foreach ($group in $($([Security.Principal.WindowsIdentity]::GetCurrent()).Groups)) {
		if ($($group.Translate([Security.Principal.SecurityIdentifier])).IsWellKnown([Security.Principal.WellKnownSidType]::BuiltinAdministratorsSid)) {
			$userColor = "DarkRed"
		}
	}
    
	$userName = $env:USERNAME.ToLower()
	$hostName = $env:COMPUTERNAME.ToLower()
	$history = @(Get-History)
	
    if ($history.Count -gt 0) {
		$history = $history[$history.Count - 1].Id
	}
	
    $history = ($history + 1)
	$nestedHeight = $NestedPromptLevel
	$stackHeight = (Get-Location -Stack).Count
	$location = $(Get-Location)
	$Host.UI.RawUI.WindowTitle = $location
	
    if ($location.Path -eq $Home) {
		$location = "~"
	}
	
    if ($location.Path.Length -ge 40) {
		$location = $location.Path
		$location = $location.Substring($location.LastIndexOf("\") + 1, $location.Length - $location.LastIndexOf("\") - 1) 
	}
    
	Write-Host "$userName" -ForegroundColor $userColor -NoNewLine
	Write-Host "@" -ForegroundColor Gray -NoNewLine
	Write-Host "$hostName" -ForegroundColor DarkYellow -NoNewLine
	Write-Host " $history" -ForegroundColor Blue -NoNewLine
	
    if ($nestedHeight -gt 0) {
		Write-Host " $nestedHeight" -ForegroundColor DarkMagenta -NoNewLine	
	}
	
    if ($stackHeight -gt 0) {
		Write-Host " $stackHeight" -ForegroundColor DarkCyan -NoNewLine
	}
    
	Write-Host " $location" -ForegroundColor Green -NoNewLine
    
    if ($location.Path -ne "cert:\") {
		Write-VcsStatus
	}
    
	return " "
}
