param(
    [switch]$SkipSwift,
    [switch]$SkipGit,
    [switch]$SkipPython
)

$ErrorActionPreference = "Stop"

function Install-WingetPackage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Id,
        [string[]]$ExtraArgs = @()
    )

    $args = @("install", "--id", $Id, "--exact", "--source", "winget", "--accept-package-agreements", "--accept-source-agreements")
    $args += $ExtraArgs
    Write-Host "winget $($args -join ' ')"
    winget @args
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "winget is required. Install App Installer from Microsoft Store, then rerun this script."
}

Install-WingetPackage `
    -Id "Microsoft.VisualStudio.2022.Community" `
    -ExtraArgs @(
        "--force",
        "--custom",
        "--add Microsoft.VisualStudio.Component.Windows11SDK.22621 --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.VC.Tools.ARM64"
    )

if (-not $SkipSwift) {
    Install-WingetPackage -Id "Swift.Toolchain"
}

if (-not $SkipGit) {
    Install-WingetPackage -Id "Git.Git"
}

if (-not $SkipPython) {
    Install-WingetPackage -Id "Python.Python.3.10"
}

Write-Host ""
Write-Host "Windows Swift build dependencies requested. Restart the terminal before building."
Write-Host "Then run: powershell -ExecutionPolicy Bypass -File scripts/package-windows.ps1"
