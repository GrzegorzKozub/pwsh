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
    
    # initialize configuration

    $configFile = "Generate-Certificate.config"
    
    if (!(Test-Path $configFile)) {
        $config = [xml] @"
            <config>
                <rootCa>
                    <filename>RootCA</filename>
                    <subject>
                        <c>PL</c>
                        <st>mazowieckie</st>
                        <l>Warszawa</l>
                        <o>Hewlett-Packard</o>
                        <ou>BS ITO Software Services</ou>
                        <cn>Test Root CA</cn>
                        <e>grzegorz.kozub@hp.com</e>
                    </subject>
                </rootCa>
                <subCa>
                    <filename>SubCA</filename>
                    <subject>
                        <c>PL</c>
                        <st>mazowieckie</st>
                        <l>Warszawa</l>
                        <o>Hewlett-Packard</o>
                        <ou>BS ITO Software Services</ou>
                        <cn>Test Sub CA</cn>
                        <e>grzegorz.kozub@hp.com</e>
                    </subject>
                </subCa>
                <certificate>
                    <filename>Certificate</filename>
                    <subject>
                        <c>PL</c>
                        <st>mazowieckie</st>
                        <l>Warszawa</l>
                        <o>Hewlett-Packard</o>
                        <ou>BS ITO Software Services</ou>
                        <cn>Test Certificate</cn>
                        <e>grzegorz.kozub@hp.com</e>
                    </subject>
                </certificate>
            </config>
"@
        $config.Save($configFile)
        
        Write-Host "The $configFile file was created. Modify it now, if required, then press any key to continue..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown")
    }
    
    # read configuration
    
    Write-Verbose "Reading configuration from the $configFile file."

    $config = New-Object xml
    $config.Load($configFile)
    
    $rootCaFilename = $config.config.rootCa.filename
    $subCaFilename = $config.config.subCa.filename
    $certificateFilename = $config.config.certificate.filename
    
    $subjectPattern = "/countryName={0}/stateOrProvinceName={1}/localityName={2}/organizationName={3}/organizationalUnitName={4}/commonName={5}/emailAddress={6}/"
    
    $rootCaSubject = $config.config.rootCa.subject
    $rootCaSubject = [string]::Format($subjectPattern, $rootCaSubject.c, $rootCaSubject.st, $crootCaSubject.l, $rootCaSubject.o, $rootCaSubject.ou, $rootCaSubject.cn, $rootCaSubject.e)
    
    $subCaSubject = $config.config.subCa.subject
    $subCaSubject = [string]::Format($subjectPattern, $subCaSubject.c, $subCaSubject.st, $csubCaSubject.l, $subCaSubject.o, $subCaSubject.ou, $subCaSubject.cn, $subCaSubject.e)
   
    $certificateSubject = $config.config.certificate.subject
    $certificateSubject = [string]::Format($subjectPattern, $certificateSubject.c, $certificateSubject.st, $ccertificateSubject.l, $certificateSubject.o, $certificateSubject.ou, $certificateSubject.cn, $certificateSubject.e)

    # generate the root CA certificate and key
    # Write-Verbose

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
