[CmdletBinding()]
Param(
    [switch]$Bootstrap  = $False,
    [switch]$Connect    = $False,
    [switch]$Reset      = $False,
    [switch]$Local      = $False,
    $Nsip               = "172.16.124.10",
    $Hostname           = "ns01",
    $Username           = "nsroot",
    $Password           = "nsroot",
    $License            = "licenses/ns01.lic",

    $DnsServerIp        = "172.16.124.50",

    $CertificatesDir    = "certs",
    $TmpCertificatesDir = "tmp"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 4

$SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($Username, $SecurePassword)

$Session =  Connect-Netscaler -Hostname $Nsip -Credential $Credential -PassThru

if ($Connect) {
    return $Session
}

if ($Bootstrap) {
    Write-Host "Starting bootstrap..."
    Set-NSTimeZone -TimeZone 'GMT+01:00-CET-Europe/Zurich' -Session $Session -Force
    Set-NSHostname -Hostname $Hostname -Session $Session -Force

    Write-Host "Installing license and restarting..."
    Install-NSLicense -Path $License -Session $Session
    Restart-NetScaler -WarmReboot -Wait -SaveConfig -Session $Session -Force

    # Reconnect after reboot
    Write-Host "Reconnecting..."
    $Session =  Connect-Netscaler -Hostname $Nsip -Credential $Credential -PassThru

    Write-Host "Longer nsroot session"
    Invoke-Nitro -Type systemuser -Method PUT -Payload @{
            username     = "nsroot"
            timeout      = "86400"
            logging      = "ENABLED"
            externalauth = "ENABLED"
        } -Action Add -Force

    Save-NSConfig

    Write-Host "Bootstrap finished."
    return
}

if ($Reset) {
    Clear-NSConfig -Level Full
    Get-NSSystemFile -FileLocation /nsconfig/ssl |
        Where-Object { $_.filename -match "(extlab|adfs)" } |
        Select-Object -ExpandProperty filename |
        ForEach-Object { Write-Verbose "Removing SSL file $_..."; $_ } |
        Remove-NSSystemFile -FileLocation /nsconfig/ssl
    Get-NSSystemFile -FileLocation /nsconfig/license |
        Where-Object { $_.filename -like "*.lic" } |
        Select-Object -ExpandProperty filename |
        ForEach-Object { Write-Verbose "Removing license file $_..."; $_ } |
        Remove-NSSystemFile -FileLocation /nsconfig/license

    Save-NSConfig
    return
}

function New-ReverseProxy {
    Param(
        [String]$IPAddress,
        [String]$ExternalFQDN,
        [String]$InternalFQDN,
        [String]$CertificateName = $ExternalFQDN
    )
    $VServerName = "vsrv-$ExternalFQDN"
    $ServerName = "srv-$InternalFQDN"

    New-NSLBServer -Name $ServerName -Domain $InternalFQDN
    Enable-NSLBServer -Name $ServerName -Force
    New-NSLBServiceGroup -Name svg-$ExternalFQDN -Protocol HTTP
    New-NSLBServiceGroupMember -Name svg-$ExternalFQDN -ServerName $ServerName

    New-NSLBVirtualServer -Name $VServerName -IPAddress $IPAddress -ServiceType SSL -Port 443
    Add-NSLBVirtualServerBinding -VirtualServerName $VServerName -ServiceGroupName svg-$ExternalFQDN
    Enable-NSLBVirtualServer -Name $VServerName -Force

    Add-NSLBSSLVirtualServerCertificateBinding -Certificate $CertificateName -VirtualServerName $VServerName

    New-NSRewriteAction -Name "act-proxy-host-$InternalFQDN" -Type Replace -Target 'HTTP.REQ.HOSTNAME' -Expression "`"$InternalFQDN`""
    New-NSRewritePolicy -Name "pol-proxy-host-$InternalFQDN" -ActionName "act-proxy-host-$InternalFQDN" -Rule "true"
    Add-NSLBVirtualServerRewritePolicyBinding -VirtualServerName $VServerName -PolicyName "pol-proxy-host-$InternalFQDN" `
        -BindPoint Request -Priority 100
}

function New-Certificate {
    Param(
        [String]$CertificateName,
        [String]$LocalFilename,
        [String]$Filename,
        [String]$Password

    )
    if (Get-NSSystemFile -FileLocation '/nsconfig/ssl' | Where Filename -eq $Filename) {
        Write-Host "Certificate is already present."
    } else {
        Write-Host "Uploading certificate..."
        Add-NSSystemFile -Path $LocalFilename -FileLocation '/nsconfig/ssl' -Filename $Filename
    }
    if ($Password) {
        Add-NSCertKeyPair -CertKeyName $CertificateName -CertPath $Filename -KeyPath $Filename -CertKeyFormat PEM -Password (
            ConvertTo-SecureString -AsPlainText -Force -String $Password)
    } else {
        Add-NSCertKeyPair -CertKeyName $CertificateName -CertPath $Filename -CertKeyFormat DER
    }
}

#
# CONFIGURATION STARTS HERE
#

Write-Host "Adding IPs and enabling features..."
Add-NSIPResource -Type SNIP -IPAddress 172.16.124.11 -SubNetMask '255.255.255.0' -VServer -Session $Session
Add-NSIPResource -Type VIP  -IPAddress 172.16.124.12 -SubNetMask '255.255.255.0' -VServer -Session $Session


Write-Host "Setting up features..."
Enable-NSFeature -Session $Session -Force -Name "aaa", "lb", "rewrite", "ssl"

# This does not work (resolution does not work when using the LB)
#Write-Host "Setting up DNS LB..."
#New-NSLBServer -Name srv-dc01 -IPAddress $DnsServerIp
#New-NSLBServiceGroupMember -Name svg-dns -ServerName srv-dc01
#New-NSLBServiceGroup -Name svg-dns -Protocol DNS
#New-NSLBVirtualServer -Name vsrv-dns -ServiceType DNS
#Add-NSLBVirtualServerBinding -VirtualServerName vsrv-dns -ServiceGroupName svg-dns
#Add-NSDnsNameServer -DNSVServerName vsrv-dns

Write-Host "Setting up DNS..."
Add-NSDnsNameServer -IPAddress $DnsServerIp

Write-Host "Uploading certificates..."
"aaa.extlab.local", "adfs.extlab.local" | ForEach-Object {
    New-Certificate -CertificateName $_ -LocalFilename "$CertificatesDir\$_.pfx" -Filename "$_.pfx" -Password Passw0rd
}

"adfs_token_signing" | ForEach-Object {
    New-Certificate -CertificateName $_ -LocalFilename "$TmpCertificatesDir\$_.cer" -Filename "$_.cer"
}


Write-Host "Setting up WWW LB..."
New-ReverseProxy -IPAddress 172.16.124.12 -ExternalFQDN www.extlab.local -InternalFQDN www.lab.local -CertificateName aaa.extlab.local

Write-Host "Setting up KCD account..."
New-NSKCDAccount -Name ns_svc -Realm "lab.local" -Credential ([PSCredential]::new("ns_svc", (ConvertTo-SecureString "Passw0rd" -Force -AsPlainText)))

Write-Host "Setting up KCD for WWW..."
Invoke-Nitro -Type tmtrafficaction -Method POST -Payload @{
        name             = "prf-sso-kcd"
        initiatelogout   = "OFF"
        persistentcookie = "OFF"
        apptimeout       = "5"
        sso              = "ON"
        kcdaccount       = "ns_svc"
    } -Action Add -Force
Invoke-Nitro -Type tmtrafficpolicy -Method POST -Payload @{
        name   = "pol-sso-kcd"
        action = "prf-sso-kcd"
        rule   = "true"
    } -Action Add -Force
Add-NSLBVirtualServerTrafficPolicyBinding -VirtualServerName "vsrv-www.extlab.local" -PolicyName "pol-sso-kcd" -Priority 100

Write-Host "Setting up authentication server..."
Invoke-Nitro -Type authenticationvserver -Method POST -Payload @{ name  = "aaa-server"
        ipv46                = "172.16.124.13"
        port                 = "443"
        servicetype          = "SSL"
        authenticationdomain = "extlab.local"
        authentication       = "ON"
        state                = "ENABLED"
    } -Action Add -Force


Write-Host "Setting up authentication for www.extlab.local..."
Invoke-Nitro -Type lbvserver -Method PUT -Payload @{
        name               = "vsrv-www.extlab.local"
        authenticationhost = "aaa.extlab.local"
        authnvsname        = "aaa-server"
        authentication     = "ON"
        authn401           = "OFF"
    } -Force
Add-NSLBSSLVirtualServerCertificateBinding -VirtualServerName "aaa-server" -Certificate "aaa.extlab.local"

if ($Local) {
    Write-Host "Setting up Local authentication..."
    Invoke-Nitro -Type aaauser -Method POST -Payload @{
            username = "test"
            password = "test"
        } -Action Add -Force

    Invoke-Nitro -Type authenticationlocalpolicy -Method POST -Payload @{
            name   = "auth-local"
            rule   = "NS_TRUE"
        } -Action Add -Force
    Invoke-Nitro -Type authenticationvserver_authenticationlocalpolicy_binding -Method POST -Payload @{
            name       = "aaa-server"
            policy     = "auth-local"
            priority   = "100"
            secondary  = "false"
        } -Action Add -Force
} else {
    Write-Host "Setting up SAML authentication..."
    Invoke-Nitro -Method POST -Type authenticationsamlaction  -Payload @{
            name                           = "act-saml-adfs.extlab.local"
            samlidpcertname                = "adfs_token_signing"
            samlredirecturl                = "https://adfs.extlab.local/adfs/ls"
            samlsigningcertname            = "aaa.extlab.local"
            samlissuername                 = "Netscaler"
            samlrejectunsignedassertion    = "ON"
            samlbinding                    = "POST"
            skewtime                       = "5"
            samltwofactor                  = "OFF"
            samlacsindex                   = "255"
            attributeconsumingserviceindex = "255"
            requestedauthncontext          = "exact"
            signaturealg                   = "RSA-SHA256"
            digestmethod                   = "SHA256"
            sendthumbprint                 = "OFF"
            enforceusername                = "ON"
        } -Action add -Force
    Invoke-Nitro -Session $session -Method POST -Type authenticationsamlpolicy -Payload @{
            name      = "pol-saml-adfs.extlab.local"
            reqaction = "act-saml-adfs.extlab.local"
            rule      = "ns_true"
        } -Action add -Force
    Invoke-Nitro -Method POST -Type authenticationvserver_authenticationsamlpolicy_binding -Payload @{
            policy    = "pol-saml-adfs.extlab.local"
            name      = "aaa-server"
            priority  = "100"
            secondary = "false"
        } -Action add -Force
}

Save-NSConfig

#$lbsrv01 = New-NSLBServer -Name 'srv-storefront-sfdev01' -IPAddress '10.23.39.249' -State 'DISABLED' -PassThru
#Enable-NSLBServer -Name 'srv-storefront-sfdev01' -Force

#$lbsrv02 = New-NSLBServer -Name 'srv-storefront-sfdev02' -IPAddress '10.23.35.255' -State 'DISABLED' -PassThru
#Enable-NSLBServer -Name 'srv-storefront-sfdev02' -Force
#New-NSLBServiceGroup -Name 'svg-storefront'-ServiceType HTTP

#New-NSLBServiceGroupMember -Name 'svg-storefront' -ServerName 'srv-storefront-sfdev01'
#New-NSLBServiceGroupMember -Name 'svg-storefront' -ServerName 'srv-storefront-sfdev02'

#New-NSLBVirtualServer -Name 'lb-vsrv01' -IPAddress '172.16.124.12' -Port 80 -ServiceType 'HTTP'
#Add-NSLBVirtualServerBinding -VirtualServerName 'lb-vsrv01' -ServiceGroupName 'svg-storefront' -Force -PassThru


