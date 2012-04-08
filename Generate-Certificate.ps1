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
    
    if (!(Test-Path $configFile)) {
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
                        <o>Hewlett-Packard</o>
                        <ou>BS ITO Software Services</ou>
                        <cn>Test Root CA</cn>
                        <e>grzegorz.kozub@hp.com</e>
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
                        <o>Hewlett-Packard</o>
                        <ou>BS ITO Software Services</ou>
                        <cn>Test Sub CA</cn>
                        <e>grzegorz.kozub@hp.com</e>
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
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp")
    }
    
    # read configuration
    
    Write-Verbose "Reading configuration from the $configFile file."

    $config = New-Object xml
    $config.Load($configFile)
    
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

    $certificateFilename = $config.config.certificate.filename
    $certificateValidForDays = $config.config.certificate.validForDays
    $certificateKeyPassword = $config.config.certificate.keyPassword
    $certificateExportPassword = $config.config.certificate.exportPassword
    $certificateSubject = $config.config.certificate.subject
    $certificateSubject = [string]::Format($subjectPattern, $certificateSubject.c, $certificateSubject.st, $certificateSubject.l, $certificateSubject.o, $certificateSubject.ou, $certificateSubject.cn, $certificateSubject.e)
    
    # setup file extensions

    $cer = ".cer"
    $key = ".key"
    $pfx = ".crl"
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

    if (!$certificateFilename -or !$certificateValidForDays -or !$certificateKeyPassword -or !$certificateExportPassword -or !$certificateSubject) {
        Write-Error "The $configFile file is missing required certificate settings."
        return
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
        $caAdjective = "subordinate"
    } else {
        $caFilename = $rootCaFilename
        $caKeyPassword = $rootCaKeyPassword
        $caAdjective = "root"
    }

    # generate the certificate

    Write-Verbose "Generating the certificate request."
    openssl req -new -out $certificateFilename$req -keyout $certificateFilename$key -subj $certificateSubject -passout pass:$certificateKeyPassword

    Write-Verbose "Signing the certificate request with the $caAdjective CA key."
    openssl ca -days $certificateValidForDays -batch -cert $caFilename$cer -keyfile $caFilename$key -passin pass:$caKeyPassword -in $certificateFilename$req -out $certificateFilename$cer

    Write-Verbose "Converting the certificate to PKCS#12 format."
    openssl pkcs12 -export -in $certificateFilename$cer -inkey $certificateFilename$key -passin pass:$certificateKeyPassword -out $certificateFilename$pfx -passout pass:$certificateExportPassword

    # generate the CRL

    if ($UseSubCa -and $RevokeSubCa) {
        Write-Verbose "Revoking the subordinate CA."
        openssl ca -cert $rootCaFilename$cer -keyfile $rootCaFilename$key -passin pass:$rootCaKeyPassword -revoke $subCaFilename$cer

        Write-Verbose "Generating the CRL for the root CA."
        openssl ca -cert $rootCaFilename$cer -keyfile $rootCaFilename$key -passin pass:$rootCaKeyPassword -gencrl -out $rootCaFilename$crl   
    }

    if ($RevokeCertificate) {
        Write-Verbose "Revoking the certificate."
        openssl ca -cert $caFilename$cer -keyfile $caFilename$key -passin pass:$caKeyPassword -revoke $certificateFilename$cer

        Write-Verbose "Generating the CRL for the $caAdjective CA."
        openssl ca -cert $caFilename$cer -keyfile $caFilename$key -passin pass:$caKeyPassword -gencrl -out $caFilename$crl
    }
}

Set-Alias generate Generate-Certificate
