function Attach-LocalDb {
    [CmdletBinding()]

    param (
        [ValidateScript({ (Test-Path $_) -and ([IO.Path]::IsPathRooted($_)) })]
        [string]
        $Dir,

        [ValidateNotNullOrEmpty()]
        [string]
        $Name
    )

    $sql = "
        CREATE DATABASE $($Name) ON
            (FILENAME = N'$($Dir)/$($Name).mdf'),
            (FILENAME = N'$($Dir)/$($Name)_log.ldf')
        FOR ATTACH"

    sqlcmd -S "(localdb)\MSSQLLocalDB" -Q $sql
}

