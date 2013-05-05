function Import-Certificate {
    [CmdletBinding()]

    param (
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("CurrentUser", "LocalMachine")]
        [ValidateScript({Test-Path cert:\$_\$StoreName})]
        [string]
        $StoreLocation = "CurrentUser",
        
        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("AddressBook", "AuthRoot", "CertificateAuthority", "Disallowed", "My", "Root", "TrustedPeople", "TrustedPublisher")]
        [ValidateScript({Test-Path cert:\$StoreLocation\$_})]
        [string]
        $StoreName = "My",
        
        [Parameter(Position = 2, Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_})]
        [System.IO.FileInfo]
        $CertificateFile,
        
        [Parameter(Position = 3)]
        [string]
        $CertificatePassword
    )
    
    begin {
        [void][System.Reflection.Assembly]::LoadWithPartialName("System.Security")
        
        try {
            $store = New-Object System.Security.Cryptography.X509Certificates.X509Store $StoreName, $StoreLocation
            $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
        } catch {
            Write-Error -Message $_ -ErrorAction Stop
        }
        
        Write-Verbose "Opened certificate store $StoreName for $StoreLocation."
    }
    
    process {
        try {
            if (!(Test-Path $CertificateFile.FullName)) {
                $CertificateFile = New-Object System.IO.FileInfo $(Join-Path -Path $PWD.ProviderPath -ChildPath $CertificateFile)
            }
            
            $certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $CertificateFile, $CertificatePassword
            $store.Add($certificate)
            
            Write-Verbose "Imported certificate $CertificateFile."
        } catch {
            Write-Error -Message $_ -ErrorAction Continue
        }
    }
    
    end { 
        if ($store -ne $null) {
            $store.Close()
        }
    }
}

Set-Alias impcert Import-Certificate
