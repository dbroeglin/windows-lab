Set-StrictMode -Version Latest 
$ErrorActionPreference = "Stop"

$user = [adsi]"WinNT://localhost/Administrator,user"
$user.SetPassword("Passw0rd")
$user.SetInfo()
