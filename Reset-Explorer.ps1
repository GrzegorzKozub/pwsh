function Reset-Explorer {
  param (
    [switch] $DialogPaths,
    [switch] $TrayIcons,
    [switch] $Windows
  )

  function Log ($message) {
    Write-Host $message -ForegroundColor DarkGray
  }

  function DialogPaths {
    Log "Clearing paths recently used in dialog windows"
    Remove-Item `
      -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32" `
      -Recurse `
      -ErrorAction SilentlyContinue
  }

  function TrayIcons {
    Log "Clearing tray icons"
    Stop-Process -Name "explorer"
    foreach ($value in "IconStreams", "PastIconsStream") {
      Remove-ItemProperty `
        -Name $value `
        -Path "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\TrayNotify" `
        -ErrorAction SilentlyContinue
    }
  }

  function Windows {
    Log "Clearing manually set window sizes"
    $keys = (
      "HKCU:\Software\Microsoft\Windows\Shell\BagMRU", 
      "HKCU:\Software\Microsoft\Windows\Shell\Bags", 
      "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\BagMRU", 
      "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags"
    )
    foreach ($key in $keys) {
      Remove-Item -Path $key -Recurse -ErrorAction SilentlyContinue
    }
  }

  if (!$DialogPaths -and !$Windows -and !$TrayIcons) {
    $DialogPaths = $true
    $TrayIcons = $true
    $Windows = $true
  }

  if ($DialogPaths) { DialogPaths }
  if ($TrayIcons) { TrayIcons }
  if ($Windows) { Windows }
}

