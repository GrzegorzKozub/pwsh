function Reset-DialogPaths {
    Remove-Item `
        -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32" `
        -Recurse `
        -ErrorAction SilentlyContinue
}

