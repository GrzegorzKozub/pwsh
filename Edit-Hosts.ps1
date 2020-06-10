function Edit-Hosts {
  Start-Process `
    -FilePath "gvim.exe" `
    -ArgumentList (Join-Path $env:SystemRoot "System32\drivers\etc\hosts") `
    -Verb RunAs
}

Set-Alias hosts Edit-Hosts

