param (
  [Switch] $Backup,
  [Switch] $Restore
)

if ($Backup -eq $Restore) { throw "Can either backup or restore" }
if (Get-Process 'claude' -ErrorAction SilentlyContinue) { throw "Claude is running" }

$config = $env:CLAUDE_CONFIG_DIR ? $env:CLAUDE_CONFIG_DIR : "$env:USERPROFILE\.config\claude"
if (!(Test-Path $config)) { New-Item $config -ItemType Directory | Out-Null }

if (!$env:RESTIC_REPOSITORY) { $env:RESTIC_REPOSITORY = "D:\Snaps" }
if (!(Test-Path $env:RESTIC_REPOSITORY)) { New-Item $env:RESTIC_REPOSITORY -ItemType Directory | Out-Null }

if ($Backup) {

  if (!(Get-ChildItem $env:RESTIC_REPOSITORY -Force -ErrorAction SilentlyContinue)) {
    restic init --quiet
    if ($LASTEXITCODE) { throw "restic init failed" }
  }

  restic backup --quiet --skip-if-unchanged --tag 'claude' $config
  if ($LASTEXITCODE) { throw "restic backup failed" }

  restic forget `
    --keep-within-daily 7d --keep-within-weekly 21d --keep-within-monthly 3m `
    --prune --quiet --tag claude
  if ($LASTEXITCODE) { throw "restic forget failed" }

}

if ($Restore) {

  restic restore --delete --quiet --tag 'claude' --target $config `
    "latest:/$($config.Replace(':', '').Replace('\', '/'))" | Out-Null
  if ($LASTEXITCODE) { throw "restic restore failed" }

}
