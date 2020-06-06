Import-Module Docker

function Docker-PostgresContainer {
  param (
    [ValidateNotNullOrEmpty()] [string] $Database = "postgres",
    [ValidateNotNullOrEmpty()] [string] $User = "postgres",
    [ValidateNotNullOrEmpty()] [string] $Password = "postgres",
    [ValidateNotNullOrEmpty()] [int] $HostPort = 5432,
    [ValidateNotNullOrEmpty()] [string] $ImageTag = "latest",
    [ValidateNotNullOrEmpty()] [string] $ContainerName = "postgres",
    [switch] $Force
  )

  HandleExistingContainer $ContainerName $Force   

  docker run `
    --name "$ContainerName"`
    -e "POSTGRES_DB=$Database" -e "POSTGRES_USER=$User" -e "POSTGRES_PASSWORD=$Password" `
    -p "$($HostPort):5432" `
    -d `
    "postgres:$ImageTag" | Out-Null

  return GetContainerId $ContainerName
}

Set-Alias postgres Docker-PostgresContainer

