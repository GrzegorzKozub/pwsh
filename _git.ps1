# _git.ps1 - lightweight native git tab-completion for PowerShell
# Dot-source or Import this from your $PROFILE:
#   . "$HOME\_git.ps1"
# No modules, no prompt changes - just Register-ArgumentCompleter for `git`.

$script:GitSubcommands = @(
    'add','am','apply','archive','bisect','blame','branch','bundle','checkout',
    'cherry','cherry-pick','clean','clone','commit','config','describe','diff',
    'fetch','filter-branch','format-patch','fsck','gc','grep','init','log','merge',
    'mv','notes','prune','pull','push','rebase','reflog','remote','reset','restore',
    'rev-parse','revert','rm','shortlog','show','sparse-checkout','stash','status',
    'submodule','switch','tag','worktree'
) | Select-Object -Unique

function script:Get-GitBranches {
    param([switch]$IncludeRemote)
    $fmt = if ($IncludeRemote) { '--all' } else { '--list' }
    git branch $fmt --format='%(refname:short)' 2>$null
}

function script:Get-GitTags {
    git tag -l 2>$null
}

function script:Get-GitRemotes {
    git remote 2>$null
}

function script:Get-GitStashes {
    git stash list --format='%gd' 2>$null
}

function script:Get-GitRefs {
    # branches + tags, deduped - used for checkout/merge/rebase/reset/diff/log/show/cherry-pick/revert
    (Get-GitBranches -IncludeRemote) + (Get-GitTags) | Select-Object -Unique
}

function script:Get-GitWorktreePaths {
    git worktree list --porcelain 2>$null |
        Where-Object { $_ -like 'worktree *' } |
        ForEach-Object { $_.Substring(10) }
}

function script:Get-GitTrackedFiles {
    git ls-files 2>$null
}

function script:Get-GitStatusFiles {
    # returns objects with .Code (XY porcelain status) and .Path
    git status --porcelain=v1 2>$null | ForEach-Object {
        $code = $_.Substring(0, 2)
        $path = $_.Substring(3)
        if ($path -match ' -> ') { $path = ($path -split ' -> ')[-1] }
        [PSCustomObject]@{ Code = $code; Path = $path }
    }
}

function script:Get-GitUnstagedFiles {
    Get-GitStatusFiles | Where-Object { $_.Code[1] -in 'M', 'D' } | ForEach-Object { $_.Path }
}

function script:Get-GitStagedFiles {
    Get-GitStatusFiles | Where-Object { $_.Code[0] -in 'M', 'A', 'D', 'R', 'C' } | ForEach-Object { $_.Path }
}

function script:Get-GitUntrackedFiles {
    Get-GitStatusFiles | Where-Object { $_.Code -eq '??' } | ForEach-Object { $_.Path }
}

function script:Get-GitAddableFiles {
    (Get-GitUnstagedFiles) + (Get-GitUntrackedFiles) + (Get-GitStagedFiles) | Select-Object -Unique
}

function script:Get-GitPatchFiles {
    Get-ChildItem -Path . -Filter *.patch -File -ErrorAction SilentlyContinue |
        ForEach-Object { $_.Name }
    Get-ChildItem -Path . -Filter *.diff -File -ErrorAction SilentlyContinue |
        ForEach-Object { $_.Name }
}

function script:New-Completion {
    param([string]$Text, [string]$Tooltip = $Text)
    [System.Management.Automation.CompletionResult]::new($Text, $Text, 'ParameterValue', $Tooltip)
}

