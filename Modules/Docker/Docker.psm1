function GetContainerId ($containerName) {
    return docker ps -a --filter "name = $containerName" --format "{{.ID}}"
}

function HandleExistingContainer ($containerName, $remove) {
    $containerId = GetContainerId $containerName
    if (!$containerId) { return }
    if ($remove) {
        docker stop $containerId | Out-Null
        docker rm $containerId | Out-Null
    } else {
        throw "Container $containerName already exists with ID $containerId"
    }
}

