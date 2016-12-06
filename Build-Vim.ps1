function Build-Vim {
    Push-Location

    if (Test-Path "build-vim" -PathType Container) {
        Set-Location "build-vim"
        git clean -fd
        git pull
    } else {
        git clone https://github.com/vim/vim.git "build-vim"
        Set-Location "build-vim"
    }

    $archivePath = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($PROFILE.CurrentUserAllHosts), "Build-Vim.zip")
    7z x -y $archivePath *.diff | Out-Null

    foreach ($patch in Get-ChildItem -Filter *.diff) {
        git apply $patch
    }

    Set-Location "src"
    7z x -y $archivePath | Out-Null

    foreach ($gui in "no", "yes") {
        mingw32-make -j4 -f make_ming.mak `
            FEATURES=HUGE MBYTE=yes IME=yes GIME=yes CSCOPE=yes GUI=$gui OLE=$gui DIRECTX=$gui `
            PYTHON3=c:/Programs/Python DYNAMIC_PYTHON3=yes PYTHON3_VER=35 `
            PERL=c:/Programs/Perl DYNAMIC_PERL=yes PERL_VER=524 `
            RUBY=c:/Programs/Ruby DYNAMIC_RUBY=yes RUBY_VER=23 RUBY_VER_LONG=2.3.0 `
            #LUA=c:/Programs/Lua DYNAMIC_LUA=yes LUA_VER=52
    }

    Copy-Item -Path "vim.exe", "gvim.exe", "vimrun.exe" -Destination $(Get-Location -Stack).ToArray()[0].Path -Force
    Pop-Location
}

Set-Alias bv Build-Vim

