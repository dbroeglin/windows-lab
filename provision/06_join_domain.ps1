Param(
    $LabIPAddressPattern,
    $DNSServerIP
)
Set-StrictMode -Version Latest 
$ErrorActionPreference = "Stop"


# Ensure we use only the DNS server at $DNSServerIP
Set-DnsClientServerAddress -InterfaceIndex (
        (Get-NetIPAddress).InterfaceIndex
    ) -ServerAddress $DNSServerIP

$Domain = "lab.local"
$Password = "Passw0rd" | ConvertTo-SecureString -asPlainText -Force
$Username = "Administrator" 
$Credential = New-Object PSCredential($Username, $Password)
Add-Computer -DomainName $Domain -Credential $Credential
