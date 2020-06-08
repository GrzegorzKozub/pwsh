using namespace System.Collections.ObjectModel
using namespace System.Management.Automation

Import-Module Admin
Import-Module Deploy

function Deploy-App {
  param (
    [Parameter(ValueFromRemainingArguments)] [switch] $SkipC = $false,
    [Parameter(ValueFromRemainingArguments)] [switch] $SkipD = $false,
    [Parameter(ValueFromRemainingArguments)] [switch] $SkipPs1 = $false,
    [Parameter(ValueFromRemainingArguments)] [switch] $SkipReg = $false,
    [Parameter(ValueFromRemainingArguments)] [switch] $Remove = $false,
    [Parameter(ValueFromRemainingArguments)] [switch] $Pack = $false
  )

  dynamicparam {
    $packages = "D:\Win\Packages"

    $values =
      Get-ChildItem -Path $packages -Recurse -Include "*.zip" |
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

  process {
    $switches = @{
      skipC = $SkipC
      skipD = $SkipD
      skipPs1 = $SkipPs1
      skipReg = $SkipReg
      remove = $Remove
      pack = $Pack
      parallel = $Parallel
    }

    if ($switches.remove -and $switches.pack) {
      Write-Error "Can either add, remove or pack"
      return
    }

    AssertRunningAsAdmin

    $time = [Diagnostics.Stopwatch]::StartNew()

    $globals = @{
      zip = Join-Path $packages "$($PSBoundParameters.App).zip"
      targetDrive = "D:"
      systemDrive = $env:SystemDrive
    }

    $d = @{
      packages = Join-Path $globals.targetDrive "Packages"
      apps = Join-Path $globals.targetDrive "Apps"
      programdata = Join-Path $globals.targetDrive $home.TrimEnd($env:USERNAME).TrimStart($globals.systemDrive) | Join-Path -ChildPath "All Users"
      home = Join-Path $globals.targetDrive $home.TrimStart($globals.systemDrive)
      documents = Join-Path $globals.targetDrive $home.TrimStart($globals.systemDrive) | Join-Path -ChildPath "Documents"
      savedgames = Join-Path $globals.targetDrive $home.TrimStart($globals.systemDrive) | Join-Path -ChildPath "Saved Games"
      local = Join-Path $globals.targetDrive $env:LOCALAPPDATA.TrimStart($globals.systemDrive)
      locallow = Join-Path $globals.targetDrive ($env:LOCALAPPDATA.TrimStart($globals.systemDrive) + "Low")
      roaming = Join-Path $globals.targetDrive $env:APPDATA.TrimStart($globals.systemDrive)
    }

    $c = @{
      c = Join-Path $globals.systemDrive "\"
      shortcuts = Join-Path $env:ProgramData "Microsoft\Windows\Start Menu\Programs"
      startup = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup"
    }

    $globals.package = Join-Path $d.packages ([IO.Path]::GetFileNameWithoutExtension($globals.zip))

    if ($switches.remove) {
      Write-Host "Removing $($globals.zip)" -ForegroundColor Red
      $hook = "remove"
    } elseif ($switches.pack) {
      Write-Host "Packing $($globals.zip)" -ForegroundColor Blue
      $hook = "pack"
    } else {
      Write-Host "Adding $($globals.zip)" -ForegroundColor Green
      $hook = "add"
    }

    function RemovePackage {
      Remove $globals.package
    }

    function UnzipPackage {
      Unzip $globals.zip $d.packages
      SetOwnerToCurrentUser $globals.package
      SetChildrenOwnerToCurrentUser $globals.package
    }

    if (Test-Path $globals.package) { RemovePackage }
    UnzipPackage

    function DeployCategory ($category, $to, $replace = $true, $createLinks = $true) {
      $from = Join-Path $globals.package $category

      $deviceFrom = $from + "@" + $env:COMPUTERNAME
      if (Test-Path $deviceFrom) {
        $from = $deviceFrom
      } elseif (!(Test-Path $from)) { return }

      DeployItems $switches $globals $from $to $replace $createLinks
    }

    function RunPs1 ($name) {
      if ($switches.skipPs1) { return }
      $ps1 = Join-Path $globals.package "$name.ps1"
      if (Test-Path $ps1) {
        Log "Run" $ps1
        & $ps1
      }
    }

    if (!$switches.remove -and !$switches.pack) { RunPs1 "install" }

    DeployCategory "apps" $d.apps $true $false
    DeployCategory "programdata" $d.programdata
    DeployCategory "home" $d.home
    DeployCategory "documents" $d.documents
    DeployCategory "savedgames" $d.savedgames
    DeployCategory "local" $d.local
    DeployCategory "locallow" $d.locallow
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

    RunPs1 $hook

    if (!$switches.skipReg) {
      $reg = Join-Path $globals.package "$hook.reg"
      if (Test-Path $reg) {
        Log "Import" $reg
        Start-Process -FilePath "regedit.exe" -ArgumentList "/s", """$reg""" -Wait
      }
    }

    $txt = Join-Path $globals.package "$hook.txt"
    if (Test-Path $txt) {
      Log "Show" $txt
      Get-Content $txt | Write-Host -ForegroundColor White
      Write-Host "Press any key..."
      $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
    }

    if (!$switches.remove -and !$switches.pack) { RefreshIcons }

    if ($switches.pack) {
      $packageZip = "$($globals.package).zip"
      Remove $packageZip
      Zip $globals.package $packageZip
      SetOwnerToCurrentUser $packageZip
      Log "Move" $globals.zip
      Move-Item $packageZip $globals.zip -Force
    }

    RemovePackage

    $time.Stop()
    Write-Host "Done in $($time.Elapsed.ToString("mm\:ss\.fff"))" -ForegroundColor DarkGray
  }
}

Set-Alias deploy Deploy-App

