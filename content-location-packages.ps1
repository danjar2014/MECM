


$pkgs = Get-CMPackage

foreach ($pkg in $pkgs) {
  Write-Host "PackageID: $($pkg.PackageID)"
  Write-Host "Name: $($pkg.Name)"
  $oldpath = $pkg.PkgSourcePath
  Write-Host "Old Source: $oldpath"
  $replacementString = "\\frmndfsvm11\repository$"
  $oldpath = $oldpath.substring(28)
    }
    Write-Host "Current source: $oldpath" -ForegroundColor Cyan
     $NewPath = $replacementString + $oldpath

  Write-Host "New Source: $NewPath"
  if ($NewPath -ne "") {
    if ($NewPath.ToLower() -ne $oldpath.ToLower()) {
      Write-Host "updating pacakge source path..."
      Set-CMPackage -Id $pkg.PackageID -Path $NewPath
    }
}
  write-host "----"


