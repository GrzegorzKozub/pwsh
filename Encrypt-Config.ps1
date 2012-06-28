function Encrypt-Config {
    [CmdletBinding()]

    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateNotNullOrEmpty()] 
        [string] 
        $ExecutablePath,

        [Parameter(Position = 1, Mandatory = $true)] 
        [ValidateNotNullOrEmpty()] 
        [string] 
        $ConfigSectionName,

        [Parameter(Position = 2)]
        [string] 
        $ConfigSectionGroupName,
        
        [Parameter(Position = 3)] 
        [ValidateSet("DataProtectionConfigurationProvider", "RSAProtectedConfigurationProvider")] 
        [string] 
        $DataProtectionProvider = "DataProtectionConfigurationProvider"
    )
 
    [void] [Reflection.Assembly]::Load("System.Configuration, Version=2.0.0.0, Culture=Neutral, PublicKeyToken=b03f5f7f11d50a3a")
 
    $config = [System.Configuration.ConfigurationManager]::OpenExeConfiguration($ExecutablePath)
    
    if ($ConfigSectionGroupName -ne "") {
        $configSectionGroup = $config.GetSectionGroup($ConfigSectionGroupName)
        $configSection = $configSectionGroup.Sections[$ConfigSectionName]
    } else {
        $configSection = $config.GetSection($ConfigSectionName)
    }
    
    $sectionInformation = $configSection.SectionInformation

    if (-not $sectionInformation.IsProtected) {
        Write-Host "Encrypting $ConfigSectionName inside $ExecutablePath.config..."
        $sectionInformation.ProtectSection($DataProtectionProvider)
    } else {
        Write-Host "Decrypting $ConfigSectionName inside $ExecutablePath.config..."
        $sectionInformation.UnprotectSection()
    }

    $sectionInformation.ForceSave = [System.Boolean]::True
    $config.Save([System.Configuration.ConfigurationSaveMode]::Modified)
}

Set-Alias encrypt Encrypt-Config

