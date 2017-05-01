$password = ConvertTo-SecureString -String "Passw0rd" -Force -AsPlainText
$CertificateDir = "c:\vagrant\certs"

Mkdir $CertificateDir -Force

"aaa.extlab.local", "www.extlab.local" | ForEach {
    $Fqdn = $_
    New-SelfSignedCertificate -certstorelocation cert:\localmachine\my `
        -dnsname $Fqdn

    Start-Sleep 1

    dir Cert:\LocalMachine\My | ? { $_.Subject -match $Fqdn } |
        Export-PfxCertificate -FilePath $CertificateDir\$Fqdn.pfx -Password $password    
}

return 

# The following code works only on W2016 (PS v5 ?):

$password = ConvertTo-SecureString -String "Passw0rd" -Force -AsPlainText
dir Cert:\LocalMachine\My | ? { $_.Subject -match "adfs.extlab.local" } | Remove-Item

New-SelfSignedCertificate -certstorelocation cert:\localmachine\my `
        -dnsname adfs.extlab.local -KeySpec KeyExchange 

dir Cert:\LocalMachine\My | ? { $_.Subject -match "adfs.extlab.local" } |
    Export-PfxCertificate -FilePath adfs.extlab.local.pfx -Password $password    
