param (
  [ValidateNotNullOrEmpty()] [string] $GitHubUser = "GrzegorzKozub",
  [ValidateScript({ Test-Path $_ })] [string] $To = "E:\github"
)

function GetRepos {
  return (Invoke-WebRequest -Uri "https://api.github.com/users/$GitHubUser/repos" |
    ConvertFrom-Json) |
    Select-Object -Property `
      @{ Name = 'name'; Expression = { $_.name } }, `
      @{ Name = 'url'; Expression = { $_.ssh_url } }
}

function GetRepoVersion ($repoName) {
  return (Invoke-WebRequest -Uri "https://api.github.com/repos/$GitHubUser/$repoName/branches/master" |
    ConvertFrom-Json).commit.sha.Substring(0, 7)
}

function GetBackupVersion ($repoName) {
  $backups = Get-ChildItem -Path (GetBackupPath $repoName "*")
  if (!$backups) { return $null }
  return $backups[0].BaseName.Split(".")[2]
}

function GetTempPath ($repoName) {
  return "$(Join-Path -Path $env:TEMP -ChildPath $repoName).git"
}

function GetBackupPath ($repoName, $version) {
  return "$(Join-Path -Path $To -ChildPath $repoName).git.$version.zip"
}

function Clone ($url, $path) {
  git clone --bare --quiet $url $path
}

function Remove ($path) {
  Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
}

function Zip ($from, $to) {
  7z a $to $from | Out-Null
}

function StartTimer {
  return [Diagnostics.Stopwatch]::StartNew()
}

function StopTimer ($timer, $message) {
  $timer.Stop()
  Write-Host "$message in $($timer.Elapsed.ToString("mm\:ss\.fff"))" -ForegroundColor DarkGray
}

function Log ($repoName) {
  Write-Host "Processing " -NoNewLine
  Write-Host $repoName -ForegroundColor DarkCyan
}

$allTime = StartTimer

foreach ($repo in (GetRepos)) {
  $time = StartTimer
  Log $repo.name
  $backupVersion = GetBackupVersion $repo.name
  $repoVersion = GetRepoVersion $repo.name
  if ($backupVersion -eq $repoVersion) {
    Write-Host "Backup version $backupVersion is up to date" -ForegroundColor DarkGray
    continue
  }
  Write-Host "Updating backup to version $repoVersion" -ForegroundColor DarkGray
  $tempPath = GetTempPath $repo.name
  Remove $tempPath
  Remove (GetBackupPath $repo.name $backupVersion)
  Clone $repo.url $tempPath
  Zip $tempPath (GetBackupPath $repo.name $repoVersion)
  Remove $tempPath
  StopTimer $time "Done"
}

StopTimer $allTime "All done"

