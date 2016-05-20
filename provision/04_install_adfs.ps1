Param (
    [String]$ADFSdisplayName        = "LAB ADFS",
    [String]$CertificateDirectory   = "c:\vagrant\tmp",
    [String]$CertificateADFSsubject = "adfs.extlab.local",
    [String]$CertificatePassword    = "Passw0rd",
    [String]$AdminUserName          = "LAB\vagrant",
    [String]$AdminUserPassword      = "vagrant",
    [String]$ADFSUserName           = "LAB\adfs_svc",
    [String]$ADFSUserPassword       = "Passw0rd"
)
 
Set-StrictMode -Version Latest 
$ErrorActionPreference = "Stop"

$ADFSUserCredential = New-Object PSCredential ($ADFSUserName, 
    (ConvertTo-SecureString $ADFSUserPassword -AsPlainText -Force)
)

Import-PfxCertificate $CertificateDirectory\$CertificateADFSsubject.pfx `
    -CertStoreLocation Cert:\LocalMachine\My `
    -Password (ConvertTo-SecureString $CertificatePassword -AsPlainText -Force)

# ADFS Install
Add-WindowsFeature ADFS-Federation -IncludeManagementTools
Import-Module ADFS

$CertificateThumbprint = (
    dir Cert:\LocalMachine\My | where { $_.subject -match "cn=$CertificateADFSsubject" }
).Thumbprint
Install-AdfsFarm -CertificateThumbprint $CertificateThumbprint `
    -FederationServiceDisplayName $ADFSdisplayName `
    -FederationServiceName $CertificateADFSsubject `
    -ServiceAccountCredential $ADFSUserCredential `
    -Credential (New-Object PSCredential ($AdminUserName, 
        (ConvertTo-SecureString $AdminUserPassword -AsPlainText -Force)))


Write-Host "Exporting ADFS Token Signing Certificate..."
$Cert=Get-AdfsCertificate -CertificateType Token-Signing
$CertBytes=$Cert[0].Certificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
[System.IO.File]::WriteAllBytes("$CertificateDirectory\adfs_token_signing.cer", $certBytes)
