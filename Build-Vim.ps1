function Build-Vim {
    Push-Location

    if (Test-Path "vim" -PathType Container) {
        Set-Location "vim"
        git reset --hard
        git clean -d --force
        git pull
    } else {
        git clone git://github.com/b4winckler/vim.git
        Set-Location "vim"
    }

    Set-Location "src"

    foreach ($gui in "no", "yes") {
        mingw32-make -j4 -f make_ming.mak `
            FEATURES=HUGE GUI=$gui OLE=$gui `
            PYTHON3=c:/Programs/Python DYNAMIC_PYTHON3=yes PYTHON3_VER=33 `
            PERL=c:/Programs/Perl DYNAMIC_PERL=yes PERL_VER=514 `
            RUBY=c:/Programs/Ruby DYNAMIC_RUBY=yes RUBY_VER=20 RUBY_VER_LONG=2.0.0
    }

    Copy-Item -Path "vim.exe", "gvim.exe" -Destination $(Get-Location -Stack).ToArray()[0].Path -Force
    Pop-Location
}

Set-Alias bv Build-Vim

