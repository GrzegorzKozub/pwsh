using namespace System.Collections.ObjectModel
using namespace System.Management.Automation

Import-Module Admin

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
    $win = "D:\Win"

    $globals = @{
      packagesDir = Join-Path $win "Packages"
      unpackedDir = Join-Path $win "Unpacked"
      targetDrive = "D:"
      systemDrive = $env:SystemDrive
    }

    $values =
      Get-ChildItem -Path $globals.packagesDir -Recurse -Include "*.zip" |
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
    }

    if ($switches.remove -and $switches.pack) {
      Write-Error "Can either add, remove or pack"
      return
    }

    AssertRunningAsAdmin

    $time = [Diagnostics.Stopwatch]::StartNew()

    $globals.package = Join-Path $globals.packagesDir "$($PSBoundParameters.App).zip"

    $d = @{
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

    $globals.unpacked = Join-Path $globals.unpackedDir ([IO.Path]::GetFileNameWithoutExtension($globals.package))

    if ($switches.remove) {
      Write-Host "Removing $($globals.package)" -ForegroundColor Red
      $hook = "remove"
    } elseif ($switches.pack) {
      Write-Host "Packing $($globals.package)" -ForegroundColor Blue
      $hook = "pack"
    } else {
      Write-Host "Adding $($globals.package)" -ForegroundColor Green
      $hook = "add"
    }

    function Log ($action, $path) {
      Write-Host ("{0,-7}" -f $action) -NoNewLine
      Write-Host $path -ForegroundColor DarkCyan
    }

    function Remove ($path) {
      if (!(Test-Path $path)) { return }
      Log "Remove" $path
      Remove-Item $path -Recurse -Force
    }

    function RemoveUnpacked { Remove $globals.unpacked }

    if (Test-Path $globals.unpacked) { RemoveUnpacked }

    function Test7z { return !!(Get-Command "7z" -ErrorAction SilentlyContinue) }

    function Unzip ($from, $to) {
      Log "Unzip" (Join-Path $to ([IO.Path]::GetFileNameWithoutExtension($from)))
      if (Test7z) {
        7z x $from -y -o"$to" | Out-Null
      } else {
        Expand-Archive $from $to
      }
    }

    function SetOwner ($path, $user) {
      $acl = Get-Acl -LiteralPath $path
      $acl.SetOwner($user)
      Set-Acl -LiteralPath $path -AclObject $acl
    }

    function GetCurrentUser {
      return New-Object System.Security.Principal.NTAccount($env:USERNAME)
    }

    function SetOwnerToCurrentUser ($path) {
      SetOwner $path (GetCurrentUser)
    }

    function UnzipPackage {
      Unzip $globals.package $globals.unpackedDir
      SetOwnerToCurrentUser $globals.unpacked

      function SetChildrenOwnerToCurrentUser ($path) {
        $user = GetCurrentUser
        foreach ($item in (Get-ChildItem $path -Recurse)) {
          SetOwner $item.FullName $user
        }
      }

      SetChildrenOwnerToCurrentUser $globals.unpacked
    }

    UnzipPackage

    function RunPs1 ($name) {
      if ($switches.skipPs1) { return }
      $ps1 = Join-Path $globals.unpacked "$name.ps1"
      if (Test-Path $ps1) {
        Log "Run" $ps1
        & $ps1
      }
    }

    if (!$switches.remove -and !$switches.pack) { RunPs1 "install" }

    function DeployCategory ($category, $to, $replace = $true, $createLinks = $true) {
      $from = Join-Path $globals.unpacked $category

      $deviceFrom = $from + "@" + $env:COMPUTERNAME
      if (Test-Path $deviceFrom) { $from = $deviceFrom } elseif (!(Test-Path $from)) { return }

      $isC = $to.StartsWith($globals.systemDrive)

      function CreateDir ($dir) {
        if (Test-Path $dir) { return }
        Log "Create" $dir
        New-Item $dir -ItemType Directory | Out-Null
      }

      function CreateCopy ($from, $to, $isDir) {
        Log "Copy" $to
        if ($isDir) {
          robocopy $from $to /NJH /NJS /NFL /NDL /E /COPY:DATO "/MT:$($env:NUMBER_OF_PROCESSORS / 2)" | Out-Null
        } else {
          robocopy `
            ([IO.Path]::GetDirectoryName($from)) `
            ([IO.Path]::GetDirectoryName($to)) `
            ([IO.Path]::GetFileName($from)) `
            /NJH /NJS /NFL /NDL /COPY:DATO | Out-Null
        }
      }

      function CreateLink ($link, $path, $isDir = $true) {
        if (Test-Path $link) { return }
        Log "Link" $link
        if ($isDir) {
          New-Item -ItemType Junction -Path $link -Target $path | Out-Null
        } else {
          New-Item -ItemType SymbolicLink -Path $link -Target $path | Out-Null
        }
        SetOwnerToCurrentUser $link
      }

      foreach ($itemFrom in Get-ChildItem $from -Force -ErrorAction SilentlyContinue) {
        $itemTo = Join-Path $to $itemFrom.Name
        $isDir = $itemFrom.Attributes.HasFlag([IO.FileAttributes]::Directory)

        if (($isC -and !$switches.skipC) -or (!$isC -and !$switches.skipD)) {
          if (!$switches.pack -and ($switches.remove -or $replace)) {
            Remove $itemTo
          }

          if ($switches.pack) {
            Remove $itemFrom.FullName
            CreateCopy $itemTo $itemFrom.FullName $isDir
          }

          if (!$switches.remove -and !$switches.pack) {
            CreateDir $to
            CreateCopy $itemFrom.FullName $itemTo $isDir
          }
        }

        if (!$switches.skipC -and !$switches.pack -and $createLinks) {
          $link = Join-Path $globals.systemDrive $itemTo.TrimStart($globals.targetDrive)
          Remove $link
          if (!$switches.remove) {
            CreateDir (Join-Path $globals.systemDrive $to.TrimStart($globals.targetDrive))
            CreateLink $link $itemTo $isDir
          }
        }
      }
    }

    DeployCategory "apps" $d.apps $true $false
    DeployCategory "programdata" $d.programdata
    DeployCategory "home" $d.home
    DeployCategory "documents" $d.documents
    DeployCategory "savedgames" $d.savedgames
    DeployCategory "local" $d.local
    DeployCategory "locallow" $d.locallow
    DeployCategory "roaming" $d.roaming

    foreach ($category in (Get-ChildItem $globals.unpacked |
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
      $reg = Join-Path $globals.unpacked "$hook.reg"
      if (Test-Path $reg) {
        Log "Import" $reg
        Start-Process -FilePath "regedit.exe" -ArgumentList "/s", """$reg""" -Wait
      }
    }

    $txt = Join-Path $globals.unpacked "$hook.txt"
    if (Test-Path $txt) {
      Log "Show" $txt
      Get-Content $txt | Write-Host -ForegroundColor White
      Write-Host "Press any key..."
      $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
    }

    function RefreshIcons { ie4uinit -show }
    if (!$switches.remove -and !$switches.pack) { RefreshIcons }

    if ($switches.pack) {
      $zip = "$($globals.unpacked).zip"
      Remove $zip

      function Zip ($from, $to) {
        Log "Zip" $to
        if (Test7z) {
          7z a $to $from | Out-Null
        } else {
          Compress-Archive $from $to
        }
      }

      Zip $globals.unpacked $zip
      SetOwnerToCurrentUser $zip
      Log "Move" $globals.package
      Move-Item $zip $globals.package -Force
    }

    RemoveUnpacked

    $time.Stop()
    Write-Host "Done in $($time.Elapsed.ToString("mm\:ss\.fff"))" -ForegroundColor DarkGray
  }
}

Set-Alias deploy Deploy-App

