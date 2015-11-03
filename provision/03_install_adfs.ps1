param (
    [switch]$OnlineRequest
)
 
Set-StrictMode -Version Latest 
$ErrorActionPreference = "Stop"
    
$Start = get-date
 
### Variables
$CertificateADFSsubject = "adfs.broeglin.fr"
$ADFSdisplayName = "Kloud Showcase ADFS 2"
$ADFSuser = "broeglin\ADFSfarm2012R2"
$CertificateLocalPath = "C:\Certificates\"
#$CertificateRemotePath = "\\dc01.kloud.internal\certificates\"
$CertificateRemotePath = $CertificateLocalPath
$RelyingPartyTrustExchangeName = "Exchange"
$RelyingPartyTrustExchangeURI = "https://ex2010-01.kloud.internal/owa"
$RelyingPartyTrustExchangeIssuanceRule = "@RuleTemplate = `"AllowAllAuthzRule`""    # Escape quotes
$RelyingPartyTrustExchangeIssuanceRule += "`n => issue(Type = `"http://schemas.microsoft.com/authorization/claims/permit`", Value = `"true`");"    # New line and escape quotes
# Only for Online Request
$CertificateAuthority = "dc01.kloud.internal\kloud-Showcase-CA"
 
### Preparation
#$PfxPasswordADFS = Get-Credential "PFX password" -message "Enter the password for the ADFS PFX certificate"
#if ($PfxPasswordADFS -eq $null) {
#    write-host "No password entered, exiting"
#    exit
#}
#$ADFSuserCredential = Get-Credential $ADFSuser -message "Enter the password for the ADFS service account"
#if ($ADFSuserCredential -eq $null) {
#    write-host "No password entered, exiting"
#    exit
#}
 
$secpasswd = ConvertTo-SecureString "PlainTextPassword" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("username", $secpasswd) 

$PfxPasswordADFS    = $mycreds
$ADFSuserCredential = $mycreds
     
if ((Test-Path $CertificateLocalPath) -eq $false) {
    mkdir $CertificateLocalPath
}
 

$CertificateADFS = "$CertificateADFSsubject.pfx"
$CertificateADFSremotePath = $CertificateRemotePath + $CertificateADFS
 
$CertificateADFSsubjectCN = "CN=" + $CertificateADFSsubject
cd $CertificateLocalPath
 
function New-CertificateRequest {
    param (
        [Parameter(Mandatory=$true, HelpMessage = "Please enter the subject beginning with CN=")]
        [ValidatePattern("CN=")]
        [string]$subject,
        [Parameter(Mandatory=$false, HelpMessage = "Please enter the SAN domains as a comma separated list")]
        [array]$SANs,
        [Parameter(Mandatory=$false, HelpMessage = "Please enter the Online Certificate Authority")]
        [string]$OnlineCA,
        [Parameter(Mandatory=$false, HelpMessage = "Please enter the Online Certificate Authority")]
        [string]$CATemplate = "WebServer"
    )
 
    ### Preparation
    $subjectDomain = $subject.split(',')[0].split('=')[1]
    if ($subjectDomain -match "\*.") {
        $subjectDomain = $subjectDomain -replace "\*", "star"
    }
    $CertificateINI = "$subjectDomain.ini"
    $CertificateREQ = "$subjectDomain.req"
    $CertificateRSP = "$subjectDomain.rsp"
    $CertificateCER = "$subjectDomain.cer"
 
    ### INI file generation
    new-item -type file $CertificateINI -force
    add-content $CertificateINI '[Version]'
    add-content $CertificateINI 'Signature="$Windows NT$"'
    add-content $CertificateINI ''
    add-content $CertificateINI '[NewRequest]'
    $temp = 'Subject="' + $subject + '"'
    add-content $CertificateINI $temp
    add-content $CertificateINI 'Exportable=TRUE'
    add-content $CertificateINI 'KeyLength=2048'
    add-content $CertificateINI 'KeySpec=1'
    add-content $CertificateINI 'KeyUsage=0xA0'
    add-content $CertificateINI 'MachineKeySet=True'
    add-content $CertificateINI 'ProviderName="Microsoft RSA SChannel Cryptographic Provider"'
    add-content $CertificateINI 'ProviderType=12'
    add-content $CertificateINI 'SMIME=FALSE'
    add-content $CertificateINI 'RequestType=PKCS10'
    add-content $CertificateINI '[Strings]'
    add-content $CertificateINI 'szOID_ENHANCED_KEY_USAGE = "2.5.29.37"'
    add-content $CertificateINI 'szOID_PKIX_KP_SERVER_AUTH = "1.3.6.1.5.5.7.3.1"'
    add-content $CertificateINI 'szOID_PKIX_KP_CLIENT_AUTH = "1.3.6.1.5.5.7.3.2"'
    if ($SANs) {
        add-content $CertificateINI 'szOID_SUBJECT_ALT_NAME2 = "2.5.29.17"'
        add-content $CertificateINI '[Extensions]'
        add-content $CertificateINI '2.5.29.17 = "{text}"'
 
        foreach ($SAN in $SANs) {
            $temp = '_continue_ = "dns=' + $SAN + '&"'
            add-content $CertificateINI $temp
        }
    }
 
    ### Certificate request generation
    if (test-path $CertificateREQ) {del $CertificateREQ}
    certreq -new $CertificateINI $CertificateREQ
 
    ### Online certificate request and import
    if ($OnlineCA) {
        if (test-path $CertificateCER) {del $CertificateCER}
        if (test-path $CertificateRSP) {del $CertificateRSP}
        certreq -submit -attrib "CertificateTemplate:$CATemplate" -config $OnlineCA $CertificateREQ $CertificateCER
 
        certreq -accept $CertificateCER
    }
}
 
### Script
 
if ($OnlineRequest) { 
    # Certificate creation
    New-CertificateRequest -subject $CertificateADFSsubjectCN -OnlineCA $CertificateAuthority
 
    # Certificate export
    $ADFScertificate = dir Cert:\LocalMachine\My | where { $_.subject -match $CertificateADFSsubject }
    if (($ADFScertificate.count) -gt 1) {
        write-host -foregroundcolor Yellow "`n`nDuplicate certifcates! Delete all certificates with the subject $CertificateADFSsubject"
        exit
    }
    Export-PfxCertificate -Cert $ADFScertificate -FilePath $CertificateADFSremotePath -Password $PfxPasswordADFS.Password
} else {
    Import-PfxCertificate -FilePath $CertificateADFSremotePath -CertStoreLocation cert:\localMachine\my -Password $PfxPasswordADFS.Password
}

# ADFS Install
Add-WindowsFeature ADFS-Federation -IncludeManagementTools
Import-Module ADFS
$CertificateThumbprint = (dir Cert:\LocalMachine\My | where {$_.subject -match $CertificateADFSsubjectCN}).thumbprint
Install-AdfsFarm -CertificateThumbprint $CertificateThumbprint -FederationServiceDisplayName $ADFSdisplayName -FederationServiceName $CertificateADFSsubject -ServiceAccountCredential $ADFSuserCredential
 
# ADFS Non Claims Aware Relying Party Trust
Add-AdfsNonClaimsAwareRelyingPartyTrust -Name $RelyingPartyTrustExchangeName -Identifier $RelyingPartyTrustExchangeURI -IssuanceAuthorizationRules $RelyingPartyTrustExchangeIssuanceRule

$Finish = get-date
$Elapsed = $finish - $start
"Elapsed time: {0:mm} minutes and {0:ss} seconds" -f $Elapsed