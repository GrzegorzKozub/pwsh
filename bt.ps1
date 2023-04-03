if ([Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains "S-1-5-32-544") {
  &btop
} else {
  Start-Process `
    -Verb "RunAs" `
    -FilePath "wt" `
    -ArgumentList "new-tab", "pwsh", "-Command", "btop"
}

