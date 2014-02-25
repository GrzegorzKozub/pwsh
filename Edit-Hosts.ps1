function Edit-Hosts {
    Start-Process -FilePath "gvim.exe" -ArgumentList "--cmd ""let g:signify_disable_by_default = 1""", "C:\Windows\System32\drivers\etc\hosts" -Verb RunAs
}

Set-Alias hosts Edit-Hosts

