function Check-DedupConfig ([string]$Volume) {
$Dedupconfig = Get-DedupVolume -Volume $volume
if($Dedupconfig.MinimumFileAgeDays -ne 3){
$configok = $false
}
elseif($Dedupconfig.MinimumFileAgeDays = 3){
$configok = $true
}
else{
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
$configok = $false
}
else{
$configok = $true
}



return $configok
}



# Determine which drive to use, by retrieving the location of the SMS DP ContentLib drive from the registry.
$key = Get-Item HKLM:\SOFTWARE\Microsoft\SMS\DP -ErrorAction SilentlyContinue
if($key){
$smsdrive = $key.GetValue("ContentLibUsableDrives")
if(($smsdrive.Split("\"))[1] -eq "" -or ($smsdrive.Split(","))[0] -eq ($smsdrive.Split(","))[1]){
$DPVolume = $smsdrive.Split("\")[0]
}else{
return "NonCompliant"
}
}else{
return "NonCompliant"
}



# check if File Dedup feature is enabled:
$WinFeature_Dedup = Get-WindowsFeature -Name FS-Data-Deduplication
if($WinFeature_Dedup.InstallState -eq "Available" -and $WinFeature_Dedup.Installed -eq $false){
return "NonCompliant"
}



# check if Dedup is enabled on the drive
if((Get-DedupStatus) -ne $null){
$DedupStatus = Get-DedupStatus
$DedupVolume = $DedupStatus.Volume
# check Dedup configuration
if(Check-DedupConfig -volume $DPVolume){
return "Compliant"
}else{
return "NonCompliant"
}
}else{
return "NonCompliant"
}