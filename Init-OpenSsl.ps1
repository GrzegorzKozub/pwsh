$ca = "demoCA"
New-Item -ItemType Directory -Name $ca | Out-Null

$folders = "certs", "crl", "newcerts", "private"
foreach ($folder in $folders) { New-Item -ItemType Directory -Path $ca -Name $folder | Out-Null } 

New-Item -ItemType File -Path $ca -Name "index.txt" | Out-Null
New-Item -ItemType File -Path $ca -Name "serial" -Value "00" | Out-Null
New-Item -ItemType File -Path $ca -Name "crlnumber" -Value "00" | Out-Null