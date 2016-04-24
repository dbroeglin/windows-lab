$ErrorActionPreference = "Stop"

# Sets registry keys so that all users have http://*.lab.local as a "Local Site" in Internet Explorer"

$InternetSettings = 'HKLM:Software\Policies\Microsoft\Windows\CurrentVersion\Internet Settings'
$Domains          = "$InternetSettings\ZoneMap\Domains" 
$Domain           = "$Domains\lab.local"

mkdir -Force $Domains
Set-ItemProperty -Path $InternetSettings -Name Security_HKLM_only -Value 1 -Type DWORD
if (-not (Test-Path -Path $Domain))
{
    $null = New-Item -Path $Domain
}
Set-ItemProperty -Path $Domain -Name http  -Value 1 -Type DWord
Set-ItemProperty -Path $Domain -Name https -Value 1 -Type DWord

# Trust the aaa.extlab.local certiciate used by Netscaler
Import-PfxCertificate c:\vagrant\test\aaa.extlab.local.pfx `
    -CertStoreLocation Cert:\LocalMachine\Root `
    -Password (ConvertTo-SecureString -AsPlainText -String "Passw0rd" -Force)

msiexec.exe /i "c:\downloads\googlechromestandaloneenterprise.msi" NOGOOGLEUPDATEPING=1 /l*v c:\vagrant\test\chrome_install.log /q /norestart  
