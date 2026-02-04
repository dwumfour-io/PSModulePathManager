# Build Launcher with Icon and Code Signing Instructions

$ErrorActionPreference = 'Stop'
$scriptRoot = $PSScriptRoot

Write-Host "`n🎨 PSModulePath Manager - Icon & Security Setup" -ForegroundColor Cyan
Write-Host "================================================`n" -ForegroundColor Cyan

# Step 1: Convert PNG to ICO (manual step if ImageMagick not available)
$pngPath = Join-Path $scriptRoot "icon.png"
$icoPath = Join-Path $scriptRoot "icon.ico"

if (-not (Test-Path $icoPath)) {
    Write-Host "⚠️  ICO file not found. Please convert icon.png to icon.ico" -ForegroundColor Yellow
    Write-Host "   Option 1: Use online converter https://convertio.co/png-ico/" -ForegroundColor White
    Write-Host "   Option 2: Install ImageMagick and run:" -ForegroundColor White
    Write-Host "            magick convert icon.png -define icon:auto-resize=256,128,64,48,32,16 icon.ico`n" -ForegroundColor Gray
    
    $continue = Read-Host "Have you created icon.ico? (Y/N)"
    if ($continue -ne 'Y') {
        Write-Host "❌ Please create icon.ico first, then run this script again." -ForegroundColor Red
        exit 1
    }
}

# Step 2: Compile launcher with icon
Write-Host "📦 Compiling launcher with icon..." -ForegroundColor Green

$csPath = Join-Path $scriptRoot "LauncherWithIcon.cs"
$exePath = Join-Path $scriptRoot "PSModulePathManager.exe"

# Find csc.exe
$csc = Get-ChildItem "C:\Windows\Microsoft.NET\Framework64" -Recurse -Filter "csc.exe" | 
    Select-Object -Last 1 -ExpandProperty FullName

if (-not $csc) {
    Write-Host "❌ C# compiler not found!" -ForegroundColor Red
    exit 1
}

# Compile with icon
& $csc /target:winexe /out:$exePath /win32icon:$icoPath $csPath

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Executable compiled with icon: $exePath`n" -ForegroundColor Green
} else {
    Write-Host "❌ Compilation failed!" -ForegroundColor Red
    exit 1
}

# Step 3: Code Signing Instructions
Write-Host "`n🔒 SECURITY: Code Signing Required for Production" -ForegroundColor Yellow
Write-Host "================================================`n" -ForegroundColor Yellow

Write-Host "To pass Windows SmartScreen and security reviews:`n" -ForegroundColor White

Write-Host "Option 1: Purchase Code Signing Certificate (~$100-400/year)" -ForegroundColor Cyan
Write-Host "  Providers: DigiCert, Sectigo, GlobalSign" -ForegroundColor Gray
Write-Host "  After obtaining certificate:" -ForegroundColor Gray
Write-Host "    Set-AuthenticodeSignature -FilePath '$exePath' -Certificate `$cert`n" -ForegroundColor White

Write-Host "Option 2: Self-Signed Certificate (for testing only)" -ForegroundColor Cyan
Write-Host "  `$cert = New-SelfSignedCertificate -Type CodeSigningCert -Subject 'CN=Joe Dwumfour' -CertStoreLocation Cert:\CurrentUser\My" -ForegroundColor White
Write-Host "  Set-AuthenticodeSignature -FilePath '$exePath' -Certificate `$cert`n" -ForegroundColor White

Write-Host "Option 3: GitHub Actions + Azure Key Vault (free for open source)" -ForegroundColor Cyan
Write-Host "  See: https://github.com/marketplace/actions/code-sign-action`n" -ForegroundColor Gray

# Step 4: Update shortcuts with new icon
Write-Host "`n🔗 Updating shortcuts with new icon..." -ForegroundColor Green

$desktopShortcut = "$env:USERPROFILE\Desktop\PSModulePath Manager.lnk"
$startMenuShortcut = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\PSModulePath Manager.lnk"

$shell = New-Object -ComObject WScript.Shell

foreach ($shortcutPath in @($desktopShortcut, $startMenuShortcut)) {
    if (Test-Path $shortcutPath) {
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $exePath
        $shortcut.WorkingDirectory = $scriptRoot
        $shortcut.IconLocation = "$exePath,0"
        $shortcut.Description = "Manage PowerShell Module Paths"
        $shortcut.Save()
        Write-Host "  ✅ Updated: $shortcutPath" -ForegroundColor Gray
    }
}

Write-Host "`n✨ Setup Complete!" -ForegroundColor Green
Write-Host "`nNext Steps:" -ForegroundColor Cyan
Write-Host "  1. ✅ Icon applied to executable" -ForegroundColor White
Write-Host "  2. ⏳ Get code signing certificate (recommended for distribution)" -ForegroundColor White
Write-Host "  3. ⏳ Sign the .exe with certificate" -ForegroundColor White
Write-Host "  4. ⏳ Upload icon.png to GitHub for IconUri in manifest`n" -ForegroundColor White

Write-Host "Your executable: $exePath" -ForegroundColor Cyan
