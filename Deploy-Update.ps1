Import-Module Admin

function Deploy-Update {
  param (
    [switch] $Parallel
  )

  AssertRunningAsAdmin

  $time = [Diagnostics.Stopwatch]::StartNew()

  foreach ($app in $(Get-ChildItem -Path "D:\Apps" -Directory -Name)) {
    Deploy-App -App $app -Update -Parallel: $Parallel
  }

  $time.Stop()
  Write-Host "All done in $($time.Elapsed.ToString("mm\:ss\.fff"))" -ForegroundColor DarkGray
}

Set-Alias update Deploy-Update

