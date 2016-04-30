Set-StrictMode -Version Latest 
$ErrorActionPreference = "Stop"
$IPAddress  = "172.16.124.50"
$VagrantIPPattern = "10.0.*"

#
# Ensure AD and DNS use only the $IPAddress 
#

Get-NetIPConfiguration -InterfaceIndex (Get-NetIPAddress -IPAddress $VagrantIPPattern).InterfaceIndex |
    Get-NetConnectionProfile |
    Where IPv4Connectivity -ne "NoTraffic" |
    Set-DnsClient -RegisterThisConnectionsAddress:$false -Verbose

Get-NetAdapter -InterfaceIndex (Get-NetIPAddress -IPAddress $IPAddress).InterfaceIndex | 
    Rename-NetAdapter -NewName Lab


#
# Install AD features
#

Add-WindowsFeature "RSAT-AD-Tools"

Add-WindowsFeature -Name "ad-domain-services" -IncludeAllSubFeature -IncludeManagementTools 
Add-WindowsFeature -Name "dns" -IncludeAllSubFeature -IncludeManagementTools 
Add-WindowsFeature -Name "gpmc" -IncludeAllSubFeature -IncludeManagementTools 

# Force the DNS server to bind to $IPAddress
dnscmd dc01 /ResetListenAddresses $IPAddress

