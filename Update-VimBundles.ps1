function Update-VimBundles {
    workflow Pull-UpdatesInParallel {
        $bundles = Get-ChildItem -Path "c:\Apps\Vim\vimfiles\bundle" -Directory

        foreach -Parallel ($bundle in $bundles) {
            InlineScript {
                $bundle = $Using:bundle
                $n = [Environment]::NewLine

                Set-Location -Path $bundle.FullName

                $pullResult = git pull 2>&1
                Write-Output -InputObject $("Pulling $bundle..." + $n + [String]::Join($n, $pullResult) + $n)

                if (git submodule 2>&1) {
                    $submoduleUpdateResult = git submodule update --init --recursive 2>&1

                    if ($submoduleUpdateResult) {
                        Write-Output -InputObject $("Updating submodules for $bundle..." + $n + [String]::Join($n, $submoduleUpdateResult) + $n)
                    }
                }

                if (Test-Path "package.json" -PathType Leaf) {
                    $npmInstallResult = npm install 2>&1

                    if ($npmInstallResult) {
                        Write-Output -InputObject $("Installing npm packages for $bundle..." + $n + [String]::Join($n, $npmInstallResult) + $n)
                    }
                }
            }
        }
    }

    Pull-UpdatesInParallel
}

Set-Alias uvb Update-VimBundles

