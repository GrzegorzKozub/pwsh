Get-ChildItem $(Join-Path $(Split-Path $PROFILE) *.ps1) `
    -Exclude $(Split-Path $PROFILE.CurrentUserAllHosts -Leaf), $(Split-Path $PROFILE.CurrentUserCurrentHost -Leaf) |
    ForEach-Object { . $_ }

Import-Module posh-git
