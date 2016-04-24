Param(
    $LabIPAddressPattern,
    $DNSServerIP,
    $Domain = "lab.local"
)
Set-StrictMode -Version Latest 
$ErrorActionPreference = "Stop"

# Rename Lab Interface
Get-NetAdapter -InterfaceIndex (Get-NetIPAddress -IPAddress $LabIPAddressPattern).InterfaceIndex | 
    Rename-NetAdapter -NewName Lab

# Ensure we use only the DNS server at $DNSServerIP
Set-DnsClientServerAddress -InterfaceIndex (
        (Get-NetIPAddress).InterfaceIndex
    ) -ServerAddress $DNSServerIP

 Set-DnsClientGlobalSetting -SuffixSearchList $Domain 

$Password = "Passw0rd" | ConvertTo-SecureString -asPlainText -Force
$Username = "Administrator" 
$Credential = New-Object PSCredential($Username, $Password)
Add-Computer -DomainName $Domain -Credential $Credential
