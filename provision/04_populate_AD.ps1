New-ADUser -Name "Dominique Broeglin" -GivenName Dominique -Surname Broeglin `
     -SamAccountName dom -UserPrincipalName dom@lab.local `
     -AccountPassword (convertto-securestring "Passw0rd" -asplaintext -force) `
     -PassThru | Enable-ADAccount
     
Add-DnsServerResourceRecord -ZoneName lab.local -A -Name www -IPv4Address 172.16.124.51