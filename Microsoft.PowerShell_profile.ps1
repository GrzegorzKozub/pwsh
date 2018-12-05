Import-Module posh-git
Import-Module posh-docker

Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
    param ($commandName, $wordToComplete, $cursorPosition)
    dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, "ParameterValue", $_)
    }
}

. _rg.ps1

Get-ChildItem `
    (Split-Path $PROFILE) `
    -Filter "*-*.ps1" |
ForEach-Object { . $_.FullName }

$backgroundColor = "Black"
$separatorColor = "DarkGray"

if ($Host.PrivateData -ne $null) {
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
}

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
$GitPromptSettings.AfterText = ""
$GitPromptSettings.BeforeForegroundColor = $separatorColor
$GitPromptSettings.BeforeIndexForegroundColor = $separatorColor
$GitPromptSettings.BeforeIndexText = ""
$GitPromptSettings.BeforeText = " "
$GitPromptSettings.BranchAheadStatusForegroundColor = "DarkGreen"
$GitPromptSettings.BranchBehindAndAheadStatusForegroundColor = "DarkYellow"
$GitPromptSettings.BranchBehindStatusForegroundColor = "DarkRed"
$GitPromptSettings.BranchForegroundColor = "DarkBlue"
$GitPromptSettings.BranchGoneStatusForegroundColor = "Red"
$GitPromptSettings.BranchIdenticalStatusToForegroundColor = "DarkBlue"
$GitPromptSettings.DefaultForegroundColor = "Gray"
$GitPromptSettings.DelimForegroundColor = $separatorColor
$GitPromptSettings.DelimText = ""
$GitPromptSettings.EnableWindowTitle = ""
$GitPromptSettings.IndexForegroundColor = "DarkGreen"
$GitPromptSettings.LocalStagedStatusSymbol = ""
$GitPromptSettings.LocalWorkingStatusSymbol = ""

Clear-Variable backgroundColor
Clear-Variable separatorColor

$prompt = @{
    User = $env:USERNAME.ToLower()
    Host = $env:COMPUTERNAME.ToLower()
    UserColor = if (Test-Admin) { "DarkRed" } else { "DarkGreen" }
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

    $Host.UI.RawUI.BackgroundColor = "Black"
    $Host.UI.RawUI.ForegroundColor = "Gray"

    Write-Host $prompt.User -ForegroundColor $prompt.UserColor -NoNewLine
    Write-Host "@" -ForegroundColor "DarkGray" -NoNewLine
    Write-Host $prompt.Host -ForegroundColor "DarkYellow" -NoNewLine

    Write-Host " $path" -ForegroundColor "DarkCyan" -NoNewLine

    if ($VisualStudio) {
        Write-Host " vs" -ForegroundColor "DarkMagenta" -NoNewLine
    }

    if ($location.Provider.Name -eq "FileSystem") {
        Write-VcsStatus
    }

    Write-Host
    Write-Host ">" -ForegroundColor "DarkGray" -NoNewLine

    return " "
}

