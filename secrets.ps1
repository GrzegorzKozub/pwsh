param ([string[]] $Set)

$file = Join-Path $PSScriptRoot ".secrets"
$secrets = [ordered]@{}

if (Test-Path $file) {
  foreach ($line in Get-Content $file) {
    if (!$line) { continue }
    $name, $value = $line -split " ", 2
    $secrets[$name] = $value
  }
}

if ($Set) {
  $changed = $false
  foreach ($name in $Set) {
    $secure = Read-Host $name -AsSecureString
    if ($secure.Length -eq 0) { continue }
    $secrets[$name] = $secure | ConvertFrom-SecureString
    $changed = $true
  }
  if ($changed) {
    $secrets.GetEnumerator() | ForEach-Object { "$($_.Key) $($_.Value)" } | Set-Content $file
  }
}

foreach ($secret in $secrets.GetEnumerator()) {
  try {
    $secure = ConvertTo-SecureString $secret.Value -ErrorAction Stop
    Set-Item "Env:\$($secret.Key)" ([Net.NetworkCredential]::new("", $secure).Password) -ErrorAction Stop
  } catch {
    Write-Warning "Can't set $($secret.Key): $($_.Exception.Message)"
  }
}
