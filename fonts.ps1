Write-Host "normal " -NoNewline

Write-Host "$([char]27)[1mbold$([char]27)[0m " -NoNewline
Write-Host "$([char]27)[2mdim$([char]27)[0m " -NoNewline
Write-Host "$([char]27)[3mitalic$([char]27)[0m " -NoNewline
Write-Host "$([char]27)[3;1mbold-italic$([char]27)[0m"

Write-Host "$([char]27)[4:1mstraight$([char]27)[0m " -NoNewline
Write-Host "$([char]27)[4:2mdouble$([char]27)[0m " -NoNewline
Write-Host "$([char]27)[4:3mcurly$([char]27)[0m " -NoNewline
Write-Host "$([char]27)[4:4mdotted$([char]27)[0m " -NoNewline
Write-Host "$([char]27)[4:5mdashed$([char]27)[0m"

Write-Host "$([char]27)[5mblink$([char]27)[0m " -NoNewline
Write-Host "$([char]27)[7mreverse$([char]27)[0m " -NoNewline
Write-Host "$([char]27)[9mstrikethrough$([char]27)[0m"

Write-Host "$([char]27)]8;;http://archlinux.org$([char]27)\link$([char]27)]8;;$([char]27)\"

Write-Host "== != === !== >= <= => ->"
Write-Host "              "
Write-Host "🙁 😐 🙂 👍 👎"

Write-Host
