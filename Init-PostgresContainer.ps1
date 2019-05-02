function Init-PostgresContainer {
    [CmdletBinding()]

    param (
        [ValidateNotNullOrEmpty()]
        [string]
        $Database = "postgres",

        [ValidateNotNullOrEmpty()]
        [string]
        $User = "postgres",

        [ValidateNotNullOrEmpty()]
        [string]
        $Password = "postgres",

        [ValidateNotNullOrEmpty()]
        [int]
        $HostPort = 5432,

        [ValidateNotNullOrEmpty()]
        [string]
        $ImageTag = "latest",

        [ValidateNotNullOrEmpty()]
        [string]
        $ContainerName = "postgres",

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
        -e "POSTGRES_DB=$($Database)" -e "POSTGRES_USER=$($User)" -e "POSTGRES_PASSWORD=$($Password)" `
        -p "$($HostPort):5432" `
        -d `
        "postgres:$($ImageTag)" | Out-Null

    return GetId
}

Set-Alias postgres Init-PostgresContainer

