<#
.SYNOPSIS
  Builds an installable Ghidra extension zip of Zeekr_RH850 for one Ghidra installation.

.DESCRIPTION
  Compiles data/languages/RH850.slaspec with that Ghidra's own SLEIGH compiler (the .sla
  format is tied to the Ghidra version) and writes
      dist/ghidra_<version>_PUBLIC_<yyyyMMdd>_Zeekr_RH850.zip
  containing a top-level Zeekr_RH850/ folder, the layout Ghidra's
  File > Install Extensions dialog expects.

.EXAMPLE
  .\build-release.ps1 -GhidraDir "C:\ghidra_12.1.4_PUBLIC"
#>
param(
    [string]$GhidraDir = $env:GHIDRA_INSTALL_DIR,
    [string]$OutDir = (Join-Path $PSScriptRoot "dist")
)
$ErrorActionPreference = "Stop"
$ExtName = "Zeekr_RH850"

if (-not $GhidraDir -or -not (Test-Path (Join-Path $GhidraDir "Ghidra\application.properties"))) {
    throw "Pass -GhidraDir (or set GHIDRA_INSTALL_DIR) to a Ghidra installation folder."
}
$props = Get-Content (Join-Path $GhidraDir "Ghidra\application.properties")
$version = (($props | Where-Object { $_ -like "application.version=*" }) -split "=", 2)[1].Trim()
$release = (($props | Where-Object { $_ -like "application.release.name=*" }) -split "=", 2)[1].Trim()
Write-Host "Ghidra $version $release at $GhidraDir"

# Ghidra's launcher needs a JDK; reuse the one pinned in launch.properties when JAVA_HOME is unset.
if (-not $env:JAVA_HOME) {
    $override = Get-Content (Join-Path $GhidraDir "support\launch.properties") |
        Where-Object { $_ -like "JAVA_HOME_OVERRIDE=*" } | Select-Object -First 1
    if ($override) { $env:JAVA_HOME = ($override -split "=", 2)[1].Trim() }
}
if (-not $env:JAVA_HOME -or -not (Test-Path (Join-Path $env:JAVA_HOME "bin\java.exe"))) {
    throw "JAVA_HOME must point to a JDK $((($props | Where-Object { $_ -like 'application.java.min=*' }) -split '=', 2)[1])+ installation."
}
$env:PATH = (Join-Path $env:JAVA_HOME "bin") + ";" + $env:PATH

# Stage exactly what the extension needs.
$stageRoot = Join-Path $PSScriptRoot "build\$version"
$stage = Join-Path $stageRoot $ExtName
if (Test-Path $stageRoot) { Remove-Item -Recurse -Force $stageRoot }
New-Item -ItemType Directory -Force (Join-Path $stage "data") | Out-Null
Copy-Item (Join-Path $PSScriptRoot "Module.manifest") $stage
Copy-Item (Join-Path $PSScriptRoot "README.md") $stage
Copy-Item -Recurse (Join-Path $PSScriptRoot "data\languages") (Join-Path $stage "data\languages")
Copy-Item -Recurse (Join-Path $PSScriptRoot "data\manuals") (Join-Path $stage "data\manuals")
# Exact extension match: "-Filter *.sla" would also match *.slaspec on Windows.
Get-ChildItem -Recurse -File (Join-Path $stage "data") | Where-Object { $_.Extension -eq ".sla" } | Remove-Item -Force

$date = (Get-Date).ToString("yyyy-MM-dd", [Globalization.CultureInfo]::InvariantCulture)
$ext = (Get-Content (Join-Path $PSScriptRoot "extension.properties")) |
    ForEach-Object { $_ -replace "@extversion@", $version -replace "^createdOn=.*$", "createdOn=$date" }
[IO.File]::WriteAllLines((Join-Path $stage "extension.properties"), [string[]]$ext)

# Compile with this Ghidra's SLEIGH.
$sleigh = Join-Path $GhidraDir "support\sleigh.bat"
$spec = Join-Path $stage "data\languages\RH850.slaspec"
# cmd /s /c "" "bat" "arg" "" keeps paths with spaces intact; the string is passed to cmd verbatim.
$proc = Start-Process -FilePath "$env:SystemRoot\System32\cmd.exe" -NoNewWindow -Wait -PassThru `
    -ArgumentList ('/d /s /c ""' + $sleigh + '" "' + $spec + '""')
$sla = [IO.Path]::ChangeExtension($spec, ".sla")
if ($proc.ExitCode -ne 0 -or -not (Test-Path $sla) -or (Get-Item $sla).Length -eq 0) {
    throw "SLEIGH compile failed (exit $($proc.ExitCode))."
}
Write-Host "Compiled $sla ($((Get-Item $sla).Length) bytes)"

# Zip with forward-slash entry names (Windows PowerShell's Compress-Archive writes backslashes).
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
New-Item -ItemType Directory -Force $OutDir | Out-Null
$stamp = (Get-Date).ToString("yyyyMMdd", [Globalization.CultureInfo]::InvariantCulture)
$zipPath = Join-Path $OutDir "ghidra_${version}_${release}_${stamp}_${ExtName}.zip"
if (Test-Path $zipPath) { Remove-Item -Force $zipPath }
$zip = [IO.Compression.ZipFile]::Open($zipPath, [IO.Compression.ZipArchiveMode]::Create)
try {
    $base = (Resolve-Path $stageRoot).Path.TrimEnd('\') + '\'
    Get-ChildItem -Recurse -File $stage | ForEach-Object {
        $entry = $_.FullName.Substring($base.Length).Replace('\', '/')
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, $entry, [IO.Compression.CompressionLevel]::Optimal) | Out-Null
    }
}
finally {
    $zip.Dispose()
}
$hash = (Get-FileHash $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Host "Built $zipPath"
Write-Host "SHA-256 $hash"
