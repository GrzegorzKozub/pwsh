using namespace System.Collections.ObjectModel
using namespace System.Management.Automation

function Deploy-App {
    [CmdletBinding()]

    param (
        [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
        [switch]
        $SkipC = $false,

        [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
        [switch]
        $SkipD = $false,

        [Parameter(Position = 2, ValueFromRemainingArguments = $true)]
        [switch]
        $SkipPs1 = $false,

        [Parameter(Position = 3, ValueFromRemainingArguments = $true)]
        [switch]
        $SkipReg = $false,

        [Parameter(Position = 4, ValueFromRemainingArguments = $true)]
        [switch]
        $Remove = $false,

        [Parameter(Position = 5, ValueFromRemainingArguments = $true)]
        [switch]
        $Pack = $false,

        [Parameter(Position = 6, ValueFromRemainingArguments = $true)]
        [switch]
        $Parallel = $true
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

        $switches = @{
            remove = $Remove
            skipC = $SkipC
            skipD = $SkipD
            skipPs1 = $SkipPs1
            skipReg = $SkipReg
            pack = $Pack
            parallel = $Parallel
        }

        if ($switches.remove -and $switches.pack) {
            Write-Error "Can either remove or pack"
            return
        }

        if (!(Test-Admin)) {
            Write-Error "Must run as admin"
            return
        }

        $time = [Diagnostics.Stopwatch]::StartNew()

        $globals = @{
            zip = Join-Path $source "$($PSBoundParameters.App).zip"
            installDir = "D:"
            systemDrive = Get-Content Env:\SystemDrive
        }

        Write-Host "$(if ($switches.remove) { "Removing" } elseif ($switches.pack) { "Packing" } else { "Installing" }) $($globals.zip)"

        $d = @{
            packages = Join-Path $globals.installDir "Packages"
            apps = Join-Path $globals.installDir "Apps"
            programdata = Join-Path $globals.installDir $home.TrimEnd((Get-Content Env:\USERNAME)).TrimStart($globals.systemDrive) | Join-Path -ChildPath "All Users"
            home = Join-Path $globals.installDir $home.TrimStart($globals.systemDrive)
            documents = Join-Path $globals.installDir $home.TrimStart($globals.systemDrive) | Join-Path -ChildPath "Documents"
            local = Join-Path $globals.installDir (Get-Content Env:\LOCALAPPDATA).TrimStart($globals.systemDrive)
            roaming = Join-Path $globals.installDir (Get-Content Env:\APPDATA).TrimStart($globals.systemDrive)
        }

        $c = @{
            c = Join-Path $globals.systemDrive "\"
            apps = Join-Path $globals.systemDrive "Apps"
            shortcuts = Join-Path (Get-Content Env:\ProgramData) "Microsoft\Windows\Start Menu\Programs"
            startup = Join-Path (Get-Content Env:\APPDATA) "Microsoft\Windows\Start Menu\Programs\Startup"
        }

        $globals.package = Join-Path $d.packages ([IO.Path]::GetFileNameWithoutExtension($globals.zip))

        $sourceDeployPs1 = ". $(Join-Path (Split-Path $PROFILE) 'Deploy.ps1')"
        Invoke-Expression $sourceDeployPs1

        function RemovePackage () {
            Write-Host "Remove $($globals.package)"
            Remove $globals.package
        }

        $7z = Get-Command "7z" -ErrorAction SilentlyContinue

        function ExtractPackage () {
            Write-Host "Extract $($globals.package)"
            if ($7z) {
                7z x $globals.zip -y -o"$($d.packages)" | Out-Null
            } else {
                Expand-Archive $globals.zip $d.packages
            }
        }

        if (Test-Path $globals.package) {
            if (!$switches.remove -and !$switches.pack) {
                RemovePackage
                ExtractPackage
            }
        } else {
            ExtractPackage
        }

        $script:jobs = @()

        function DeployCategory ($category, $to, $replace = $true, $createSymlinks = $true) {
            $from = Join-Path $globals.package $category

            $deviceFrom = $from + "@" + (Get-Content Env:\COMPUTERNAME)
            if (Test-Path $deviceFrom) {
                $from = $deviceFrom
            } elseif (!(Test-Path $from)) {
                return
            }

            if ($switches.parallel) {
                $script:jobs += Start-Job `
                    -InitializationScript ([ScriptBlock]::Create($sourceDeployPs1)) `
                    -ScriptBlock {
                        param($switches, $globals, $from, $to, $replace, $createSymlinks)
                        DeployItems $switches $globals $from $to $replace $createSymlinks
                    } `
                    -ArgumentList @($switches, $globals, $from, $to, $replace, $createSymlinks)
            } else {
                DeployItems $switches $globals $from $to $replace $createSymlinks
            }
        }

        DeployCategory "apps" $d.apps $true $false
        DeployCategory "programdata" $d.programdata
        DeployCategory "home" $d.home
        DeployCategory "documents" $d.documents
        DeployCategory "local" $d.local
        DeployCategory "roaming" $d.roaming

        foreach ($category in (Get-ChildItem $globals.package |
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

            DeployCategory $category $path $true (-not $isC)
        }

        DeployCategory "shortcuts" $c.shortcuts $false $false
        DeployCategory "startup" $c.startup $false $false

        if ($switches.parallel) {
            $script:jobs | Wait-Job | Receive-Job
            $script:jobs | Remove-Job
        }

        $script = if ($switches.remove) { "remove" } elseif ($switches.pack) { "pack" } else { "install" }

        if (!$switches.skipPs1) {
            $ps1 = Join-Path $globals.package "$script.ps1"
            if (Test-Path $ps1) {
                Write-Host "Run $ps1"
                & $ps1
            }
        }

        if (!$switches.skipReg) {
            $reg = Join-Path $globals.package "$script.reg"
            if (Test-Path $reg) {
                Write-Host "Import $reg"
                Start-Process -FilePath "regedit.exe" -ArgumentList "/s", """$reg""" -Wait
            }
        }

        $txt = Join-Path $globals.package "$script.txt"
        if (Test-Path $txt) {
            Write-Host "Show $txt"
            Write-Host ""
            Get-Content $txt
            Write-Host ""
            Write-Host "Press any key..."
            $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
        }

        if (!$switches.remove -and !$switches.pack) { ie4uinit -show }

        if ($switches.remove) { RemovePackage }

        if ($switches.pack) {
            $packageZip = "$($globals.package).zip"
            Remove $packageZip
            Write-Host "Pack $($globals.zip)"

            if ($7z) {
                7z a $packageZip $globals.package | Out-Null
            } else {
                Compress-Archive $globals.package $packageZip
            }

            Move-Item $packageZip $globals.zip -Force
        }

        $time.Stop()
        Write-Host "Done in $($time.Elapsed.ToString("mm\:ss\.fff"))"
    }
}

Set-Alias deploy Deploy-App

