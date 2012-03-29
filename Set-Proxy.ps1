function Set-Proxy
{
    [CmdletBinding()]
    
    Param (
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Off", "Automatic", "Manual")]
        [string]
        $Configuration
    )

    $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    $autoConfigUrl = "http://autocache.hp.com/"
    $proxyServer = "bbnwebcachevip2.bastion.europe.hp.com:8080"
    $proxyOverride = "127.0.0.1;localhost;*.eds.com;*.hp.com;*.hp.net;*.hpqcorp.net;*.cpqcorp.net;*.hpshopping.com;130.177.*"
    
    switch ($Configuration)
    {   
        "Off"
        {
            Set-ItemProperty -Path $path -Name ProxyEnable -Value 0
            Remove-ItemProperty -Path $path -Name AutoConfigURL -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $path -Name ProxyServer -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $path -Name ProxyOverride -Value "<local>"
        }
        "Automatic"
        {
            Set-ItemProperty -Path $path -Name ProxyEnable -Value 0
            Set-ItemProperty -Path $path -Name AutoConfigURL -Value $autoConfigUrl
            Remove-ItemProperty -Path $path -Name ProxyServer -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $path -Name ProxyOverride -Value "<local>"
        }
        "Manual"
        {
            Set-ItemProperty -Path $path -Name ProxyEnable -Value 1
            Remove-ItemProperty -Path $path -Name AutoConfigURL -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $path -Name ProxyServer -Value $proxyServer
            Set-ItemProperty -Path $path -Name ProxyOverride -Value ($proxyOverride + ";<local>")
        }
    }
}

Set-Alias proxy Set-Proxy
