function Copy-ReleaseNotes {
    [CmdletBinding()]

    param (

        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $TfsServerAddress = "http://tfs:80/tfs/Apsis",

        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SourceLocation = "$/ANP/RC",

        [Parameter(Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Applications = "Web",

        [Parameter(Position = 3, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Version
    )

    Add-PSSnapin Microsoft.TeamFoundation.PowerShell

    Write-Verbose "Getting TFS server at $TfsServerAddress."

    $tfsServer = Get-TfsServer -Name $TfsServerAddress

    Write-Verbose "Getting Changesets from $SourceLocation versions $Version."

    $changesets = Get-TfsItemHistory -Server $tfsServer -HistoryItem $SourceLocation -Version $Version -Recurse -All `
        | Format-List -Property `
            @{ Name = "Changeset"; Expression = { [String]::Format("{0}, {1}, {2}", $_.ChangesetId, $_.CreationDate, $_.OwnerDisplayName) } }, `
            Comment, `
            @{ Name = "Work Items"; Expression = { [String]::Join(", ", ($_.WorkItems | ForEach-Object { $_.Id })) } } `
        | Out-String

    Write-Verbose "Getting linked Work Items."

    $workItems = Get-TfsItemHistory -Server $tfsServer -HistoryItem $SourceLocation -Version $Version -Recurse -All `
        | Select-Object -Property WorkItems -ExpandProperty WorkItems `
        | Sort-Object -Property Id -Unique `
        | Format-List -Property `
            @{ Name = "Work Item"; Expression = { [String]::Format("{0}, {1}, created by {2}", $_.Id, $_.State, $_.CreatedBy) } }, `
            Title `
        | Out-String

    $environment = switch -Wildcard ($SourceLocation) {
        "*/ANP/RC*" { "rc.anpdm.com" }
        "*/Team Maintenance*" { "tm.anpdm.com" }
        "*/Team 1*" { "t1.anpdm.com" }
        "*/Team 2*" { "t2.anpdm.com" }
    }

    Write-Verbose "Deployment target is $environment ($Applications)."

    $messageTemplate = "$environment ($Applications) was updated from $SourceLocation code with the following Changesets:

{0}


Here is the list of Work Items affected by this deployment:

{1}"

    [String]::Format($messageTemplate, $changesets.Trim(), $workItems.Replace("Title     :", "Title          :").Trim()) | clip

    Write-Verbose "Release notes were copied to your clipboard."
}

Set-Alias cprn Copy-ReleaseNotes

