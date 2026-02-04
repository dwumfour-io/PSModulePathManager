# Create PSModulePath Manager Icon
# Generates a 256x256 PNG icon that can be converted to .ico

Add-Type -AssemblyName System.Drawing

# Create bitmap
$size = 256
$bitmap = New-Object System.Drawing.Bitmap($size, $size)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = 'AntiAlias'
$graphics.InterpolationMode = 'HighQualityBicubic'

# Background - gradient blue
$brush1 = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    [System.Drawing.Point]::new(0, 0),
    [System.Drawing.Point]::new($size, $size),
    [System.Drawing.Color]::FromArgb(255, 0, 120, 215),
    [System.Drawing.Color]::FromArgb(255, 0, 90, 158)
)
$graphics.FillRectangle($brush1, 0, 0, $size, $size)

# Draw folder icon
$folderColor = [System.Drawing.Color]::FromArgb(255, 255, 193, 7)
$folderBrush = New-Object System.Drawing.SolidBrush($folderColor)
$folderPath = New-Object System.Drawing.Drawing2D.GraphicsPath

# Folder shape
$folderPath.AddLine(50, 100, 120, 100)
$folderPath.AddLine(120, 100, 130, 80)
$folderPath.AddLine(130, 80, 200, 80)
$folderPath.AddLine(200, 80, 210, 100)
$folderPath.AddLine(210, 100, 210, 180)
$folderPath.AddLine(210, 180, 50, 180)
$folderPath.CloseFigure()
$graphics.FillPath($folderBrush, $folderPath)

# Draw path/arrow
$pathPen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 12)
$pathPen.StartCap = 'Round'
$pathPen.EndCap = 'ArrowAnchor'
$graphics.DrawLine($pathPen, 70, 130, 190, 130)

# Draw "PS>" text
$font = New-Object System.Drawing.Font("Consolas", 32, [System.Drawing.FontStyle]::Bold)
$textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$graphics.DrawString("PS", $font, $textBrush, 85, 190)

# Save PNG
$pngPath = Join-Path $PSScriptRoot "icon.png"
$bitmap.Save($pngPath, [System.Drawing.Imaging.ImageFormat]::Png)

Write-Host "✅ Icon created: $pngPath" -ForegroundColor Green

# Clean up
$graphics.Dispose()
$bitmap.Dispose()

# Try to convert to ICO using online tool or ImageMagick if available
if (Get-Command magick -ErrorAction SilentlyContinue) {
    $icoPath = Join-Path $PSScriptRoot "icon.ico"
    & magick convert $pngPath -define icon:auto-resize=256,128,64,48,32,16 $icoPath
    Write-Host "✅ ICO file created: $icoPath" -ForegroundColor Green
} else {
    Write-Host "`n⚠️  To create .ico file, either:" -ForegroundColor Yellow
    Write-Host "   1. Install ImageMagick: winget install ImageMagick.ImageMagick" -ForegroundColor Cyan
    Write-Host "   2. Use online converter: https://convertio.co/png-ico/" -ForegroundColor Cyan
    Write-Host "`nUpload icon.png and download as icon.ico" -ForegroundColor White
}

Write-Host "`n📁 Icon location: $PSScriptRoot" -ForegroundColor Cyan
