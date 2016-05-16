Param(
    $IISIPAddress                  = "172.16.124.51"
)
Set-StrictMode -Version Latest 
$ErrorActionPreference = "Stop"

Start-Sleep 15

Add-ADGroupMember -Identity "Domain Admins" -Members "vagrant"

# Client Users
Write-Host "Creating Alice Account..."
New-ADUser -Name "Alice" -GivenName Alice `
     -SamAccountName alice -UserPrincipalName alice@lab.local `
     -AccountPassword (convertto-securestring "Passw0rd" -asplaintext -force) `
     -PassThru | Enable-ADAccount

Write-Host "Creating Bob Account..."
New-ADUser -Name "Bob" -GivenName Alice `
     -SamAccountName bob -UserPrincipalName bob@lab.local `
     -AccountPassword (convertto-securestring "Passw0rd" -asplaintext -force) `
     -PassThru | Enable-ADAccount

# IIS service account and DNS entry 
Write-Host "Creating IIS Account..."
New-ADUser -Name "IIS Service Account" `
     -SamAccountName iis_svc -UserPrincipalName iis_svc@lab.local `
     -ServicePrincipalNames "HTTP/www.lab.local" `
     -AccountPassword (convertto-securestring "Passw0rd" -asplaintext -force) `
     -PasswordNeverExpires $True `
     -PassThru | Enable-ADAccount

Write-Host "IIS Account created"
Get-ADUser iis_svc -Properties TrustedForDelegation,TrustedToAuthForDelegation,"msDS-AllowedToDelegateTo",ServicePrincipalNames

Write-Host "Adding DNS A record for www..."
Add-DnsServerResourceRecord -ZoneName lab.local -A -Name www -IPv4Address $IISIPAddress 
