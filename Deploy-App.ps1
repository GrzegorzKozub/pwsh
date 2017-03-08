using namespace System.Collections.ObjectModel
using namespace System.Management.Automation

function Deploy-App {
    [CmdletBinding()]

    param (
        [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
        [switch]
        $Remove = $false,

        [Parameter(Position = 2, ValueFromRemainingArguments = $true)]
        [switch]
        $SkipC = $false,

        [Parameter(Position = 3, ValueFromRemainingArguments = $true)]
        [switch]
        $SkipD = $false,

        [Parameter(Position = 4, ValueFromRemainingArguments = $true)]
        [switch]
        $SkipPs1 = $false,

        [Parameter(Position = 5, ValueFromRemainingArguments = $true)]
        [switch]
        $SkipReg = $false
    )

    DynamicParam {

        $source = "D:\Dropbox\Apps"

        $values =
            Get-ChildItem -Path $source -Recurse -Include "*.zip" |
            Select-Object -ExpandProperty Name |
            Where-Object { !$_.StartsWith(".") } |
            ForEach-Object { [IO.Path]::GetFileNameWithoutExtension($_) }

        $attributes = New-Object Collection[System.Attribute]

        $parameter = New-Object ParameterAttribute
        $parameter.Mandatory = $true
        $parameter.ParameterSetName = "__AllParameterSets"
        $parameter.Position = 0
        $attributes.Add($parameter)

        $validateSet = New-Object ValidateSetAttribute($values)
        $attributes.Add($validateSet)

        $dynamicParameters = New-Object RuntimeDefinedParameterDictionary

        $dynamicParameter = New-Object RuntimeDefinedParameter("App", [string], $attributes)
        $dynamicParameters.Add("App", $dynamicParameter)

        return $dynamicParameters
    }

    Process {

        $time = [Diagnostics.Stopwatch]::StartNew()

        $installDir = "D:"
        $systemDrive = Get-Content Env:\SystemDrive

        $zip = Join-Path $source "$($PSBoundParameters.App).zip"

        Write-Host "$(if ($Remove) { "Removing" } else { "Installing" }) $zip"

        $d = @{
            temp = Join-Path $installDir ".deploying"
            apps = Join-Path $installDir "Apps"
            home = Join-Path $installDir $home.TrimStart($systemDrive)
            documents = Join-Path $installDir $home.TrimStart($systemDrive) | Join-Path -ChildPath "Documents"
            local = Join-Path $installDir $(Get-Content Env:\LOCALAPPDATA).TrimStart($systemDrive)
            roaming = Join-Path $installDir $(Get-Content Env:\APPDATA).TrimStart($systemDrive)
        }

        $c = @{
            c = Join-Path $systemDrive "\"
            apps = Join-Path $systemDrive "Apps"
            shortcuts = Join-Path $(Get-Content Env:\ProgramData) "Start Menu\Programs"
            startup = Join-Path $home "Start Menu\Programs\Startup"
        }

        function CreateDir ($dir) {
            if (Test-Path $dir) { return }
            New-Item $dir -ItemType Directory | Out-Null
        }

        CreateDir $d.apps
        CreateDir $d.home
        CreateDir $d.documents
        CreateDir $d.local
        CreateDir $d.roaming

        function CreateSymlink ($symlink, $path, $isDir = $true) {
            if (Test-Path $symlink) { return }
            Write-Host "Symlink $symlink"
            cmd /c mklink $(if ($isDir) { "/J" } else { "" }) $symlink $path | Out-Null
        }

        function RemoveSymlink ($symlink, $isDir = $true) {
            Write-Host "Unlink $symLink"
            if ($isDir) {
                try { [IO.Directory]::Delete($symlink, $true) } catch { } # https://github.com/PowerShell/PowerShell/issues/621
            } else {
                Remove-Item $symlink -ErrorAction SilentlyContinue
            }
        }

        New-Item $d.temp -ItemType Directory | Out-Null
        
        $7z = Get-Command 7z -ErrorAction SilentlyContinue
        
        if ($7z) {
            Write-Host "Extract with 7-Zip"
            7z x $zip -y -o"$($d.temp)" | Out-Null
        } else {
            Expand-Archive $zip $d.temp
        }

        $package = $(Get-ChildItem $d.temp)[0].FullName

        function Process ($category, $path, $replace = $true, $createSymlinks = $true) {

            $isC = $path.StartsWith($systemDrive)

            $categoryPath = Join-Path $package $category
            $deviceCategoryPath = $categoryPath + "@" + $(Get-Content Env:\COMPUTERNAME)
            if (Test-Path $deviceCategoryPath) { $categoryPath = $deviceCategoryPath }

            foreach ($item in Get-ChildItem $categoryPath -ErrorAction SilentlyContinue) {

                $fullPath = Join-Path $path $item.Name

                if (($isC -and !$SkipC) -or (!$isC -and !$SkipD)) {
                    if ($Remove -or $replace) {
                        Write-Host "Remove $fullPath"
                        Remove-Item $fullPath -Recurse -Force -ErrorAction SilentlyContinue
                    }
                    if (!$Remove) { 
                        Write-Host "Create $fullPath"
                        Move-Item $item.FullName $path -Force -ErrorAction SilentlyContinue
                    }
                }

                if (!$SkipC -and $createSymlinks) {
                    $symlink = Join-Path $systemDrive $fullPath.TrimStart($installDir)
                    $isDir = $item.Attributes -eq "Directory"
                    RemoveSymlink $symlink $isDir
                    if (!$Remove) {
                        CreateSymlink $symlink $fullPath $isDir
                    }
                }
            }
        }

        Process "apps" $d.apps $true $false
        Process "home" $d.home
        Process "documents" $d.documents
        Process "local" $d.local
        Process "roaming" $d.roaming

        Process "c" $c.c $false $false
        Process "shortcuts" $c.shortcuts $false $false
        Process "startup" $c.startup $false $false

        $script = if ($Remove) { "remove" } else { "install" }

        if (!$SkipPs1) {
            $ps1 = Join-Path $package "$script.ps1"
            if (Test-Path $ps1) {
                Write-Host "Run $ps1"
                & $ps1
            }
        }

        if (!$SkipReg) {
            $reg = Join-Path $package "$script.reg"
            if (Test-Path $reg) {
                Write-Host "Import $reg"
                Start-Process -FilePath "regedit.exe" -ArgumentList "/s", """$reg""" -Wait
            }
        }

        ie4uinit -show

        Remove-Item $d.temp -Recurse -Force

        $time.Stop()

        Write-Host "Done in $($time.Elapsed.ToString("mm\:ss\.fff"))"
    }
}

Set-Alias deploy Deploy-App

