function Log-Msg{



Param(
# message to log (mandatory)
[parameter(Mandatory = $true)]
[string]
$LogMessage,

# log file path (mandatory)
[parameter(Mandatory = $false)]
[string]
$LogFile=$mainLogFile,



# severity level: 1 = information, 2 = warning, 3 = error, default = 1
[parameter(Mandatory = $false)]
[ValidateRange(1, 3)]
[Single]
$Severity = 1,



# component, default = N/A
[parameter(Mandatory = $false)]
[string]
$Component = "PROCESS",



# component, default = N/A
[parameter(Mandatory = $false)]
[System.ConsoleColor]
$ForegroundColor



)
$ErrorActionPreference = "SilentlyContinue"
# obtain UTC offset
$DateTime = New-Object -ComObject WbemScripting.SWbemDateTime
$DateTime.SetVarDate($(Get-Date))
$UtcValue = $DateTime.Value
$UtcOffset = $UtcValue.Substring(21, $UtcValue.Length - 21)

# build line template
$LogLineTemplate = "<![LOG[{0}]LOG]!><time=`"{1}{2}`" date=`"{3}`" component=`"{4}`" context=`"{5}`" type=`"{6}`" thread=`"{7}`" file=`"{8}`">"



# insert values in template
$LogLine = $LogLineTemplate -f $LogMessage,
(Get-Date -Format HH:mm:ss.fff),
$UtcOffset,
(Get-Date -Format M-d-yyyy),
$Component,
[System.Security.Principal.WindowsIdentity]::GetCurrent().Name,
$Severity,
[Threading.Thread]::CurrentThread.ManagedThreadId,
(Split-Path -Leaf $PSScriptRoot)



# add line to log file
$LogLine | Out-File -FilePath $LogFile -WhatIf:$false -Append -Encoding Default
if($ForegroundColor){
Write-Host $LogMessage -ForegroundColor $ForegroundColor
}else{
Write-Host $LogMessage
}
$ErrorActionPreference = "Continue"



}



function Check-DedupConfig ([string]$Volume) {
$Dedupconfig = Get-DedupVolume -Volume $volume
if($Dedupconfig.MinimumFileAgeDays -ne 3){
Write-Host("Incorrect configuration : Minimum File Age is set to {0} days" -f $Dedupconfig.MinimumFileAgeDays) -ForegroundColor Red
$configok = $false
}
elseif($Dedupconfig.MinimumFileAgeDays = 3){
Write-Host("Configuration OK : Minimum File Age is set to {0} days" -f $Dedupconfig.MinimumFileAgeDays) -ForegroundColor Green
$configok = $true
}
else{
Write-Host("Unable to check Minimum File Age value !" -f $Dedupconfig.MinimumFileAgeDays) -ForegroundColor Red
$configok = $false
}



$smspkgpath = "\smspkg{0}$" -f $volume.Substring(0,1).ToLower()
$okflag = 0
foreach($Folder in $Dedupconfig.ExcludeFolder){
if($Folder.ToString() -eq "\sms_dp$"){$okflag ++}
if($Folder.ToString() -eq "\smssig$"){$okflag ++}
if($Folder.ToString() -eq $smspkgpath){$okflag ++}
if($Folder.ToString() -eq "\sms_dp$\sms"){$okflag ++}
}
# $okflag



if($okflag -ne 4){
Write-Host ("Incorrect configuration: some of the required folder exclusions are missing !") -ForegroundColor Red
$configok = $false
}
else{
Write-Host ("Configuration OK: All required dedup Folder exclusions seem to be set as expected.") -ForegroundColor Green
$configok = $true
}



return $configok
}



function Set-DedupConfig ([string]$Volume){
$smspkgpath = "\smspkg{0}$" -f $volume.Substring(0,1).ToLower()
try{
Set-DedupVolume -Volume $volume -MinimumFileAgeDays 3 -ExcludeFolder "\sms_dp$","\smssig$",$smspkgpath,"\sms_dp$\sms"
}catch{
Log-Msg("'{0}' : '{1}'! Exiting..." -f $_.Exception.Message,$_.Exception.StackTrace) -Severity 3 -Component "END"
continue
}
}



$logDir = "C:\_logfiles"
$mainLogFile = Join-Path $logDir ("{0}_{1}.log" -f "Set-Dedup-Config",(Get-Date -Format yyyy-MM-dd))
if(!(Test-Path $mainLogFile)){New-Item $mainLogFile -ItemType File -Force | Out-Null}



Log-Msg("***** BEGIN *****") -Component "BEGIN"



# Determine which drive to use, by retrieving the location of the SMS DP ContentLib drive from the registry.
$key = Get-Item HKLM:\SOFTWARE\Microsoft\SMS\DP -ErrorAction SilentlyContinue
if($key){
$smsdrive = $key.GetValue("ContentLibUsableDrives")
if(($smsdrive.Split("\"))[1] -eq "" -or ($smsdrive.Split(","))[0] -eq ($smsdrive.Split(","))[0]){
$DPVolume = $smsdrive.Split("\")[0]
Log-Msg("Found one ContentLib usable drive: '{0}', resuming..." -f $DPVolume)
}else{
Log-Msg("Found more than one SMS drive! Please check DP configuration! Exiting...") -Severity 3 -Component "END"
Log-Msg("{0}" -f $smsdrive) -Severity 3 -Component "END"
return "NonCompliant"
}
}else{
Log-Msg("SMS DP config registry key not found! Please check DP configuration! Exiting...") -Severity 3 -Component "END"
return "NonCompliant"
}



# check if File Dedup feature is enabled:
$WinFeature_Dedup = Get-WindowsFeature -Name FS-Data-Deduplication
if($WinFeature_Dedup.InstallState -eq "Available" -and $WinFeature_Dedup.Installed -eq $false){
Log-Msg("Windows File Deduplication feature is available but not installed!") #-ForegroundColor Gray
Install-WindowsFeature -Name FS-Data-Deduplication -IncludeAllSubFeature -Restart #enable and configure dedup
}elseif($WinFeature_Dedup.Installed -eq $true){
Log-Msg("Windows File Deduplication feature is installed. We can continue...")
}



# check if Dedup is enabled on the drive
if((Get-DedupStatus) -ne $null){
$DedupStatus = Get-DedupStatus
$DedupVolume = $DedupStatus.Volume
Log-Msg("Deduplication is enabled on volume {0}" -f $DedupVolume)
# check Dedup configuration
if(Check-DedupConfig -volume $DedupVolume){
Log-Msg("Dedup Configuration OK, nothing to do.") -Component "END"
return "Compliant"
}else{
Log-Msg("Dedup configuration not OK: Applying desired configuration...")
Set-DedupConfig -volume $DedupVolume
Log-Msg("Dedup configuration applied successfully")
}
}else{
Log-Msg("Deduplication is disabled ! Enabling Deduplication on smsdp drive...")
$DedupVolume = $DPVolume
Enable-DedupVolume -Volume $DedupVolume
Set-DedupConfig -Volume $DedupVolume
Log-Msg("Dedup configuration applied successfully")
}



Log-Msg("***** END *****") -Component "END"