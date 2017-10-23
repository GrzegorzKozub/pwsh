function Remove ($path) {
    Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
}

function CreateDir ($dir) {
    if (Test-Path $dir) { return }
    Write-Host "Create $dir"
    New-Item $dir -ItemType Directory | Out-Null
}

function CreateCopy ($from, $to, $isDir) {
    if ($isDir) {
        robocopy $from $to /NJH /NJS /NFL /NDL /E | Out-Null
    } else {
        xcopy $from ([IO.Path]::GetDirectoryName($to)) /YKHRQ | Out-Null
    }
}

function CreateSymlink ($symlink, $path, $isDir = $true) {
    if (Test-Path $symlink) { return }
    Write-Host "Symlink $symlink"
    cmd /c mklink $(if ($isDir) { "/J" } else { "" }) $symlink $path | Out-Null
}

function RemoveSymlink ($symlink) {
    Write-Host "Unlink $symLink"
    Remove $symlink
}

function DeployItems ($switches, $globals, $from, $to, $replace, $createSymlinks) {
    $isC = $to.StartsWith($globals.systemDrive)

    foreach ($itemFrom in Get-ChildItem $from -Force -ErrorAction SilentlyContinue) {
        $itemTo = Join-Path $to $itemFrom.Name
        $isDir = $itemFrom.Attributes.HasFlag([IO.FileAttributes]::Directory)

        if (($isC -and !$switches.skipC) -or (!$isC -and !$switches.skipD)) {
            if (!$switches.pack -and ($switches.remove -or $replace)) {
                Write-Host "Remove $itemTo"
                Remove $itemTo
            }

            if ($switches.pack) {
                Write-Host "Pack $itemTo to $($itemFrom.FullName)"
                Remove $itemFrom.FullName
                CreateCopy $itemTo $itemFrom.FullName $isDir
            }

            if (!$switches.remove -and !$switches.pack) {
                Write-Host "Create $itemTo"
                CreateDir $to
                CreateCopy $itemFrom.FullName $itemTo $isDir
            }
        }

        if (!$switches.skipC -and !$switches.pack -and $createSymlinks) {
            $symlink = Join-Path $globals.systemDrive $itemTo.TrimStart($globals.installDir)
            RemoveSymlink $symlink
            if (!$Remove) {
                CreateDir (Join-Path $globals.systemDrive $to.TrimStart($globals.installDir))
                CreateSymlink $symlink $itemTo $isDir
            }
        }
    }
}
