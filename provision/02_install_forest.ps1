Set-StrictMode -Version Latest 
$ErrorActionPreference = "Stop"

$domainname = "lab.local"
$netbiosName = "LAB" 

Import-Module ADDSDeployment 
Install-ADDSForest -CreateDnsDelegation:$false `
    -DatabasePath "C:\Windows\NTDS" `
    -DomainMode "Win2012" `
    -DomainName $domainname `
    -DomainNetbiosName $netbiosName `
    -ForestMode "Win2012" `
    -InstallDns:$true `
    -LogPath "C:\Windows\NTDS" `
    -NoRebootOnCompletion:$false `
    -SysvolPath "C:\Windows\SYSVOL" `
    -safemodeadministratorpassword (convertto-securestring "Password1" -asplaintext -force) `
    -Force:$true