Param(
    $Domain                    = "lab.local",
    $IISServiceAccountUsername = "LAB\iis_svc",
    $IISServiceAccountPassword = "Passw0rd",
    $Fqdn                      = "www.lab.local"
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "Installing IIS..."
Import-Module ServerManager 

Install-WindowsFeature Web-Server
Install-WindowsFeature Web-Mgmt-Console
Install-WindowsFeature Web-Basic-Auth
Install-WindowsFeature Web-Windows-Auth

Import-Module WebAdministration

$WebsiteRoot = "c:\Inetpub\WWWRoot"

# Remove default web site:
Remove-Item 'IIS:\Sites\Default Web Site' -Confirm:$false -Recurse

$WebRoot = Join-Path $WebsiteRoot $Fqdn
mkdir $WebRoot 

Write-Host "Creating AppPool..."
$appPool = New-WebAppPool -Name "$($Fqdn)_pool"

# http://www.iis.net/configreference/system.applicationhost/applicationpools/add/processmodel
$AppPool.processModel.identityType = 3 # 0: LocalSystem, 1: localservice, 2: NetworkService, 3: SpecificUser, 4: ApplicationPoolIdentity
$AppPool.processModel.userName = $IISServiceAccountUsername 
$AppPool.processModel.password = $IISServiceAccountPassword 

$appPool | Set-Item

Write-Host "Setting up www.lab.local..."
$WebSite = New-Website -Name $Fqdn `
                       -PhysicalPath $WebRoot `
                       -ApplicationPool ($AppPool.Name) `
                       -HostHeader $Fqdn
                       
"Hello World!" | Out-File "$WebRoot\index.html"

Set-WebConfigurationProperty -Filter /system.WebServer/security/authentication/anonymousAuthentication `
    -Name enabled -Value $false -Location $Fqdn
Set-WebConfigurationProperty -Filter /system.WebServer/security/authentication/windowsAuthentication `
    -Name enabled -Value $true -Location $Fqdn
Set-WebConfigurationProperty -Filter /system.webServer/security/authentication/windowsAuthentication `
    -Name useAppPoolCredentials -Value $true -Location $Fqdn            
