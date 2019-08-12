function Install-Wsl {
  Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Windows-Subsystem-Linux"
}

Set-Alias wsl Install-Wsl

