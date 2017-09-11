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
        $SkipReg = $false,

        [Parameter(Position = 6, ValueFromRemainingArguments = $true)]
        [switch]
        $Pack = $false
    )

    DynamicParam {

        $source = "D:\Dropbox\Packages"

        $values =
            Get-ChildItem -Path $source -Recurse -Include "*.zip" |
            Select-Object -ExpandProperty Name |
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

        if ($Remove -and $Pack) {
            Write-Error "Can either remove or pack"    
            return
        }

        if (!(Test-Admin)) {
            Write-Error "Must run as admin"
            return
        }

        $time = [Diagnostics.Stopwatch]::StartNew()

        $installDir = "D:"
        $systemDrive = Get-Content Env:\SystemDrive

        $zip = Join-Path $source "$($PSBoundParameters.App).zip"

        Write-Host "$(if ($Remove) { "Removing" } elseif ($Pack) { "Packing" } else { "Installing" }) $zip"

        $d = @{
            packages = Join-Path $installDir "Packages"
            apps = Join-Path $installDir "Apps"
            home = Join-Path $installDir $home.TrimStart($systemDrive)
            documents = Join-Path $installDir $home.TrimStart($systemDrive) | Join-Path -ChildPath "Documents"
            local = Join-Path $installDir (Get-Content Env:\LOCALAPPDATA).TrimStart($systemDrive)
            roaming = Join-Path $installDir (Get-Content Env:\APPDATA).TrimStart($systemDrive)
        }

        $c = @{
            c = Join-Path $systemDrive "\"
            apps = Join-Path $systemDrive "Apps"
            shortcuts = Join-Path (Get-Content Env:\ProgramData) "Microsoft\Windows\Start Menu\Programs"
            startup = Join-Path (Get-Content Env:\APPDATA) "Microsoft\Windows\Start Menu\Programs\Startup"
        }

        function CreateDir ($dir) {
            if (Test-Path $dir) { return }
            New-Item $dir -ItemType Directory | Out-Null
        }

        CreateDir $d.packages
        CreateDir $d.apps
        CreateDir $d.home
        CreateDir $d.documents
        CreateDir $d.local
        CreateDir $d.roaming

        $7z = Get-Command 7z -ErrorAction SilentlyContinue

        function ExtractPackage () {
            if ($7z) {
                Write-Host "Extract with 7-Zip to $package"
                7z x $zip -y -o"$($d.packages)" | Out-Null
            } else {
                Write-Host "Expand to $package"
                Expand-Archive $zip $d.packages
            }
        }

        function RemovePackage () {
            Write-Host "Remove $package"
            Remove-Item $package -Recurse -Force
        }

        $package = Join-Path $d.packages ([IO.Path]::GetFileNameWithoutExtension($zip))

        if (Test-Path $package) {
            if (!$Remove -and !$Pack) {
                RemovePackage
                ExtractPackage
            }
        } else {
            ExtractPackage
        }

        function CreateCopy ($from, $to, $isDir) {
            if ($isDir) {
                xcopy $from $to /EYKHRIQ | Out-Null
            } else {
                xcopy $from ([IO.Path]::GetDirectoryName($to)) /YKHRQ | Out-Null
            }
        }

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

        function Process ($category, $path, $replace = $true, $createSymlinks = $true) {

            $isC = $path.StartsWith($systemDrive)

            $categoryPath = Join-Path $package $category
            $deviceCategoryPath = $categoryPath + "@" + (Get-Content Env:\COMPUTERNAME)
            if (Test-Path $deviceCategoryPath) { $categoryPath = $deviceCategoryPath }

            foreach ($item in Get-ChildItem $categoryPath -Force -ErrorAction SilentlyContinue) {

                $fullPath = Join-Path $path $item.Name
                $isDir = $item.Attributes.HasFlag([IO.FileAttributes]::Directory)

                if (($isC -and !$SkipC) -or (!$isC -and !$SkipD)) {
                    if (!$Pack -and ($Remove -or $replace)) {
                        Write-Host "Remove $fullPath"
                        Remove-Item $fullPath -Recurse -Force -ErrorAction SilentlyContinue
                    }
                    if ($Pack) {
                        Write-Host "Pack $fullPath to $($item.FullName)"
                        Remove-Item $item.FullName -Recurse -Force
                        CreateCopy $fullPath $item.FullName $isDir
                    }
                    if (!$Remove -and !$Pack) { 
                        Write-Host "Create $fullPath"
                        CreateDir $path
                        CreateCopy $item.FullName $fullPath $isDir
                    }
                }

                if (!$SkipC -and !$Pack -and $createSymlinks) {
                    $symlink = Join-Path $systemDrive $fullPath.TrimStart($installDir)
                    RemoveSymlink $symlink $isDir
                    if (!$Remove) {
                        CreateDir (Join-Path $systemDrive $path.TrimStart($installDir))
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

        foreach ($category in (Get-ChildItem $package |
                Select-Object -ExpandProperty Name |
                Where-Object { $_.Contains("#") } |
                ForEach-Object { $_.Split("@")[0] }) |
                Get-Unique) {
            $hashSeparated = $category.Split("#")
            $isC = $hashSeparated[0] -eq "c"
            $path = if ($isC) { $c.c } else { $d[$hashSeparated[0]] }
            for ($i = 1; $i -lt $hashSeparated.Length; $i++) {
                $path = Join-Path $path $hashSeparated[$i]
            }
            Process $category $path $true (-not $isC)
        }

        Process "shortcuts" $c.shortcuts $false $false
        Process "startup" $c.startup $false $false

        $script = if ($Remove) { "remove" } elseif ($Pack) { "pack" } else { "install" }

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

        $txt = Join-Path $package "$script.txt"
        if (Test-Path $txt) {
            Write-Host "Show $txt"
            Write-Host ""
            Get-Content $txt
            Write-Host ""
            Write-Host "Press any key..."
            $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
        }

        if (!$Remove -and !$Pack) { ie4uinit -show }

        if ($Remove) { RemovePackage }

        if ($Pack) {
            Remove-Item "$package.zip" -ErrorAction SilentlyContinue

            if ($7z) {
                Write-Host "Pack with 7-Zip to $zip"
                7z a "$package.zip" "$package" | Out-Null
            } else {
                Write-Host "Compress to $zip"
                Compress-Archive $package "$package.zip"
            }

            Move-Item "$package.zip" $zip -Force
        }

        $time.Stop()

        Write-Host "Done in $($time.Elapsed.ToString("mm\:ss\.fff"))"
    }
}

Set-Alias deploy Deploy-App

