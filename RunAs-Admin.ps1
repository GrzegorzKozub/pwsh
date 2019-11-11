function RunAs-Admin {
  [CmdletBinding()]

  param (
    [Parameter(Position = 0, Mandatory = $true)]
    [ScriptBlock]
    $Cmd
  )

  if (Test-Admin) {
    Invoke-Command -ScriptBlock $Cmd
  } else {
    Start-Process `
      -FilePath "powershell" `
      -Verb "RunAs" `
      -ArgumentList @"
        -NoLogo
        -Command
        & {Set-Location $(Get-Location); $($Cmd.ToString()); Read-Host -Prompt 'Press Enter to close this window...'}
"@
  }
}

Set-Alias sudo RunAs-Admin

