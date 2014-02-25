function Reset-ExplorerWindows {
    $keys = (
        "HKCU:\Software\Microsoft\Windows\Shell\BagMRU", 
        "HKCU:\Software\Microsoft\Windows\Shell\Bags", 
        "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\BagMRU", 
        "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags"
    )

    foreach ($key in $keys) {
        Remove-Item -Path $key -Recurse -ErrorAction SilentlyContinue
    }
}

Set-Alias rew Reset-ExplorerWindows

