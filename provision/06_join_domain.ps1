Param(
    $LabIPAddressPattern,
    $DCIPAddress,
    $Domain = "lab.local"
)
Set-StrictMode -Version Latest 
$ErrorActionPreference = "Stop"

Write-Host "Renaming lab interface to 'Lab'..."
Get-NetAdapter -InterfaceIndex (Get-NetIPAddress -IPAddress $LabIPAddressPattern).InterfaceIndex | 
    Rename-NetAdapter -NewName Lab

Write-Host "Setting DNS server to $DCIPAddress..."
Set-DnsClientServerAddress -InterfaceIndex (
        (Get-NetIPAddress).InterfaceIndex
    ) -ServerAddress $DCIPAddress

Set-DnsClientGlobalSetting -SuffixSearchList $Domain 

Write-Host "Joining domain..."
$Password = "Passw0rd" | ConvertTo-SecureString -asPlainText -Force
$Username = "Administrator" 
$Credential = New-Object PSCredential($Username, $Password)
Add-Computer -DomainName $Domain -Credential $Credential
