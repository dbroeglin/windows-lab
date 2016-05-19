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

# Netscaler KCD service account
# Note: the account's SPN is not meaningful, it just allows us to activate delegation
Write-Host "Creating Netscaler Account..."
$User = New-ADUser -Name "Netscaler Service Account" `
     -SamAccountName ns_svc -UserPrincipalName ns_svc@lab.local `
     -AccountPassword (convertto-securestring "Passw0rd" -asplaintext -force) `
     -ServicePrincipalNames host/nsdbg `
     -PasswordNeverExpires $True `
     -PassThru

Set-ADAccountControl $User -TrustedForDelegation $False -TrustedToAuthForDelegation $True
Get-ADUser $User | Set-ADUser -Enabled $True -Replace @{
    "msDS-AllowedToDelegateTo" = "http/www.lab.local"
}

Write-Host "Netscaler Account created:"
Get-ADUser ns_svc -Properties TrustedForDelegation,TrustedToAuthForDelegation,"msDS-AllowedToDelegateTo",ServicePrincipalNames

# ADFS service account and DNS entry 
Write-Host "Creating ADFS Account..."
New-ADUser -Name "ADFS Service Account" `
     -SamAccountName adfs_svc -UserPrincipalName adfs_svc@lab.local `
     -AccountPassword (convertto-securestring "Passw0rd" -asplaintext -force) `
     -PasswordNeverExpires $True `
     -PassThru | Enable-ADAccount

Write-Host "ADFS Account created:"
Get-ADUser adfs_svc -Properties TrustedForDelegation,TrustedToAuthForDelegation,"msDS-AllowedToDelegateTo",ServicePrincipalNames
Add-ADGroupMember -Identity "Domain Admins" -Members "adfs_svc"
