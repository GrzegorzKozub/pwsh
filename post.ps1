& (Join-Path -Path $PSScriptRoot -ChildPath "accent.ps1")
& (Join-Path -Path $PSScriptRoot -ChildPath "wall.ps1")

# smart app control

sudo {
  Set-ItemProperty `
    -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy" `
    -Name "VerifiedAndReputablePolicyState" `
    -Value 0 `
    -Force
  "" | CiTool.exe --refresh | Out-Null
}
