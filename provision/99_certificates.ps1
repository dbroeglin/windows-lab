$password = ConvertTo-SecureString -String "Passw0rd" -Force -AsPlainText

Mkdir c:\vagrant\test\ -Force

"aaa.extlab.local", "www.extlab.local" | ForEach {
    $Fqdn = $_
    New-SelfSignedCertificate -certstorelocation cert:\localmachine\my `
        -dnsname $Fqdn

    Start-Sleep 1

    dir Cert:\LocalMachine\My | ? { $_.Subject -match $Fqdn } |
        Export-PfxCertificate -FilePath c:\vagrant\test\$Fqdn.pfx -Password $password    
}

# Works only on W2016:
#New-SelfSignedCertificate -certstorelocation cert:\localmachine\my `
#        -dnsname sts.extlab.local -KeySpec KeyExchange 

#dir Cert:\LocalMachine\My | ? { $_.Subject -match "sts.extlab.local" } |
#    Export-PfxCertificate -FilePath c:\vagrant\test\sts.extlab.local.pfx -Password $password    
