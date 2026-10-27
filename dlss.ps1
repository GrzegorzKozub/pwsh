param (
  [Switch] $ShowOverlay,
  [Switch] $HideOverlay,
  [Switch] $Dev,
  [Switch] $Prod
)

$path = 'HKLM:\SOFTWARE\NVIDIA Corporation\Global\NGXCore'
$name = 'ShowDlssIndicator'

if ($ShowOverlay) {
  sudo {
    if (!(Test-Path $args[0])) { New-Item $args[0] | Out-Null }
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
  $version = Get-ChildItem "$env:ALLUSERSPROFILE\NVIDIA\NGX\models\dlss\versions" -Directory |
    Sort-Object { [long] $_.Name } -Descending | Select-Object -First 1
  $files = Join-Path $version.FullName 'files'
  $model = @(Get-ChildItem $files -File)
  if ($model.Count -ne 1) { throw "Expected exactly one file in $files, found $($model.Count)" }
  $backup = Join-Path $version.FullName "$($model[0].Name).default"
  $model = $model[0].FullName
}

if ($Dev) {
  $temp = Join-Path $env:TEMP 'streamline'
  $zip = Join-Path $temp 'streamline.zip'
  New-Item $temp -ItemType Directory -Force | Out-Null
  if (!(Test-Path $zip)) {
    $url = lastversion 'NVIDIA-RTX/Streamline' --assets --filter 'streamline-sdk-v[\d.]+\.zip$'
    curl.exe -sSL -o $zip $url
  }
  7z e $zip "-o$temp" 'bin/x64/development/nvngx_dlss.dll' -y | Out-Null
  if (!(Test-Path $backup)) { Copy-Item $model $backup }
  Copy-Item "$temp\nvngx_dlss.dll" $model
}

if ($Prod) {
  if (Test-Path $backup) { Move-Item $backup $model -Force }
}
