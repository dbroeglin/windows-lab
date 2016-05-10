Param (
    [String]$ADFSdisplayName = "LAB ADFS",
    [String]$CertificateADFSsubject = "sts.extlab.local",
    [String]$CertificatePassword = "Passw0rd",
    [String]$AdminUserName        = "LAB\vagrant",
    [String]$AdminUserPassword    = "vagrant",
    [String]$ADFSUserName        = "LAB\adfs_svc",
    [String]$ADFSUserPassword    = "Passw0rd"
)
 
Set-StrictMode -Version Latest 
$ErrorActionPreference = "Stop"

$ADFSUserCredential = New-Object PSCredential ($ADFSUserName, 
    (ConvertTo-SecureString $ADFSUserPassword -AsPlainText -Force)
)

Import-PfxCertificate c:\vagrant\test\$CertificateADFSsubject.pfx `
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
 
# ADFS Non Claims Aware Relying Party Trust
#Add-AdfsNonClaimsAwareRelyingPartyTrust -Name $RelyingPartyTrustExchangeName -Identifier $RelyingPartyTrustExchangeURI -IssuanceAuthorizationRules $RelyingPartyTrustExchangeIssuanceRule
