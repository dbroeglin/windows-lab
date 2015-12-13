
Set-DnsClientServerAddress -InterfaceIndex ((get-netadapter | ? { $_.MacAddress -eq '08-00-27-00-00-11' }).InterfaceIndex) -ServerAddress '192.168.100.10'

$Domain = "broeglin.fr"
$Password = "vagrant" | ConvertTo-SecureString -asPlainText -Force
$Username = "vagrant" 
$Credential = New-Object System.Management.Automation.PSCredential($Username,$Password)
Add-Computer -DomainName $Domain -Credential $Credential
