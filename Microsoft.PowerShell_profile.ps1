$backgroundColor = "Black"
$separatorColor = "DarkGray"

$Host.PrivateData.DebugBackgroundColor = $backgroundColor
$Host.PrivateData.DebugForegroundColor = "Magenta"
$Host.PrivateData.ErrorBackgroundColor = $backgroundColor
$Host.PrivateData.ErrorForegroundColor = "Red"
$Host.PrivateData.ProgressBackgroundColor = "DarkGray"
$Host.PrivateData.ProgressForegroundColor = "White"
$Host.PrivateData.VerboseBackgroundColor = $backgroundColor
$Host.PrivateData.VerboseForegroundColor = "Cyan"
$Host.PrivateData.WarningBackgroundColor = $backgroundColor
$Host.PrivateData.WarningForegroundColor = "Yellow"

$GitPromptSettings.AfterForegroundColor = $separatorColor
$GitPromptSettings.AfterText = ")"
$GitPromptSettings.BeforeForegroundColor = $separatorColor
$GitPromptSettings.BeforeIndexForegroundColor = $separatorColor
$GitPromptSettings.BeforeIndexText = ""
$GitPromptSettings.BeforeText = " ("
$GitPromptSettings.BranchAheadForegroundColor = "DarkGreen"
$GitPromptSettings.BranchBehindForegroundColor = "DarkRed"
$GitPromptSettings.BranchBehindAndAheadForegroundColor = "DarkYellow"
$GitPromptSettings.BranchForegroundColor = "DarkBlue"
$GitPromptSettings.DefaultForegroundColor = "Gray"
$GitPromptSettings.DelimForegroundColor = $separatorColor
$GitPromptSettings.DelimText = ""
$GitPromptSettings.EnableWindowTitle = ""
$GitPromptSettings.IndexForegroundColor = "DarkGreen"
$GitPromptSettings.UntrackedForegroundColor = "DarkYellow"
$GitPromptSettings.UntrackedText = " *"
$GitPromptSettings.WorkingForegroundColor = "DarkRed"

Clear-Variable backgroundColor
Clear-Variable separatorColor

$prompt = @{}
$prompt.User = $env:USERNAME.ToLower()
$prompt.Host = $env:COMPUTERNAME.ToLower()
$prompt.UserColor = "DarkGreen"

foreach ($group in $($([Security.Principal.WindowsIdentity]::GetCurrent()).Groups)) {
    if ($($group.Translate([Security.Principal.SecurityIdentifier])).IsWellKnown([Security.Principal.WellKnownSidType]::BuiltinAdministratorsSid)) {
        $prompt.UserColor = "DarkRed"
        break
    }
}

function Prompt {

	$stackLevel = (Get-Location -Stack).Count
	$location = (Get-Location).Path

    if ($location -eq $Home) {
		$location = "~"
	} elseif ($location.Length -ge 64) {
		$location = $location.Substring($location.LastIndexOf("\") + 1, $location.Length - $location.LastIndexOf("\") - 1)
	}

	$Host.UI.RawUI.WindowTitle = "$location"

	Write-Host $prompt.User -ForegroundColor $prompt.UserColor -NoNewLine
	Write-Host "@" -ForegroundColor "DarkGray" -NoNewLine
	Write-Host $prompt.Host -ForegroundColor "DarkYellow" -NoNewLine

    if ($stackLevel -gt 0) {
		Write-Host " $stackLevel" -ForegroundColor "DarkMagenta" -NoNewLine
	}

	Write-Host " $location" -ForegroundColor "DarkCyan" -NoNewLine

    if ($location.Path -ne "cert:\") {
		Write-VcsStatus
	}

    Write-Host
    Write-Host ">" -ForegroundColor "DarkGray" -NoNewLine

	return " "
}
