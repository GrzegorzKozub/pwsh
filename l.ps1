$tempFile = New-TemporaryFile
&lf -last-dir-path $tempFile.FullName
if (Test-Path -PathType Leaf $tempFile) {
  $dir = Get-Content -Path $tempFile
  Remove-Item -Path $tempFile
  if ((Test-Path -PathType Container "$dir") -and "$dir" -ne "$pwd") {
    Set-Location -Path "$dir"
  }
}
