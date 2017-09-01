function Update-Path {
    [CmdletBinding()]

    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Dir,

        [Parameter(Position = 1)]
        [ValidateSet("Machine", "User")]
        [string]
        $Target = "Machine",

        [Parameter(Position = 2)]
        [switch]
        $Remove = $false
    )

    if (!(Test-Admin)) {
        Write-Error "Must run as admin"
        return
    }

    if ($Target -eq "Machine") {
        $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SYSTEM\CurrentControlSet\Control\Session Manager\Environment", $true)
    } else {
        $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("Environment", $true)
    }

    $path = $key.GetValue("Path", $null, "DoNotExpandEnvironmentNames")

    if ($path -eq $null) {
        $script:paths = @()
    } else {
        $script:paths = @($path.Split(";") | Where-Object { $_ -ne "" })
    }

    function Normalize ($dir) {
        foreach ($envVar in "SystemRoot", "ProgramFiles(x86)", "ProgramFiles", "USERPROFILE") {
            $dir = $dir -replace (Get-Content ("Env:\" + $envVar)).Replace("\", "\\").Replace("(", "\(").Replace(")", "\)"), "%$envVar%"
        }
        return $dir
    }

    $script:paths = @($script:paths | ForEach-Object { Normalize $_ })

    $Dir = Normalize $Dir
    $Dir = $Dir.TrimEnd("\")

    $pathContainsDir = $paths -contains $Dir

    if ($Remove) {
        if (!$pathContainsDir) {
            Write-Warning "$Dir not found in $Target Path"
        } else {
            $script:paths = $script:paths | Where-Object { $_ -ne $Dir }
        }
    } else {
        if ($pathContainsDir) {
            Write-Warning "$Dir already added to $Target Path"
        } else {
            $script:paths += $Dir
        }
    }

    function ExtractPaths ($dir) {
        $matching = @()
        $remaining = @()

        foreach ($path in $script:paths) {
            if ($path -like "$dir*") {
                $matching += $path
            } else {
                $remaining += $path
            }
        }

        $script:paths = $remaining
        return $matching | Sort-Object
    }

    $windowsPaths = ExtractPaths "%SystemRoot%"
    $windowsPaths = 
        @($windowsPaths | Where-Object { $_ -eq "%SystemRoot%\system32" }) + 
        @($windowsPaths | Where-Object { $_ -ne "%SystemRoot%\system32" })

    $programFilesPaths = ExtractPaths "%ProgramFiles%"
    $programFilesX86Paths = ExtractPaths "%ProgramFiles(x86)%"
    $userProfilePaths = ExtractPaths "%USERPROFILE%"

    $appsPaths = @(ExtractPaths "C:\Apps\") + @(ExtractPaths "D:\Apps\")
    
    $otherPaths = $script:paths

    $script:paths = @() + 
        $windowsPaths +
        $programFilesPaths +
        $programFilesX86Paths +
        $appsPaths +
        $userProfilePaths +
        $otherPaths

    $script:paths = $script:paths | Get-Unique

    $path = $script:paths -Join ";"

    $key.SetValue("Path", $path, "ExpandString")
    $key.Dispose()

    function NotifySystem () {
        if (-not ("Win32.NativeMethods" -as [Type])) {
            Add-Type -Namespace "Win32" -Name "NativeMethods" -MemberDefinition @"
[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
"@
        }

        $HWND_BROADCAST = [IntPtr] 0xffff
        $WM_SETTINGCHANGE = 0x1a
        $result = [UIntPtr]::Zero

        [Win32.NativeMethods]::SendMessageTimeout($HWND_BROADCAST, $WM_SETTINGCHANGE, [UIntPtr]::Zero, "Environment", 2, 5000, [ref] $result) | Out-Null
    }

    NotifySystem

    function GetPath ($scope) {
        return [System.Environment]::GetEnvironmentVariable("Path", $scope) 
    }

    $env:Path = (GetPath "Machine") + ";" + (GetPath "User")
}

Set-Alias path Update-Path
