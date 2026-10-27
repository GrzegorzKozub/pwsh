param (
  [Parameter(Mandatory, Position = 0)]
  [ValidateSet('Brave', 'Claude')]
  [String] $Name,
  [Switch] $Backup,
  [Switch] $Restore,
  [String[]] $Skip
)

if ($Backup -eq $Restore) { throw 'Can either backup or restore' }

$proc, $tag, $path = switch ($Name) {
  'Brave' {
    'brave',
    'brave',
    (Join-Path 'D:' $env:LOCALAPPDATA.TrimStart('C:') 'BraveSoftware\Brave-Origin\User Data')
  }
  'Claude' {
    'claude',
    'claude',
    ($env:CLAUDE_CONFIG_DIR ? $env:CLAUDE_CONFIG_DIR : (Join-Path $env:USERPROFILE '.config\claude'))
  }
}

if (Get-Process $proc -ErrorAction SilentlyContinue) { throw "$Name is running" }

if (!$env:RESTIC_REPOSITORY) { $env:RESTIC_REPOSITORY = 'D:\Snaps' }

if ($Backup) {

  if (!(Test-Path $path)) { throw "$path does not exist" }

  if (!(Test-Path $env:RESTIC_REPOSITORY)) {
    restic init --quiet
    if ($LASTEXITCODE) { throw 'restic init failed' }
  }

  if ($Name -eq 'Brave') { & "$PSScriptRoot\cache.ps1" Brave }

  restic backup --quiet --skip-if-unchanged --tag $tag $path
  if ($LASTEXITCODE) { throw 'restic backup failed' }

  restic forget `
    --keep-within-daily 7d --keep-within-weekly 21d --keep-within-monthly 3m `
    --prune --quiet --tag $tag
  if ($LASTEXITCODE) { throw 'restic forget failed' }

}

if ($Restore) {

  $exclude = @(foreach ($s in $Skip) { '--exclude', $s })

  restic restore --delete --quiet --tag $tag --target $path @exclude `
    "latest:/$($path.Replace(':', '').Replace('\', '/'))" | Out-Null
  if ($LASTEXITCODE) { throw 'restic restore failed' }

}
