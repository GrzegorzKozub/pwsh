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
        $RestorePath,

        [string]
        $RestoreName,

        [switch]
        $Force
    )

    function GetId {
        return docker ps -a --filter "name = $($ContainerName)" --format "{{.ID}}"
    }

    $containerId = GetId

    if ($containerId) {
        if (!$Force) {
            Write-Error "Container $($ContainerName) already exists with ID $($containerId)"
            return
        }
        docker stop $containerId | Out-Null
        docker rm $containerId | Out-Null
    }

    docker run `
        --name "$($ContainerName)"`
        -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=$($SaPassword)" `
        -p "$($HostPort):1433" `
        -d "microsoft/mssql-server-linux:$($ImageTag)" | Out-Null

    if ($RestorePath -and $RestoreName) {
        $backupDir = "/var/opt/mssql/backup"
        $dataDir = "/var/opt/mssql/data"
        $restoreFile = [IO.Path]::GetFileNameWithoutExtension($RestorePath)

        $sql = "
            RESTORE DATABASE $($RestoreName)
            FROM DISK = N'$($backupDir)/$($restoreFile).bak'
            WITH
                MOVE N'$($restoreFile)' TO N'$($dataDir)/$($RestoreName).mdf',
                MOVE N'$($restoreFile)_log' TO N'$($dataDir)/$($RestoreName)_log.ldf'"

        docker exec -it $ContainerName mkdir $backupDir
        docker cp $RestorePath "$($ContainerName):$($backupDir)"

        Start-Sleep -Seconds 5

        docker exec -it $ContainerName /opt/mssql-tools/bin/sqlcmd `
            -S localhost -U sa -P $SaPassword -Q $sql | Out-Null
    }

    return GetId
}

Set-Alias mssql Init-MsSqlContainer

