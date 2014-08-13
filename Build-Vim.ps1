function Build-Vim {
    Push-Location

    if (Test-Path "build-vim" -PathType Container) {
        Set-Location "build-vim"
        hg update --clean
        hg status --ignored --unknown | ForEach-Object { Remove-Item $_.Substring(2) }
        hg pull
    } else {
        hg clone https://code.google.com/p/vim/ "build-vim"
        Set-Location "build-vim"
    }

    Set-Location "src"

    foreach ($gui in "no", "yes") {
        mingw32-make -j4 -f make_ming.mak `
            FEATURES=HUGE GUI=$gui OLE=$gui `
            PYTHON=c:/Programs/Python DYNAMIC_PYTHON=yes PYTHON_VER=27 `
            PERL=c:/Programs/Perl DYNAMIC_PERL=yes PERL_VER=514 `
            RUBY=c:/Programs/Ruby DYNAMIC_RUBY=yes RUBY_VER=20 RUBY_VER_LONG=2.0.0
    }

    Copy-Item -Path "vim.exe", "gvim.exe" -Destination $(Get-Location -Stack).ToArray()[0].Path -Force
    Pop-Location
}

Set-Alias bv Build-Vim

