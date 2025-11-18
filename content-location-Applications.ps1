
Write-Host "Querying Applications..." -ForegroundColor Cyan

$Apps = Get-CMApplication
$AppNames = $Apps.LocalizedDisplayName
$AppCount = $AppNames.Count
$RowCount = 1

Write-Host "Returned $AppCount objects"

foreach ($AppName in $AppNames) {
  Write-Host "Application: $AppName ($RowCount of $AppCount)" -ForegroundColor White
  $DtNames = Get-CMDeploymentType -ApplicationName $AppName
  Write-Host "Querying Deployment types..." -ForegroundColor Cyan
  foreach ($dt in $DtNames) {
    $DtSDMPackageXML = $dt.SDMPackageXML
    $DtSDMPackageXML = [xml]$DtSDMPackageXML
    $DtLocalName = $dt.LocalizedDisplayName
    $DtCleanPath = ""
    $DtCleanPath = $DtSDMPackageXML.AppMgmtDigest.DeploymentType.Installer.Contents.Content.Location[0]
    $replacementString = "\\frmndfsvm11\repository$"

    # check if array returned only a "\" value, indicating a singular value
    if ($DtPath.Length -lt 2) {
      $DtPath = $DtSDMPackageXML.AppMgmtDigest.DeploymentType.Installer.Contents.Content.Location
      $DtPath = $DtPath.substring(28)
    }
    Write-Host "Current source: $DtPath" -ForegroundColor Cyan
     $NewDtPath = $replacementString + $DtPath 

    Write-Host "New directory source: $NewDtPath" -ForegroundColor Green
    if ($NewDtPath -ne "") {
      if ($NewDtPath.ToLower() -ne $DtPath.ToLower()) {
        Set-CMDeploymentType -ApplicationName "$AppName" -DeploymentTypeName $DtLocalName -MsiOrScriptInstaller -ContentLocation "$NewDtPath"
        Write-Host "Updating: $DtLocalName" -ForegroundColor Cyan
      }
      else {
        Write-Host "No changes made" -ForegroundColor Cyan
      }
    }
  }
  Write-Host "--------------"
  $RowCount++
}


