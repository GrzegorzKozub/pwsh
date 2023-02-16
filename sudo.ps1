param (
  [ValidateNotNullOrEmpty()] [ScriptBlock] $Cmd
)

if (RunningAsAdmin) {
  Invoke-Command -ScriptBlock $Cmd
} else {
  Start-Process `
    -FilePath "powershell" `
    -Verb "RunAs" `
    -ArgumentList @"
      -NoLogo
      -Command
      & {Set-Location $(Get-Location); $($Cmd.ToString()); Write-Host 'Press any key...'; `$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') | Out-Null }
"@
}

