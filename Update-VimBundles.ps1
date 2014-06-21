function Update-VimBundles {

    workflow Pull-UpdatesInParallel {
        $bundles = Get-ChildItem -Path "c:\Programs\Vim\vimfiles\bundle" -Directory -Exclude "YouCompleteMe"

        foreach -Parallel ($bundle in $bundles) {

            InlineScript {
                $bundle = $Using:bundle
                Set-Location -Path $bundle.FullName
                $result = git pull 2>&1
                $n = [Environment]::NewLine
                Write-Output -InputObject $("Updating $bundle..." + $n + [String]::Join($n, $result) + $n)
            }
        }
    }

    Pull-UpdatesInParallel
}

Set-Alias uvb Update-VimBundles

