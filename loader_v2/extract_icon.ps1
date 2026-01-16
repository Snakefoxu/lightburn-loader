$source = "d:\REPOS_GITHUB\LightBurn_RE\original\LightBurn.exe"
$dest = "d:\REPOS_GITHUB\LightBurn_RE\loader_v2\LightBurn.ico"

Add-Type -AssemblyName System.Drawing

if (Test-Path $source) {
    $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($source)
    $fileStream = New-Object System.IO.FileStream($dest, [System.IO.FileMode]::Create)
    $icon.Save($fileStream)
    $fileStream.Close()
    Write-Host "Icon extracted to $dest"
}
else {
    Write-Error "LightBurn.exe not found in $source"
    exit 1
}
