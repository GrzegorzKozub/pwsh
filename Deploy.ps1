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

function Process ($switches, $globals, $category, $path, $replace = $true, $createSymlinks = $true) {
    $isC = $path.StartsWith($globals.systemDrive)

    $categoryPath = Join-Path $globals.package $category
    $deviceCategoryPath = $categoryPath + "@" + (Get-Content Env:\COMPUTERNAME)
    if (Test-Path $deviceCategoryPath) { $categoryPath = $deviceCategoryPath }

    foreach ($item in Get-ChildItem $categoryPath -Force -ErrorAction SilentlyContinue) {
        $fullPath = Join-Path $path $item.Name
        $isDir = $item.Attributes.HasFlag([IO.FileAttributes]::Directory)

        if (($isC -and !$switches.skipC) -or (!$isC -and !$switches.skipD)) {
            if (!$switches.pack -and ($switches.remove -or $replace)) {
                Write-Host "Remove $fullPath"
                Remove $fullPath
            }

            if ($switches.pack) {
                Write-Host "Pack $fullPath to $($item.FullName)"
                Remove $item.FullName
                CreateCopy $fullPath $item.FullName $isDir
            }

            if (!$switches.remove -and !$switches.pack) { 
                Write-Host "Create $fullPath"
                CreateDir $path
                CreateCopy $item.FullName $fullPath $isDir
            }
        }

        if (!$switches.skipC -and !$switches.pack -and $createSymlinks) {
            $symlink = Join-Path $globals.systemDrive $fullPath.TrimStart($globals.installDir)
            RemoveSymlink $symlink
            if (!$Remove) {
                CreateDir (Join-Path $globals.systemDrive $path.TrimStart($globals.installDir))
                CreateSymlink $symlink $fullPath $isDir
            }
        }
    }
}
