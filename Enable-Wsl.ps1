function Enable-Wsl {
  Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Windows-Subsystem-Linux"
}