Register-ArgumentCompleter -Native -CommandName git -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)

    $elems = $commandAst.CommandElements
    # if the cursor is still inside/at the last element, that element is the word
    # being typed right now (not yet a "completed" argument) - exclude it, otherwise
    # (e.g. trailing space) every element so far is a completed argument.
    $cursorInLastElement = $elems.Count -gt 0 -and $cursorPosition -le $elems[$elems.Count - 1].Extent.EndOffset
    $completedCount = if ($cursorInLastElement) { $elems.Count - 1 } else { $elems.Count }
    $completed = if ($completedCount -gt 0) { $elems[0..($completedCount - 1)] | ForEach-Object { $_.Extent.Text } } else { @() }
    # drop leading 'git'
    $args = if ($completed.Count -gt 1) { $completed[1..($completed.Count - 1)] } else { @() }
    $sub  = $args | Select-Object -First 1
    $wtc  = [regex]::Escape($wordToComplete)

    $candidates = @()

    if ($completed.Count -le 1) {
        # completing the subcommand itself (nothing after 'git' completed yet)
        $candidates = $script:GitSubcommands
    }
    else {
        switch ($sub) {
            { $_ -in 'checkout','switch' } {
                $candidates = @('-b','-B','--detach','--track','--orphan') + (Get-GitRefs)
            }
            'branch' {
                if ($args -contains '-d' -or $args -contains '-D' -or $args -contains '-m' -or $args -contains '-M') {
                    $candidates = Get-GitBranches
                } else {
                    $candidates = @('-a','-r','-d','-D','-m','-M','--list','--set-upstream-to=','--track','--unset-upstream') + (Get-GitBranches)
                }
            }
            { $_ -in 'merge','rebase','cherry-pick','revert','diff','show','log' } {
                $extra = switch ($sub) {
                    'rebase'      { @('-i','--interactive','--onto','--continue','--abort','--skip') }
                    'log'         { @('--oneline','--graph','--stat','-p','--all','-n') }
                    'cherry-pick' { @('--continue','--abort','--skip','-n','--no-commit') }
                    'revert'      { @('--continue','--abort','--skip','-n','--no-commit') }
                    default       { @() }
                }
                $candidates = $extra + (Get-GitRefs)
            }
            'reset' {
                $candidates = @('--hard','--soft','--mixed','--keep','--merge','HEAD','HEAD~1','HEAD^') + (Get-GitRefs)
            }
            { $_ -in 'push','pull','fetch' } {
                $remotes = Get-GitRemotes
                # arg immediately after remote name -> branch; else remote / flags
                if ($args.Count -ge 2 -and ($remotes -contains $args[1])) {
                    $candidates = Get-GitBranches
                } else {
                    $flags = switch ($sub) {
                        'push'  { @('--force','--force-with-lease','--set-upstream','-u','--tags','--delete','--all') }
                        'pull'  { @('--rebase','--ff-only','--no-rebase') }
                        'fetch' { @('--all','--prune','--tags') }
                    }
                    $candidates = $flags + $remotes
                }
            }
            'remote' {
                $sub2 = $args | Select-Object -Skip 1 -First 1
                if (-not $sub2) {
                    $candidates = @('add','remove','rename','set-url','show','prune','get-url','update','-v')
                }
                else {
                    $candidates = Get-GitRemotes
                }
            }
            'tag' {
                $candidates = @('-a','-d','-l','--list','-f') + (Get-GitTags)
            }
            'stash' {
                $sub2 = $args | Select-Object -Skip 1 -First 1
                if (-not $sub2) {
                    $candidates = @('push','pop','apply','drop','list','show','branch','clear','-u','--include-untracked')
                }
                elseif ($sub2 -in @('pop','apply','drop','show','branch')) {
                    $candidates = Get-GitStashes
                }
                else {
                    $candidates = @()
                }
            }
            'worktree' {
                $sub2 = $args | Select-Object -Skip 1 -First 1
                if (-not $sub2) {
                    $candidates = @('add','list','remove','lock','unlock','move','prune','repair')
                }
                elseif ($sub2 -eq 'add') {
                    $candidates = Get-GitRefs
                }
                elseif ($sub2 -in @('remove','lock','unlock','move')) {
                    $candidates = Get-GitWorktreePaths
                }
                else {
                    $candidates = @()
                }
            }
            'prune' {
                $candidates = @('--dry-run','--verbose', 'now')
            }
            'commit' {
                $candidates = @('-m','-am','--amend','--no-edit','--fixup','--squash','-a','--all')
            }
            'add' {
                $candidates = @('-A','--all','-p','--patch','-u','--update','.') + (Get-GitAddableFiles)
            }
            'clean' {
                $candidates = @('-n','--dry-run','-f','--force','-d','-x','-fd')
            }
            'config' {
                $candidates = @('--global','--local','--system','--get','--list','-l')
            }
            'rm' {
                $candidates = @('--cached','-r','-f','--force') + (Get-GitTrackedFiles)
            }
            'mv' {
                $candidates = @('-f','--force') + (Get-GitTrackedFiles)
            }
            'restore' {
                if ($args -contains '--staged') {
                    $candidates = @('--staged','--worktree','--source=') + (Get-GitStagedFiles)
                } else {
                    $candidates = @('--staged','--worktree','--source=') + (Get-GitUnstagedFiles)
                }
            }
            'apply' {
                $candidates = @('--check','--stat','--index','--cached','--reverse','-3','--3way') + (Get-GitPatchFiles)
            }
            'am' {
                $candidates = @('--continue','--skip','--abort','--show-current-patch') + (Get-GitPatchFiles)
            }
            'blame' {
                $candidates = @('-L','-e','--line-porcelain','-w') + (Get-GitTrackedFiles)
            }
            'grep' {
                $candidates = @('-n','-i','-l','--cached','-w','-c')
            }
            'describe' {
                $candidates = @('--tags','--all','--long','--abbrev=') + (Get-GitRefs)
            }
            'archive' {
                $candidates = @('--format=tar','--format=zip','-o','--prefix=') + (Get-GitRefs)
            }
            'bundle' {
                $sub2 = $args | Select-Object -Skip 1 -First 1
                if (-not $sub2) {
                    $candidates = @('create','verify','list-heads','unbundle')
                }
                elseif ($sub2 -eq 'create') {
                    $candidates = Get-GitRefs
                }
                else {
                    $candidates = @()
                }
            }
            'bisect' {
                $candidates = @('start','good','bad','skip','reset','log','run','visualize') + (Get-GitRefs)
            }
            'notes' {
                $sub2 = $args | Select-Object -Skip 1 -First 1
                if (-not $sub2) {
                    $candidates = @('add','append','copy','edit','show','list','remove','prune')
                } else {
                    $candidates = Get-GitRefs
                }
            }
            'reflog' {
                $sub2 = $args | Select-Object -Skip 1 -First 1
                if (-not $sub2) {
                    $candidates = @('show','list','expire','delete') + (Get-GitRefs)
                } else {
                    $candidates = Get-GitRefs
                }
            }
            'rev-parse' {
                $candidates = @('--abbrev-ref','--show-toplevel','--is-inside-work-tree','--verify') + (Get-GitRefs)
            }
            'cherry' {
                $candidates = @('-v') + (Get-GitRefs)
            }
            'format-patch' {
                $candidates = @('-1','--stdout','--cover-letter','-o') + (Get-GitRefs)
            }
            'filter-branch' {
                $candidates = @('--tree-filter','--index-filter','--msg-filter','--env-filter','--','--force') + (Get-GitRefs)
            }
            'shortlog' {
                $candidates = @('-s','-n','-e') + (Get-GitRefs)
            }
            'submodule' {
                $sub2 = $args | Select-Object -Skip 1 -First 1
                if (-not $sub2) {
                    $candidates = @('add','status','init','update','deinit','sync','foreach','absorbgitdirs')
                } else {
                    $candidates = @()
                }
            }
            'sparse-checkout' {
                $sub2 = $args | Select-Object -Skip 1 -First 1
                if (-not $sub2) {
                    $candidates = @('list','init','set','add','disable','reapply','check-rules')
                } else {
                    $candidates = @()
                }
            }
            'status' {
                $candidates = @('-s','--short','-b','--branch','--porcelain','-u','--untracked-files')
            }
            'gc' {
                $candidates = @('--aggressive','--prune','--auto')
            }
            'fsck' {
                $candidates = @('--full','--unreachable','--lost-found')
            }
            'init' {
                $candidates = @('--bare','--initial-branch=','-q')
            }
            'clone' {
                $candidates = @('--depth','--branch','--bare','--recursive','--recurse-submodules','--single-branch')
            }
            default {
                $candidates = @()
            }
        }
    }

    $candidates |
        Where-Object { $_ -and $_ -match "^$wtc" } |
        Sort-Object -Unique |
        ForEach-Object { script:New-Completion $_ }
}
