Param(
    $DomainName                    = "lab.local",
    $NetbiosName                   = "LAB",
    $SafeModeAdministratorPassword = "Password1"
)
Set-StrictMode -Version Latest 
$ErrorActionPreference = "Stop"

Import-Module ADDSDeployment 
Install-ADDSForest -CreateDnsDelegation:$false `
    -DatabasePath "C:\Windows\NTDS" `
    -DomainMode "Win2012" `
    -DomainName $DomainName `
    -DomainNetbiosName $NetbiosName `
    -ForestMode "Win2012" `
    -InstallDns:$true `
    -LogPath "C:\Windows\NTDS" `
    -NoRebootOnCompletion:$false `
    -SysvolPath "C:\Windows\SYSVOL" `
    -safemodeadministratorpassword (ConvertTo-SecureString $SafeModeAdministratorPassword -asplaintext -force) `
    -Force:$true
