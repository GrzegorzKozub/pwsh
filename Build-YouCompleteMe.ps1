# https://github.com/Valloric/YouCompleteMe/wiki/Windows-Installation-Guide#instructions-for-64-bit-using-mingw64-clang

function Build-YouCompleteMe {
    Push-Location
    Set-Location c:\Programs\Vim\vimfiles\bundle

    if (Test-Path YouCompleteMe -PathType Container) {
        Set-Location YouCompleteMe
        git reset --hard
        git clean -d --force
        git pull
    } else {
        git clone https://github.com/Valloric/YouCompleteMe.git
        Set-Location YouCompleteMe
    }

    git submodule update --init --recursive

    if ((Get-Content third_party\ycmd\cpp\CMakeLists.txt | Select-String "CMAKE_CXX_FLAGS_RELEASE" -Quiet) -eq $false) {

        Add-Content third_party\ycmd\cpp\CMakeLists.txt @'
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -include cmath")
add_definitions(-DBOOST_PYTHON_SOURCE)
add_definitions(-DBOOST_THREAD_BUILD_DLL)
add_definitions(-DMS_WIN64)
'@

    }

    $env:Path = $env:Path.Replace("C:\Programs\Git\bin;", "").Replace("C:\Programs\Ruby\bin;", "")

    New-Item build -ItemType Directory | Out-Null
    Set-Location build

    c:\Programs\CMake\bin\cmake -G "MinGW Makefiles" `
        -DPYTHON_LIBRARY="C:/Programs/Python/libs/libpython27.a" `
        -DPYTHON_INCLUDE_DIR="C:/Programs/Python/include" `
        -DPATH_TO_LLVM_ROOT:PATH="c:\Programs\LLVM" `
        . `
        c:\Programs\Vim\vimfiles\bundle\YouCompleteMe\third_party\ycmd\cpp

    mingw32-make ycm_support_libs

    Set-Location ..
    Remove-Item build -Recurse | Out-Null

    Set-Location third_party\ycmd\third_party\OmniSharpServer
    Set-VisualStudioVars
    msbuild /m OmniSharp.sln

    Pop-Location
}

Set-Alias bycm Build-YouCompleteMe

