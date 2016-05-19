#
# Note: This needs to be in it's own provisioning script. When put 
# at the end of 03_populate_AD.ps1 the Add-DnsServerPrimaryZone 
# command fails.
#

# Setup an external domain name
Get-DnsServerDiagnostics
Add-DnsServerPrimaryZone -Name "extlab.local" -ReplicationScope "Domain"

# External website name
Add-DnsServerResourceRecord -ZoneName extlab.local -A -Name www -IPv4Address 172.16.124.12

# External aaa name
Add-DnsServerResourceRecord -ZoneName extlab.local -A -Name aaa -IPv4Address 172.16.124.13

# ADFS name
Add-DnsServerResourceRecord -ZoneName extlab.local -A -Name adfs -IPv4Address 172.16.124.50 # dc01 for now
