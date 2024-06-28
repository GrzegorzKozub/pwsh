Write-Host "styles:     " -NoNewline
Write-Host "normal, " -NoNewline
Write-Host "$([char]27)[1mbold$([char]27)[0m, " -NoNewline
Write-Host "$([char]27)[3mitalic$([char]27)[0m, " -NoNewline
Write-Host "$([char]27)[3;1mbold italic$([char]27)[0m, " -NoNewline
Write-Host "$([char]27)[4munderline$([char]27)[0m, " -NoNewline
Write-Host "$([char]27)[9mstrikethrough$([char]27)[0m, " -NoNewline
Write-Host "$([char]27)[5mblink$([char]27)[0m, " -NoNewline
Write-Host "$([char]27)[2mdim$([char]27)[0m, " -NoNewline
Write-Host "$([char]27)[7mreverse$([char]27)[0m"

Write-Host "ligatures:  == != === !== >= <= => ->"

Write-Host "nerd fonts:               "

Write-Host "emoji:      🙁 😐 🙂 👍 👎"
