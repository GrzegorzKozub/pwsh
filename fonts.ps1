Write-Host "normal " -NoNewline

Write-Host "`e[1mbold`e[0m " -NoNewline
Write-Host "`e[2mdim`e[0m " -NoNewline
Write-Host "`e[3mitalic`e[0m " -NoNewline
Write-Host "`e[3;1mbold-italic`e[0m"

Write-Host "`e[4:1mstraight`e[0m " -NoNewline
Write-Host "`e[4:2mdouble`e[0m " -NoNewline
Write-Host "`e[4:3mcurly`e[0m " -NoNewline
Write-Host "`e[4:4mdotted`e[0m " -NoNewline
Write-Host "`e[4:5mdashed`e[0m"

Write-Host "`e[5mblink`e[0m " -NoNewline
Write-Host "`e[7mreverse`e[0m " -NoNewline
Write-Host "`e[9mstrikethrough`e[0m"

Write-Host "`e]8;;http://archlinux.org`e\link`e]8;;`e\"

Write-Host "== != === !== >= <= => ->"
Write-Host "              "
Write-Host "🙁 😐 🙂 👍 👎"

Write-Host
