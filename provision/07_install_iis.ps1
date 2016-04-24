Set-StrictMode -Version Latest 
$ErrorActionPreference = "Stop"

Import-Module ServerManager 

Install-WindowsFeature Web-Server
Install-WindowsFeature Web-Mgmt-Console
Install-WindowsFeature Web-Basic-Auth
Install-WindowsFeature Web-Windows-Auth

Import-Module WebAdministration

# --------------------------------------------------------------------
# Setting directory access
# --------------------------------------------------------------------
#$Command = "icacls $InetPubWWWRoot /grant BUILTIN\IIS_IUSRS:(OI)(CI)(RX) BUILTIN\Users:(OI)(CI)(RX)"
#cmd.exe /c $Command
#$Command = "icacls $InetPubLog /grant ""NT SERVICE\TrustedInstaller"":(OI)(CI)(F)"
#cmd.exe /c $Command

$websiteRoot = "c:\Inetpub\WWWRoot"
$fqdn    = "www.lab.local"

$webRoot = Join-Path $websiteRoot $fqdn
mkdir $webRoot 

$appPool = New-WebAppPool -Name "$($fqdn)_pool"

# http://www.iis.net/configreference/system.applicationhost/applicationpools/add/processmodel
$appPool.processModel.identityType = 0 # 0: LocalSystem, 1: localservice: 
$appPool.processModel.userName = "LocalSystem"
#$appPool.processModel.password = ""
$appPool | Set-Item


$website = New-Website -Name $fqdn `
                       -PhysicalPath $webRoot `
                       -ApplicationPool ($appPool.Name) `
                       -HostHeader $fqdn
                       
"Hello World!" | Out-File "$webRoot\index.html"

Set-WebConfigurationProperty -filter /system.WebServer/security/authentication/windowsAuthentication `
            -name enabled -value true -location $fqdn
Set-WebConfigurationProperty -filter /system.WebServer/security/authentication/anonymousAuthentication `
            -name enabled -value false -location $fqdn
            
setspn -S http/www.lab.local web01