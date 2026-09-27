param ( [Switch] $Reset)
sudo {
  Start-Process -FilePath "regedit.exe" -ArgumentList "/s", $args[0] -Wait
} -args $(
  Join-Path `
    -Path $PSScriptRoot `
    -ChildPath $(if ($Reset) { "blue.reg" } else { "orange.reg" })
  )
