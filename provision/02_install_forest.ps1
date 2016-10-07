Param(
    $DomainName                    = "lab.local",
    $NetbiosName                   = "LAB",
    $SafeModeAdministratorPassword = "Password1",
    $MarkerFilename                = "$emv:TEMP\ADDS-FOREST.mark"
)
Set-StrictMode -Version Latest 
$ErrorActionPreference = "Stop"

if (Test-Path $MarkerFilename) {
    Write-Host "We re-entered ADDS Forest installation! Exiting..."
    return
}

Import-Module ADDSDeployment

Write-Host "Starting ADDS Forest installation..." 
Install-ADDSForest `
    -DatabasePath "C:\Windows\NTDS" `
    -DomainMode "Win2012R2" `
    -DomainName $DomainName `
    -DomainNetbiosName $NetbiosName `
    -ForestMode "Win2012R2" `
    -InstallDns `
    -LogPath "C:\Windows\NTDS" `
    -SysvolPath "C:\Windows\SYSVOL" `
    -safemodeadministratorpassword (ConvertTo-SecureString $SafeModeAdministratorPassword -asplaintext -force) `
    -Force

"Done" | Out-File $MarkerFilename

Write-Host "Start sleeping until reboot to prevent vagrant connection failures..."
Start-Sleep 180