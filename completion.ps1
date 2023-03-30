Get-ChildItem -Path "D:\Apps\Common\" -Filter "_*.ps1" | foreach { . $_ }
