$backgroundColor = "Black"
$separatorColor = "DarkGray"

$Host.PrivateData.DebugBackgroundColor = $backgroundColor
$Host.PrivateData.DebugForegroundColor = "DarkGray"
$Host.PrivateData.ErrorBackgroundColor = $backgroundColor
$Host.PrivateData.ErrorForegroundColor = "DarkRed"
$Host.PrivateData.ProgressBackgroundColor = "DarkGray"
$Host.PrivateData.ProgressForegroundColor = "White"
$Host.PrivateData.VerboseBackgroundColor = $backgroundColor
$Host.PrivateData.VerboseForegroundColor = "Gray"
$Host.PrivateData.WarningBackgroundColor = $backgroundColor
$Host.PrivateData.WarningForegroundColor = "DarkYellow"

Set-PSReadlineOption `
    -ContinuationPromptForegroundColor DarkGray `
    -EmphasisForegroundColor Yellow `
    -ErrorForegroundColor DarkRed

Set-PSReadlineOption -TokenKind Command -ForegroundColor DarkYellow
Set-PSReadlineOption -TokenKind Comment -ForegroundColor DarkGray
Set-PSReadlineOption -TokenKind Keyword -ForegroundColor DarkBlue
Set-PSReadlineOption -TokenKind Member -ForegroundColor Gray
Set-PSReadlineOption -TokenKind None -ForegroundColor Gray
Set-PSReadlineOption -TokenKind Number -ForegroundColor White
Set-PSReadlineOption -TokenKind Operator -ForegroundColor DarkCyan
Set-PSReadlineOption -TokenKind Parameter -ForegroundColor DarkGray
Set-PSReadlineOption -TokenKind String -ForegroundColor DarkGreen
Set-PSReadlineOption -TokenKind Type -ForegroundColor Blue
Set-PSReadlineOption -TokenKind Variable -ForegroundColor DarkMagenta

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

$prompt = @{
    User = $env:USERNAME.ToLower()
    Host = $env:COMPUTERNAME.ToLower()
    UserColor = "DarkGreen"
}

foreach ($group in ([Security.Principal.WindowsIdentity]::GetCurrent()).Groups) {
    if (($group.Translate([Security.Principal.SecurityIdentifier])).IsWellKnown([Security.Principal.WellKnownSidType]::BuiltinAdministratorsSid)) {
        $prompt.UserColor = "DarkRed"
        break
    }
}

function Prompt {

    $location = Get-Location
	$path = $location.Path

    if ($path -eq $Home) {
		$path = "~"
	} elseif ($path.Length -ge 64) {
		$path = $path.Substring($path.LastIndexOf("\") + 1, $path.Length - $path.LastIndexOf("\") - 1)
	}

	$Host.UI.RawUI.WindowTitle = "$path"

	Write-Host $prompt.User -ForegroundColor $prompt.UserColor -NoNewLine
	Write-Host "@" -ForegroundColor "DarkGray" -NoNewLine
	Write-Host $prompt.Host -ForegroundColor "DarkYellow" -NoNewLine

	Write-Host " $path" -ForegroundColor "DarkCyan" -NoNewLine

    if ($location.Provider.Name -eq "FileSystem") {
		Write-VcsStatus
	}

    Write-Host
    Write-Host ">" -ForegroundColor "DarkGray" -NoNewLine

	return " "
}
