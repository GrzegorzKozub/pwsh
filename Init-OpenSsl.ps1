function Init-OpenSsl ($RootDirectory = "demoCA") {
    New-Item -ItemType Directory -Name $RootDirectory | Out-Null

    foreach ($folder in "certs", "crl", "newcerts", "private") { 
        New-Item -ItemType Directory -Path $RootDirectory -Name $folder | Out-Null 
    }
    
    New-Item -ItemType File -Path $RootDirectory -Name "crlnumber" -Value "00" | Out-Null
    New-Item -ItemType File -Path $RootDirectory -Name "index.txt" | Out-Null
    New-Item -ItemType File -Path $RootDirectory -Name "serial" -Value "00" | Out-Null
}

Set-Alias init Init-OpenSsl
