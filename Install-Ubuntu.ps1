function Install-Ubuntu {
  Push-Location
  Set-Location -Path $env:TEMP
  $packageFile = "ubuntu.appx"
  Invoke-WebRequest -Uri "https://aka.ms/wsl-ubuntu-1804" -OutFile $packageFile -UseBasicParsing
  Add-AppPackage -Path $packageFile
  Remove-Item -Path $packageFile
  Pop-Location
}

