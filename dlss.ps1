param (
  [Switch] $ShowOverlay,
  [Switch] $HideOverlay,
  [Switch] $Dev,
  [Switch] $Prod
)

$path = "HKLM:\SOFTWARE\NVIDIA Corporation\Global\NGXCore"
$name = "ShowDlssIndicator"

if ($ShowOverlay) {
  sudo {
    if (!(Test-Path -Path $args[0])) { New-Item -Path $args[0] | Out-Null }
    New-ItemProperty -Path $args[0] -Name $args[1] `
      -PropertyType DWord -Value 1024 `
      -Force | Out-Null
  } -args @($path, $name)
}

if ($HideOverlay) {
  sudo {
    Remove-ItemProperty -Path $args[0] -Name $args[1] -ErrorAction SilentlyContinue
  } -args @($path, $name)
}

if ($Dev -or $Prod) {
  $model = Get-ChildItem "C:\ProgramData\NVIDIA\NGX\models\dlss\versions" -Directory |
    Sort-Object { [long] $_.Name } -Descending | Select-Object -First 1
  $files = Join-Path $model.FullName "files"
  $driver = @(Get-ChildItem $files -File)
  if ($driver.Count -ne 1) { throw "Expected exactly one file in $files, found $($driver.Count)" }
  $backup = Join-Path $model.FullName "$($driver[0].Name).default"
  $driver = $driver[0].FullName
}

if ($Dev) {
  $temp = Join-Path $env:TEMP "streamline"
  $zip = Join-Path $temp "streamline-sdk.zip"
  New-Item -Path $temp -ItemType Directory -Force | Out-Null
  if (!(Test-Path $zip)) {
    $url = lastversion NVIDIA-RTX/Streamline --assets --filter 'streamline-sdk-v[\d.]+\.zip$'
    curl.exe -sSL -o $zip $url
  }
  7z e $zip "-o$temp" bin/x64/development/nvngx_dlss.dll -y | Out-Null
  if (!(Test-Path $backup)) { Copy-Item -Path $driver -Destination $backup }
  Copy-Item -Path "$temp\nvngx_dlss.dll" -Destination $driver
}

if ($Prod) {
  if (Test-Path $backup) { Move-Item -Path $backup -Destination $driver -Force }
  Write-Host "`e[33mEffective on the following game start`e[0m"
}
