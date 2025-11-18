
####################
# Prerequisite check
####################
if (-NOT([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Administrator priviliges are required. Please restart this script with elevated rights." -ForegroundColor Red
    Pause
    Throw "Administrator priviliges are required. Please restart this script with elevated rights."
}


#######################
# Setting the variables
#######################
$UID = [guid]::NewGuid()
$Settings= "$($env:TEMP)\$($UID)-settings.inf";
$files = "$($env:TEMP)\$($UID)-csr.req"
$Hostname=(Get-WmiObject win32_computersystem).DNSHostName+"."+(Get-WmiObject win32_computersystem).Domain


Write-Host "Provide the Subject details required for the Certificate Signing Request" -ForegroundColor Yellow
$request = "$Hostname"
$FName = $env:computername



#########################
# Create the settings.inf
#########################
$settingsInf = "
[Version] 
Signature=`"`$Windows NT`$ 
[NewRequest] 
KeyLength =  2048
Exportable = TRUE 
MachineKeySet = TRUE 
SMIME = FALSE
RequestType =  PKCS10 
ProviderName = `"Microsoft RSA SChannel Cryptographic Provider`" 
ProviderType =  12
HashAlgorithm = sha256
FriendlyName = `"$FName`" 
;Variables
Subject = `"CN={{CN}}`"
;Certreq info
;http://technet.microsoft.com/en-us/library/dn296456.aspx
;CSR Decoder
;https://certlogik.com/decoder/
;https://ssltools.websecurity.symantec.com/checker/views/csrCheck.jsp
"


$settingsInf = $settingsInf.Replace("{{CN}}",$request).Replace("{{O}}",$request['O'])

# Save settings to file in temp
$settingsInf > $Settings

# Done, we can start with the CSR
#Clear-Host

#################################
# CSR TIME
#################################

# Display summary
Write-Host "Certificate information
Common name: $($Hostname)
Exportable : True
Signature algorithm: SHA256
Key algorithm: RSA
Key size: 2048
FreindlyName : $FName
" -ForegroundColor Yellow

certreq -new $Settings $files > $null

# Output the CSR
$CSR = Get-Content $files
Write-Output $CSR >> c:\temp
Write-Host "
"