Param(
    $LabIPAddressPattern,
    $DNSServerIP
)
Set-StrictMode -Version Latest 
$ErrorActionPreference = "Stop"

Set-DnsClientServerAddress -InterfaceIndex (
        (Get-NetIPAddress -IPAddress $LabIPAddressPattern).InterfaceIndex
    ) -ServerAddress $DNSServerIP

$Domain = "lab.local"
$Password = "Passw0rd" | ConvertTo-SecureString -asPlainText -Force
$Username = "Administrator" 
$Credential = New-Object PSCredential($Username, $Password)
Add-Computer -DomainName $Domain -Credential $Credential
