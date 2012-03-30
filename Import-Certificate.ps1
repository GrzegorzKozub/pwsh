function Import-Certificate
{
    [CmdletBinding()]

    Param (
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("CurrentUser", "LocalMachine")]
        [ValidateScript({Test-Path cert:\$_\$StoreName})]
        [string]
        $StoreLocation,
        
        [Parameter(Position = 1, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("AddressBook", "AuthRoot", "CertificateAuthority", "Disallowed", "My", "Root", "TrustedPeople", "TrustedPublisher")]
        [ValidateScript({Test-Path cert:\$StoreLocation\$_})]
        [string]
        $StoreName,
        
        [Parameter(Position = 2, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_})]
        [System.IO.FileInfo]
        $CertificateFile,
        
        [Parameter(Position = 3)]
        [string]
        $CertificatePassword
    )
    
    Begin 
    {
        [void][System.Reflection.Assembly]::LoadWithPartialName("System.Security")
    }
    
    Process 
    {
        try
        {
            if (!(Test-Path $CertificateFile.FullName))
            {
                $CertificateFile = New-Object System.IO.FileInfo $(Join-Path -Path $PWD.ProviderPath -ChildPath $CertificateFile)
            }
            
            $certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $CertificateFile, $CertificatePassword
            $store = New-Object System.Security.Cryptography.X509Certificates.X509Store $StoreName, $StoreLocation
            
            $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
            $store.Add($certificate)
            
            Write-Verbose "Imported certificate $CertificateFile to store $StoreName at location $StoreLocation."
        }
        catch
        {
            Write-Error -Message $_ -ErrorAction Stop
        }
        finally
        {
            if ($store -ne $null)
            {
                $store.Close()
            }
        }
    }
    
    End 
    { }
}