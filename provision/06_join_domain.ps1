Param(
    $LabMacAddress,
    $DNSServerIP
)
Set-StrictMode -Version Latest 
$ErrorActionPreference = "Stop"

Set-DnsClientServerAddress -InterfaceIndex (
        (get-netadapter | ? { $_.MacAddress -eq $LabMacAddress }).InterfaceIndex
    ) -ServerAddress $DNSServerIP

$Domain = "lab.local"
$Password = "Passw0rd" | ConvertTo-SecureString -asPlainText -Force
$Username = "Administrator" 
$Credential = New-Object System.Management.Automation.PSCredential($Username, $Password)
Add-Computer -DomainName $Domain -Credential $Credential
