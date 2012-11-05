function Generate-Certificate {
    [CmdletBinding()]

    param (
        [Parameter()]
        [switch]
        $DontGenerateRootCa,

        [Parameter()]
        [switch]
        $UseSubCa,

        [Parameter()]
        [switch]
        $DontGenerateSubCa,

        [Parameter()]
        [switch]
        $RevokeSubCa,

        [Parameter()]
        [switch]
        $RevokeCertificate
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
    $configFilePath = Join-Path (Get-Location -PSProvider FileSystem).Path $configFile
    
    if (!(Test-Path $configFilePath)) {
        $config = [xml] @"
            <config>
                <rootCa>
                    <filename>RootCA</filename>
                    <validForDays>365</validForDays>
                    <keyPassword>pass</keyPassword>
                    <subject>
                        <c>PL</c>
                        <st>mazowieckie</st>
                        <l>Warszawa</l>
                        <o>Apsis</o>
                        <ou>Developers</ou>
                        <cn>Test Root CA</cn>
                        <e>grzegorz.kozub@apsis.com</e>
                    </subject>
                </rootCa>
                <subCa>
                    <filename>SubCA</filename>
                    <validForDays>365</validForDays>
                    <keyPassword>pass</keyPassword>
                    <subject>
                        <c>PL</c>
                        <st>mazowieckie</st>
                        <l>Warszawa</l>
                        <o>Apsis</o>
                        <ou>Developers</ou>
                        <cn>Test Sub CA</cn>
                        <e>grzegorz.kozub@apsis.com</e>
                    </subject>
                </subCa>
                <certificate>
                    <filename>Certificate</filename>
                    <validForDays>365</validForDays>
                    <keyPassword>pass</keyPassword>
                    <exportPassword>pass</exportPassword>
                    <subject>
                        <c>PL</c>
                        <st>mazowieckie</st>
                        <l>Warszawa</l>
                        <o>Apsis</o>
                        <ou>Developers</ou>
                        <cn>Test Certificate</cn>
                        <e>grzegorz.kozub@apsis.com</e>
                    </subject>
                </certificate>              
            </config>
"@
        $config.Save($configFilePath)
        
        Write-Host "The $configFile file was created. Modify it now, if required, then press any key to continue..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp")
    }

    # read configuration
    
    Write-Verbose "Reading configuration from the $configFile file."

    $config = [xml] (Get-Content $configFilePath)
    
    $subjectPattern = "/countryName={0}/stateOrProvinceName={1}/localityName={2}/organizationName={3}/organizationalUnitName={4}/commonName={5}/emailAddress={6}/"

    $rootCaFilename = $config.config.rootCa.filename
    $rootCaValidForDays = $config.config.rootCa.validForDays
    $rootCaKeyPassword = $config.config.rootCa.keyPassword
    $rootCaSubject = $config.config.rootCa.subject
    $rootCaSubject = [string]::Format($subjectPattern, $rootCaSubject.c, $rootCaSubject.st, $rootCaSubject.l, $rootCaSubject.o, $rootCaSubject.ou, $rootCaSubject.cn, $rootCaSubject.e)    

    if ($UseSubCa) {
        $subCaFilename = $config.config.subCa.filename
        $subCaValidForDays = $config.config.subCa.validForDays
        $subCaKeyPassword = $config.config.subCa.keyPassword
        $subCaSubject = $config.config.subCa.subject
        $subCaSubject = [string]::Format($subjectPattern, $subCaSubject.c, $subCaSubject.st, $subCaSubject.l, $subCaSubject.o, $subCaSubject.ou, $subCaSubject.cn, $subCaSubject.e)
    }

    $certificates = $config.config.certificate

    foreach ($c in $certificates) {
        $c.subject.InnerText = [string]::Format($subjectPattern, $c.subject.c, $c.subject.st, $c.subject.l, $c.subject.o, $c.subject.ou, $c.subject.cn, $c.subject.e)
    }

    # setup file extensions

    $cer = ".cer"
    $crl = ".crl"
    $key = ".key"
    $pfx = ".pfx"
    $req = ".req"

    # validate configuration

    if (!$rootCaFilename -or !$rootCaValidForDays -or !$rootCaKeyPassword -or !$rootCaSubject) {
        Write-Error "The $configFile file is missing required root CA settings."
        return
    }

    if ($DontGenerateRootCa -and !($(Test-Path $rootCaFilename$cer) -and $(Test-Path $rootCaFilename$key))) {
        Write-Error "If DontGenerateRootCa is set, the $rootCaFilename$cer and $rootCaFilename$key files must exist."
        return
    }

    if ($UseSubCa) {
        if (!$subCaFilename -or !$subCaValidForDays -or !$subCaKeyPassword -or !$subCaSubject) {
            Write-Error "The $configFile file is missing required subordinate CA settings."
            return
        }

        if ($DontGenerateSubCa -and !($(Test-Path $subCaFilename$cer) -and $(Test-Path $subCaFilename$key))) {
            Write-Error "If DontGenerateSubCa is set, the $subCaFilename$cer and $subCaFilename$key files must exist."
            return
        }        
    }

    foreach ($c in $certificates) {
        if (!$c.filename -or !$c.validForDays -or !$c.keyPassword -or !$c.exportPassword -or !$c.subject) {
            Write-Error "The $configFile file is missing required certificate settings."
            return
        }
    }

    # generate the CA

    if (!$DontGenerateRootCa) {
        Write-Verbose "Generating the root CA certificate and key."
        openssl req -new -x509 -days $rootCaValidForDays -out $rootCaFilename$cer -keyout $rootCaFilename$key -subj $rootCaSubject -passout pass:$rootCaKeyPassword
    }

    if ($UseSubCa) {
        if (!$DontGenerateSubCa) {
            Write-Verbose "Generating the subordinate CA certificate request and key."
            openssl req -new -out $subCaFilename$req -keyout $subCaFilename$key -subj $subCaSubject -passout pass:$subCaKeyPassword
    
            Write-Verbose "Signing the subordinate CA with the root CA key."
            openssl ca -days $subCaValidForDays -extensions v3_ca -batch -cert $rootCaFilename$cer -keyfile $rootCaFilename$key -passin pass:$rootCaKeyPassword -in $subCaFilename$req -out $subCaFilename$cer
        }

        $caFilename = $subCaFilename
        $caKeyPassword = $subCaKeyPassword
        $caKind = "subordinate"
    } else {
        $caFilename = $rootCaFilename
        $caKeyPassword = $rootCaKeyPassword
        $caKind = "root"
    }

    # generate the certificate

    foreach ($c in $certificates) {
        Write-Verbose "Generating the certificate request for $($c.filename)."
        openssl req -new -out ($c.filename+$req) -keyout ($c.filename+$key) -subj $c.subject -passout "pass:$($c.keyPassword)"
        
        Write-Verbose "Signing the certificate request with the $caKind CA key."
        openssl ca -days $c.validForDays -batch -cert $caFilename$cer -keyfile $caFilename$key -passin pass:$caKeyPassword -in ($c.filename+$req) -out ($c.filename+$cer)

        Write-Verbose "Converting the certificate to PKCS#12 format."
        openssl pkcs12 -export -in ($c.filename+$cer) -inkey ($c.filename+$key) -passin "pass:$($c.keyPassword)" -out ($c.filename+$pfx) -passout "pass:$($c.exportPassword)"
    }
   
    # generate the CRL

    if ($UseSubCa -and $RevokeSubCa) {
        Write-Verbose "Revoking the subordinate CA."
        openssl ca -cert $rootCaFilename$cer -keyfile $rootCaFilename$key -passin pass:$rootCaKeyPassword -revoke $subCaFilename$cer

        Write-Verbose "Generating the CRL for the root CA."
        openssl ca -cert $rootCaFilename$cer -keyfile $rootCaFilename$key -passin pass:$rootCaKeyPassword -gencrl -out $rootCaFilename$crl   
    }

    if ($RevokeCertificate) {
        foreach ($c in $certificates) {
            Write-Verbose "Revoking the certificate $($c.filename)."
            openssl ca -cert $caFilename$cer -keyfile $caFilename$key -passin pass:$caKeyPassword -revoke ($c.filename+$cer)
        }

        Write-Verbose "Generating the CRL for the $caKind CA."
        openssl ca -cert $caFilename$cer -keyfile $caFilename$key -passin pass:$caKeyPassword -gencrl -out $caFilename$crl
    }
}

Set-Alias generate Generate-Certificate
