Param (
    [String]$CertificateSubject     = "aaa.extlab.local",
    [String]$Fqdn                   = "www.extlab.local",
    [String]$CertificateDirectory   = "c:\vagrant\tmp",
    [String]$CertificatePassword    = "Passw0rd"
)
Import-PfxCertificate $CertificateDirectory\$CertificateSubject.pfx `
    -CertStoreLocation Cert:\LocalMachine\My `
    -Password (ConvertTo-SecureString $CertificatePassword -AsPlainText -Force)

if (Get-ADFSRelyingPartyTrust -Name Netscaler) {
    Remove-ADFSRelyingPartyTrust -TargetName Netscaler
}

Add-ADFSRelyingPartyTrust -Name Netscaler `
	-Identifier Netscaler `
	-SamlEndpoint (New-ADFSSamlEndpoint -Binding "POST" -Protocol "SAMLAssertionConsumer" -Uri "https://$Fqdn/cgi/samlauth") `
	-RequestSigningCertificate (Get-ChildItem  -Path Cert:\LocalMachine\My  | ? { $_.Subject  -Match "$CertificateSubject"})

$rules = @'
@RuleName = "Store: ActiveDirectory -> Mail (ldap attribute: mail), Name (ldap attribute: userPrincipalName), GivenName (ldap attribute: givenName), Surname (ldap attribute: sn)" 
c:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/windowsaccountname", Issuer == "AD AUTHORITY"]
 => issue(store = "Active Directory", types = ("http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress", 
 "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name", 
 "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier", 
 "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname", 
 "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname"), query = ";mail,displayName,userPrincipalName,givenName,sn;{0}", param = c.Value);
'@
  
Set-ADFSRelyingPartyTrust -TargetName Netscaler -IssuanceTransformRules $rules

$AuthRule = '=> issue(Type = "http://schemas.microsoft.com/authorization/claims/permit", Value = "true");'
$RuleSet = New-ADFSClaimRuleSet -ClaimRule $AuthRule
Set-ADFSRelyingPartyTrust -TargetName Netscaler -IssuanceAuthorizationRules $RuleSet.ClaimRulesString

Set-ADFSRelyingPartyTrust -TargetName Netscaler –NotBeforeSkew 2
