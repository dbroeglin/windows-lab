Param(
    $IPAddress  = "172.16.124.50"
)
Set-StrictMode -Version Latest 
$ErrorActionPreference = "Stop"

#
# Install AD features
#

Add-WindowsFeature "RSAT-AD-Tools"

Add-WindowsFeature -Name "ad-domain-services" -IncludeAllSubFeature -IncludeManagementTools 
Add-WindowsFeature -Name "dns" -IncludeAllSubFeature -IncludeManagementTools 
Add-WindowsFeature -Name "gpmc" -IncludeAllSubFeature -IncludeManagementTools 

# Force the DNS server to bind to $IPAddress
dnscmd dc01 /ResetListenAddresses $IPAddress

