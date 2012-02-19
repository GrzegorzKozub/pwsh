function Attach-Image
{
    [CmdletBinding()]
    
    Param (
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_})]
        [String]
        $ImagePath,
        
        [Parameter(Position = 1)]
        [Switch]
        $Detach = $false
    )

    $path = $env:TEMP + "\" + [Guid]::NewGuid().Guid + ".txt"
    
    if ($Detach)
    {
        $action = "detach vdisk"
    }
    else
    {
        $action = "attach vdisk"
    }
    
    ("select vdisk file=" + $ImagePath + [Environment]::NewLine + $action) | Out-File -FilePath $path -Encoding "UTF8"
    diskpart /s $path > $null
    Remove-Item -Path $path
}

Set-Alias attach Attach-Image
