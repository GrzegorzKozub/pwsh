Import-Module Docker

function Docker-MsSqlContainer {
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

    [switch]
    $Force
  )

  HandleExistingContainer $ContainerName $Force   

  docker run `
    --name "$ContainerName"`
    -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=$SaPassword" `
    -p "$($HostPort):1433" `
    -d `
    "microsoft/mssql-server-linux:$ImageTag" | Out-Null

  return GetContainerId $ContainerName
}

Set-Alias mssql Docker-MsSqlContainer

