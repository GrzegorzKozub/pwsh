function Log ($action, $path) {
    Write-Host ("{0,-7}" -f $action) -NoNewLine
    Write-Host $path -ForegroundColor DarkCyan
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

function SetChildrenOwnerToCurrentUser ($path) {
    $user = GetCurrentUser
    foreach ($item in (Get-ChildItem $path -Recurse)) {
        SetOwner $item.FullName $user
    }
}

function Test7z {
    return !!(Get-Command "7z" -ErrorAction SilentlyContinue)
}

function Unzip ($from, $to) {
    Log "Unzip" (Join-Path $to ([IO.Path]::GetFileNameWithoutExtension($from)))
    if (Test7z) {
        7z x $from -y -o"$to" | Out-Null
    } else {
        Expand-Archive $from $to
    }
}

function Zip ($from, $to) {
    Log "Zip" $to
    if (Test7z) {
        7z a $to $from | Out-Null
    } else {
        Compress-Archive $from $to
    }
}

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

function Remove ($path) {
    if (!(Test-Path $path)) { return }
    Log "Remove" $path
    Remove-Item $path -Recurse -Force
}

function DeployItems ($switches, $globals, $from, $to, $replace, $createLinks) {
    $isC = $to.StartsWith($globals.systemDrive)

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
            $link = Join-Path $globals.systemDrive $itemTo.TrimStart($globals.target)
            Remove $link
            if (!$Remove) {
                CreateDir (Join-Path $globals.systemDrive $to.TrimStart($globals.target))
                CreateLink $link $itemTo $isDir
            }
        }
    }
}
