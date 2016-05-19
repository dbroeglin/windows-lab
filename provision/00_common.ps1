Param(
    $LabIPAddressPattern = "172.16.124.*",
    $VagrantIPPattern    = "10.0.*"
)
Set-StrictMode -Version Latest 
$ErrorActionPreference = "Stop"

# Set local administrator password
$user = [adsi]"WinNT://localhost/Administrator,user"
$user.SetPassword("Passw0rd")
$user.SetInfo()

# Rename the LAB interface
Get-NetAdapter -InterfaceIndex (Get-NetIPAddress -IPAddress $LabIPAddressPattern).InterfaceIndex | 
    Rename-NetAdapter -NewName Lab

# Ensure the primary IP address setup by vagrant is not registered
Get-NetIPConfiguration -InterfaceIndex (Get-NetIPAddress -IPAddress $VagrantIPPattern).InterfaceIndex |
    Get-NetConnectionProfile |
    Where IPv4Connectivity -ne "NoTraffic" |
    Set-DnsClient -RegisterThisConnectionsAddress:$false -Verbose

# Install Sysinternals
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory("c:\Downloads\SysinternalsSuite.zip", "c:\Sysinternals")
