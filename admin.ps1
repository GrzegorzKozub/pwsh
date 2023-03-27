return [Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains "S-1-5-32-544"
