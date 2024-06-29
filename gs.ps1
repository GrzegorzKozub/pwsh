if (!(Test-Path -Path ".git") -or !(Get-Command "git" -ErrorAction SilentlyContinue)) { return "" }

# https://git-scm.com/docs/git-status#_porcelain_format_version_2

$status = git status --branch --porcelain=2 --show-stash # --ignore-submodule

$untracked = 0
$staged = 0
$unstaged = 0

foreach ($line in $status) {
  if ($line -match "# branch.oid (.*)") {
    $commit = "`e[33m$(-join $Matches[1][0..7])`e[0m "
  }
  if ($line -match "# branch.head (.*)") {
    $branch = "`e[34m$($Matches[1])`e[0m "
  }
  if ($line -match "# branch.ab \+(.*) \-(.*)") {
    $ahead = if ($Matches[1] -gt 0) { "`e[32m↑$($Matches[1])`e[0m " } else { "" }
    $behind = if ($Matches[2] -gt 0) { "`e[33m↓$($Matches[2])`e[0m " } else { "" }
  }
  if ($line -match "# stash (.*)") {
    $stash = "`e[35m←$($Matches[1])`e[0m "
  }
  if ($line -match "\? .*") { $untracked++ }
  if ($line -match "[12] ([\.AMD])([\.AMD])") {
    if ($Matches[1] -ne ".") { $staged++ }
    if ($Matches[2] -ne ".") { $unstaged++ }
  }
}

if ($branch -match "(detached)") { $branchOrCommit = $commit } else { $branchOrCommit = $branch }

$staged = if ($staged -gt 0) { "`e[32m+$staged`e[0m " } else { "" }
$unstaged = if ($unstaged -gt 0) { "`e[33m~$unstaged`e[0m " } else { "" }
$untracked = if ($untracked -gt 0) { "`e[31m*$untracked`e[0m " } else { "" }

return " $branchOrCommit$behind$ahead$stash$staged$unstaged$untracked"