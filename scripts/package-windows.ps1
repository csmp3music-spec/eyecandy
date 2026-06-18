param(
    [string]$Date = (Get-Date -Format "yyyyMMdd"),
    [ValidateSet("x86_64-unknown-windows-msvc", "aarch64-unknown-windows-msvc")]
    [string]$Triple = "x86_64-unknown-windows-msvc",
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$Dist = Join-Path $Root "dist"
$Product = "eyecandy"
$ArchName = if ($Triple -like "aarch64*") { "windows-arm64" } else { "windows-x64" }
$PackageName = "eyecandy-$ArchName-$Date"
$PackageDir = Join-Path $Dist $PackageName
$ZipPath = Join-Path $Dist "$PackageName.zip"
$ExePath = Join-Path $Root ".build\$Triple\release\$Product.exe"

if ($Date -notmatch '^\d{8}$') {
    throw "Date must be YYYYMMDD, got: $Date"
}

New-Item -ItemType Directory -Force -Path $Dist | Out-Null

if (-not $SkipBuild) {
    swift build `
        --package-path $Root `
        -c release `
        --triple $Triple `
        --product $Product
}

if (-not (Test-Path $ExePath)) {
    throw "Windows executable not found at $ExePath"
}

Remove-Item -Recurse -Force $PackageDir -ErrorAction SilentlyContinue
Remove-Item -Force $ZipPath -ErrorAction SilentlyContinue

New-Item -ItemType Directory -Force -Path (Join-Path $PackageDir "docs") | Out-Null
Copy-Item $ExePath (Join-Path $PackageDir "$Product.exe")
Copy-Item (Join-Path $Root "README.md") (Join-Path $PackageDir "docs\README.md")
Copy-Item (Join-Path $Root "USER_MANUAL.md") (Join-Path $PackageDir "docs\USER_MANUAL.md")

Compress-Archive -Path $PackageDir -DestinationPath $ZipPath -Force

Write-Host "Packaged $PackageDir"
Write-Host "Created $ZipPath"
