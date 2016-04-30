Param(
    $LabIPAddressPattern,
    $DNSServerIP,
    $VagrantIPAddressPattern = "10.0.*",
    $Domain = "lab.local"
)
Set-StrictMode -Version Latest 
$ErrorActionPreference = "Stop"

# Do not publish IPs that are not part of the lab
Get-NetIPConfiguration -InterfaceIndex (Get-NetIPAddress -IPAddress $VagrantIPAddressPattern).InterfaceIndex |
    Get-NetConnectionProfile |
    Where IPv4Connectivity -ne "NoTraffic" |
    Set-DnsClient -RegisterThisConnectionsAddress:$false -Verbose

# Ensure we use only the DNS server at $DNSServerIP
Set-DnsClientServerAddress -InterfaceIndex (
        (Get-NetIPAddress).InterfaceIndex
    ) -ServerAddress $DNSServerIP

 Set-DnsClientGlobalSetting -SuffixSearchList $Domain 

$Password = "Passw0rd" | ConvertTo-SecureString -asPlainText -Force
$Username = "Administrator" 
$Credential = New-Object PSCredential($Username, $Password)
Add-Computer -DomainName $Domain -Credential $Credential
