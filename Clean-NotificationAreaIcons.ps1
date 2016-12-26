function Clean-NotificationAreaIcons {
    Stop-Process -Name "explorer"
    foreach ($value in "IconStreams", "PastIconsStream") {
        Remove-ItemProperty `
            -Name $value `
            -Path "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\TrayNotify" `
            -ErrorAction SilentlyContinue
    }
}

