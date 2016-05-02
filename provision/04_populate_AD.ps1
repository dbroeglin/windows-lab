# Client User
New-ADUser -Name "Dominique Broeglin" -GivenName Dominique -Surname Broeglin `
     -SamAccountName dom -UserPrincipalName dom@lab.local `
     -AccountPassword (convertto-securestring "Passw0rd" -asplaintext -force) `
     -PassThru | Enable-ADAccount

# IIS service account and DNS entry 
New-ADUser -Name "IIS Service Account"  `
     -SamAccountName iis_svc -UserPrincipalName iis_svc@lab.local `
     -AccountPassword (convertto-securestring "Passw0rd" -asplaintext -force) `
     -PasswordNeverExpires $True `
     -PassThru | Enable-ADAccount

Add-DnsServerResourceRecord -ZoneName lab.local -A -Name www -IPv4Address 172.16.124.51

# Netscaler KCD service account
# Note: the account's SPN is not meaningful, it just allows us to activate delegation
$User = New-ADUser -Name "Netscaler Service Account" `
     -SamAccountName ns_svc -UserPrincipalName ns_svc@lab.local `
     -AccountPassword (convertto-securestring "Passw0rd" -asplaintext -force) `
     -ServicePrincipalNames host/nsdbg `
     -PasswordNeverExpires $True `
     -PassThru

Set-ADAccountControl $User -TrustedForDelegation $False -TrustedToAuthForDelegation $True
Set-ADUser $User -Replace @{
    "msDS-AllowedToDelegateTo" = "http/www.lab.local"
}
$User | Enable-ADAccount


# Setup an external domain name
Add-DnsServerPrimaryZone -Name "extlab.local" -ReplicationScope "Forest"

# External website name
Add-DnsServerResourceRecord -ZoneName extlab.local -A -Name www -IPv4Address 172.16.124.12

# External aaa name
Add-DnsServerResourceRecord -ZoneName extlab.local -A -Name aaa -IPv4Address 172.16.124.13


