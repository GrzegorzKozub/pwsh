function Edit-Hosts {
  Start-Process `
    -FilePath "gvim.exe" `
    -ArgumentList "C:\Windows\System32\drivers\etc\hosts" `
    -Verb RunAs
}

Set-Alias hosts Edit-Hosts

