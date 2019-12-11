function RunningAsAdmin {
  return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

function AssertRunningAsAdmin {
  if (!(RunningAsAdmin)) {
    Write-Error "Must run as admin"
    break
  }
}
