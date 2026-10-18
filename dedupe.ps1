$file = (Get-PSReadLineOption).HistorySavePath
$unique = [System.Collections.Generic.HashSet[string]]::new(
  [StringComparer]::OrdinalIgnoreCase
)
(Get-Content $file) | `
  Where-Object { $unique.Add($_) } | `
  Set-Content $file -Force
