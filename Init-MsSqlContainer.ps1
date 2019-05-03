# https://docs.microsoft.com/en-us/sql/linux/tutorial-restore-backup-in-sql-server-container

function Init-MsSqlContainer {
    [CmdletBinding()]

    param (
        [ValidateNotNullOrEmpty()]
        [string]
        $SaPassword = "p@ssw0rd",

        [ValidateNotNullOrEmpty()]
        [int]
        $HostPort = 1433,

        [ValidateNotNullOrEmpty()]
        [string]
        $ImageTag = "latest",

        [ValidateNotNullOrEmpty()]
        [string]
        $ContainerName = "mssql",

        [ValidateScript({ Test-Path $_ })]
        [string]
        $RestoreBackup,

        [string]
        $RestoreAs,

        [switch]
        $Force
    )

    Invoke-Expression ". $(Join-Path (Split-Path $PROFILE) 'Docker.ps1')"
    HandleExistingContainer $ContainerName $Force   

    docker run `
        --name "$($ContainerName)"`
        -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=$($SaPassword)" `
        -p "$($HostPort):1433" `
        -d `
        "microsoft/mssql-server-linux:$($ImageTag)" | Out-Null

    if ($RestoreBackup -and $RestoreAs) {
        $backupDir = "/var/opt/mssql/backup"
        $dataDir = "/var/opt/mssql/data"
        $restoreFile = [IO.Path]::GetFileNameWithoutExtension($RestoreBackup)

        $sql = "
            RESTORE DATABASE $($RestoreAs)
            FROM DISK = N'$($backupDir)/$($restoreFile).bak'
            WITH
                MOVE N'$($restoreFile)' TO N'$($dataDir)/$($RestoreAs).mdf',
                MOVE N'$($restoreFile)_log' TO N'$($dataDir)/$($RestoreAs)_log.ldf'"

        docker exec -it $ContainerName mkdir $backupDir
        docker cp $RestoreBackup "$($ContainerName):$($backupDir)"

        Start-Sleep -Seconds 5

        docker exec -it $ContainerName /opt/mssql-tools/bin/sqlcmd `
            -S localhost -U sa -P $SaPassword -Q $sql | Out-Null
    }

    return GetContainerId $ContainerName
}

Set-Alias mssql Init-MsSqlContainer

