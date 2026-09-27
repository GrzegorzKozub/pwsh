# disable smart app control
sudo {
  Set-ItemProperty `
    -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy" `
    -Name "VerifiedAndReputablePolicyState" `
    -Value 0 `
    -Force
  "" | CiTool.exe --refresh | Out-Null
}
Start-Sleep -Seconds 1
