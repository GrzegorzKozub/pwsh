using namespace System.Collections.ObjectModel
using namespace System.Management.Automation

function Deploy-App {
    [CmdletBinding()]

    param (
        [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
        [switch]
        $SkipUnzip = $false,

        [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
        [switch]
        $SkipC = $false,

        [Parameter(Position = 2, ValueFromRemainingArguments = $true)]
        [switch]
        $SkipD = $false,

        [Parameter(Position = 3, ValueFromRemainingArguments = $true)]
        [switch]
        $SkipPs1 = $false,

        [Parameter(Position = 4, ValueFromRemainingArguments = $true)]
        [switch]
        $SkipReg = $false,

        [Parameter(Position = 5, ValueFromRemainingArguments = $true)]
        [switch]
        $Remove = $false,

        [Parameter(Position = 6, ValueFromRemainingArguments = $true)]
        [switch]
        $Pack = $false,

        [Parameter(Position = 7, ValueFromRemainingArguments = $true)]
        [switch]
        $Parallel = $false,

        [Parameter(Position = 8, ValueFromRemainingArguments = $true)]
        [string]
        $Source,

        [Parameter(Position = 9, ValueFromRemainingArguments = $true)]
        [string]
        $Target
    )

    DynamicParam {

        if ($Source) { $zipDir = $Source } else { $zipDir = "D:\Dropbox\Packages" }

        $values =
            Get-ChildItem -Path $zipDir -Recurse -Include "*.zip" |
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
            skipUnzip = $SkipUnzip
            skipC = $SkipC
            skipD = $SkipD
            skipPs1 = $SkipPs1
            skipReg = $SkipReg
            remove = $Remove
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
            zip = Join-Path $zipDir "$($PSBoundParameters.App).zip"
            target = if ($Target) { $Target } else { "D:" }
            systemDrive = $env:SystemDrive
        }

        $d = @{
            packages = Join-Path $globals.target "Packages"
            apps = Join-Path $globals.target "Apps"
            programdata = Join-Path $globals.target $home.TrimEnd($env:USERNAME).TrimStart($globals.systemDrive) | Join-Path -ChildPath "All Users"
            home = Join-Path $globals.target $home.TrimStart($globals.systemDrive)
            documents = Join-Path $globals.target $home.TrimStart($globals.systemDrive) | Join-Path -ChildPath "Documents"
            local = Join-Path $globals.target $env:LOCALAPPDATA.TrimStart($globals.systemDrive)
            roaming = Join-Path $globals.target $env:APPDATA.TrimStart($globals.systemDrive)
        }

        $c = @{
            c = Join-Path $globals.systemDrive "\"
            shortcuts = Join-Path $env:ProgramData "Microsoft\Windows\Start Menu\Programs"
            startup = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup"
        }

        $globals.package = Join-Path $d.packages ([IO.Path]::GetFileNameWithoutExtension($globals.zip))
        $globals.json = Join-Path $globals.package "package.json"

        $sourceDeployPs1 = ". $(Join-Path (Split-Path $PROFILE) 'Deploy.ps1')"
        Invoke-Expression $sourceDeployPs1

        if ($switches.remove) {
            Write-Host "Removing $($globals.zip) version $(GetDeployedVersion $globals.json)" -ForegroundColor Red
            $customizations = "remove"
        } elseif ($switches.pack) {
            BumpVersion $globals.json
            Write-Host "Packing $($globals.zip) version $(GetDeployedVersion $globals.json) over $(GetPackageVersion $globals.zip)" -ForegroundColor Blue
            $customizations = "pack"
        } else {
            Write-Host "Installing $($globals.zip) version $(GetPackageVersion $globals.zip) over $(GetDeployedVersion $globals.json)" -ForegroundColor Green
            $customizations = "install"
        }

        function RemovePackage {
            Remove $globals.package
        }

        function UnzipPackage {
            Unzip $globals.zip $d.packages
            SetOwnerToCurrentUser $globals.package
            SetChildrenOwnerToCurrentUser $globals.package
        }

        if (Test-Path $globals.package) {
            if (!$switches.remove -and !$switches.pack -and !$switches.skipUnzip) {
                RemovePackage
                UnzipPackage
            }
        } else {
            if ($switches.skipUnzip) { Write-Warning "$($globals.package) is missing" }
            UnzipPackage
        }

        $script:jobs = @()

        function DeployCategory ($category, $to, $replace = $true, $createLinks = $true) {
            $from = Join-Path $globals.package $category

            $deviceFrom = $from + "@" + $env:COMPUTERNAME
            if (Test-Path $deviceFrom) {
                $from = $deviceFrom
            } elseif (!(Test-Path $from)) {
                return
            }

            if ($switches.parallel) {
                $script:jobs += Start-Job `
                    -InitializationScript ([ScriptBlock]::Create($sourceDeployPs1)) `
                    -ScriptBlock {
                        param($switches, $globals, $from, $to, $replace, $createLinks)
                        DeployItems $switches $globals $from $to $replace $createLinks
                    } `
                    -ArgumentList @($switches, $globals, $from, $to, $replace, $createLinks)
            } else {
                DeployItems $switches $globals $from $to $replace $createLinks
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

        if (!$switches.skipPs1) {
            $ps1 = Join-Path $globals.package "$customizations.ps1"
            if (Test-Path $ps1) {
                Log "Run" $ps1
                & $ps1
            }
        }

        if (!$switches.skipReg) {
            $reg = Join-Path $globals.package "$customizations.reg"
            if (Test-Path $reg) {
                Log "Import" $reg
                Start-Process -FilePath "regedit.exe" -ArgumentList "/s", """$reg""" -Wait
            }
        }

        $txt = Join-Path $globals.package "$customizations.txt"
        if (Test-Path $txt) {
            Log "Show" $txt
            Get-Content $txt | Write-Host -ForegroundColor White
            Write-Host "Press any key..."
            $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
        }

        if (!$switches.remove -and !$switches.pack) { Refresh-Icons }

        if ($switches.remove) { RemovePackage }

        if ($switches.pack) {
            $packageZip = "$($globals.package).zip"
            Remove $packageZip
            Zip $globals.package $packageZip
            SetOwnerToCurrentUser $packageZip 
            Log "Move" $globals.zip
            Move-Item $packageZip $globals.zip -Force
        }

        $time.Stop()
        Write-Host "Done in $($time.Elapsed.ToString("mm\:ss\.fff"))" -ForegroundColor DarkGray
    }
}

Set-Alias deploy Deploy-App

