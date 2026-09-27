# disable smart app control

$policy = "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy"
$state = "VerifiedAndReputablePolicyState"

if ((Get-ItemProperty -Path $policy -Name $state).$state -eq 0) {
  return
}

sudo {
  Set-ItemProperty -Path $args[0] -Name $args[1] -Value 0 -Force
  "" | CiTool.exe --refresh | Out-Null
} -args @($policy, $state)

Start-Sleep -Seconds 1
