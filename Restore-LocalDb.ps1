function Restore-LocalDb {
    [CmdletBinding()]

    param (
        [ValidateScript({ (Test-Path $_) -and ([IO.Path]::IsPathRooted($_)) })]
        [string]
        $Bak,

        [ValidateScript({ (Test-Path $_) -and ([IO.Path]::IsPathRooted($_)) })]
        [string]
        $Dir,

        [ValidateNotNullOrEmpty()]
        [string]
        $Name
    )

    $bakFileName = [IO.Path]::GetFileNameWithoutExtension($Bak)

    $sql = "
        RESTORE DATABASE $($Name)
        FROM DISK = N'$($Bak)'
        WITH
            MOVE N'$($bakFileName)' TO N'$($Dir)/$($Name).mdf',
            MOVE N'$($bakFileName)_log' TO N'$($Dir)/$($Name)_log.ldf'"

    sqlcmd -S "(localdb)\MSSQLLocalDB" -Q $sql
}

