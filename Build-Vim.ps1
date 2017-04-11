function Build-Vim {
    [CmdletBinding()]

    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateScript({ Test-Path $_ })]
        [string]
        $WorkDir,

        [Parameter(Position = 1, Mandatory = $true)]
        [ValidateScript({ Test-Path $_ })]
        [string]
        $OutDir
    )

    Push-Location

    $zipFile = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($PROFILE.CurrentUserAllHosts), "Build-Vim.zip")

    $WorkDir = Resolve-Path $WorkDir
    $OutDir = Resolve-Path $OutDir

    Set-Location $WorkDir

    $vim = "vim"

    if (Test-Path $vim -PathType Container) {
        Set-Location $vim
        git clean -fd
        git pull
    } else {
        git clone https://github.com/vim/vim.git $vim
        Set-Location $vim
    }

    7z x -y $zipFile *.diff | Out-Null

    foreach ($patch in Get-ChildItem -Filter *.diff) {
        git apply $patch
    }

    Set-Location "src"

    7z x -y $zipFile *.ico | Out-Null

    foreach ($gui in "no", "yes") {
        mingw32-make -j2 -f make_ming.mak `
            FEATURES=HUGE MBYTE=yes IME=yes GIME=yes CSCOPE=yes NETBEANS=no GUI=$gui OLE=$gui DIRECTX=$gui `
            PYTHON3=d:/Apps/Python DYNAMIC_PYTHON3=yes PYTHON3_VER=35 `
            PERL=d:/Apps/Perl DYNAMIC_PERL=yes PERL_VER=524 `
            RUBY=d:/Apps/Ruby DYNAMIC_RUBY=yes RUBY_VER=23 RUBY_VER_LONG=2.3.0
    }

    $runtime = (Select-String -Path "version.h" -Pattern '#define VIM_VERSION_NODOT.\"(vim[0-9]{2})\"').Matches[0].Groups[1].Value

    Set-Location "tee"
    mingw32-make

    Set-Location $WorkDir

    $runtimeDir = Join-Path $OutDir $runtime

    Remove-Item -Path $runtimeDir -Recurse -ErrorAction SilentlyContinue

    Copy-Item `
        -Path "$vim\runtime" `
        -Destination $runtimeDir `
        -Recurse `
        -Exclude *.cdr, *.desktop, *.eps, *.gif, *.info, *.pdf, *.png, *.xpm, termcap

    Copy-Item `
        -Path "$vim\src\vim.exe", "$vim\src\gvim.exe", "$vim\src\vimrun.exe", "$vim\src\tee\tee.exe", "$vim\src\xxd\xxd.exe" `
        -Destination $runtimeDir

    7z x -y $zipFile *.bat *.dll *.exe -o"$runtimeDir" | Out-Null

    Pop-Location
}

