function Generate-Certificate {
    [CmdletBinding()]

    param (

    )
    
    # check for OpenSSL availability
    
    $openssl = Get-Command openssl -ErrorAction SilentlyContinue
    
    if ($openssl) {
        Write-Verbose "Using OpenSSL located at $($openssl.Definition)."
    } else {
        Write-Error "OpenSSL is not accessible using the PATH environment variable or a PowerShell alias."
        return
    }
    
    # initialize the OpenSSL database
    
    $openSslDatabase = "demoCA"
    
    if (!(Test-Path $openSslDatabase)) {
        Write-Verbose "Initializing the OpenSSL database in $openSslDatabase directory."
        
        New-Item -ItemType Directory -Name $openSslDatabase | Out-Null

        foreach ($folder in "certs", "crl", "newcerts", "private") { 
            New-Item -ItemType Directory -Path $openSslDatabase -Name $folder | Out-Null 
        }

        New-Item -ItemType File -Path $openSslDatabase -Name "crlnumber" -Value "00" | Out-Null
        New-Item -ItemType File -Path $openSslDatabase -Name "index.txt" | Out-Null
        New-Item -ItemType File -Path $openSslDatabase -Name "serial" -Value "00" | Out-Null
    }

    return
    
    # generate the root CA certificate and key
    openssl req -new -x509 -days 3650 -out RootCA.cer -keyout RootCA.key -subj /countryName="PL"/stateOrProvinceName="mazowieckie"/localityName="Warsaw"/organizationName="Hewlett-Packard"/organizationalUnitName="BS ITO Software Services"/commonName="Test Root CA"/emailAddress="grzegorz.kozub@hp.com"/
    # generate the subordinate CA certificate request and key
    openssl req -new -out SubCA.req -keyout SubCA.key -subj /countryName="PL"/stateOrProvinceName="mazowieckie"/localityName="Warsaw"/organizationName="Hewlett-Packard"/organizationalUnitName="BS ITO Software Services"/commonName="Test Sub CA"/emailAddress="grzegorz.kozub@hp.com"/
    # sign the subordinate CA with the root CA key
    openssl ca -days 3650 -extensions v3_ca -cert RootCA.cer -keyfile RootCA.key -in SubCA.req -out SubCA.cer
    # generate the certificate request
    openssl req -new -out Certificate.req -keyout Certificate.key -subj /countryName="PL"/stateOrProvinceName="mazowieckie"/localityName="Warsaw"/organizationName="Hewlett-Packard"/organizationalUnitName="BS ITO Software Services"/commonName="Test certificate"/emailAddress="grzegorz.kozub@hp.com"/
    # sign the certificate request with the subordinate CA key
    openssl ca -days 3650 -cert SubCA.cer -keyfile SubCA.key -in Certificate.req -out Certificate.cer
    # convert the certificate to PKCS#12 format
    openssl pkcs12 -export -inkey Certificate.key -in Certificate.cer -out Certificate.pfx
    # revoke the certificate
    openssl ca -cert SubCA.cer -keyfile SubCA.key -revoke Certificate.cer
    # enerate the CRL for the subordinate CA
    openssl ca -cert SubCA.cer -keyfile SubCA.key -gencrl -out SubCA.crl
    # revoke the subordinate CA
    openssl ca -cert RootCA.cer -keyfile RootCA.key -revoke SubCA.cer
    # generate the CRL for the root CA
    openssl ca -cert RootCA.cer -keyfile RootCA.key -gencrl -out RootCA.crl   
}

Set-Alias generate Generate-Certificate
