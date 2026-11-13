Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "Stop"

$basePath = Join-Path $PSScriptRoot "..\build\play-feature-base.png"
$outputPath = Join-Path $PSScriptRoot "..\store_assets\draft\feature_graphic_1024x500.png"
if (-not (Test-Path -LiteralPath $basePath)) { throw "Feature background is missing; run tools/export_play_assets.gd first." }
$base = [System.Drawing.Bitmap]::FromFile($basePath)
$canvas = [System.Drawing.Bitmap]::new(1024, 500, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
try {
    if ($base.Width -ne 1024 -or $base.Height -ne 500) { throw "Feature background must be 1024x500." }
    $graphics = [System.Drawing.Graphics]::FromImage($canvas)
    try {
        $graphics.DrawImage($base, 0, 0, 1024, 500)
        $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
        $ivory = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(241, 238, 229))
        $gold = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(223, 199, 137))
        $muted = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(182, 192, 191))
        $smallFont = [System.Drawing.Font]::new("Arial", 25, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
        $titleFont = [System.Drawing.Font]::new("Arial", 58, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
        $taglineFont = [System.Drawing.Font]::new("Arial", 24, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
        try {
            $title = "HOLO TACTICS"
            if ($graphics.MeasureString($title, $titleFont).Width -gt 480) { throw "Title exceeds its 480px text area." }
            $graphics.DrawString("PIXEL FANTASY STRATEGY", $smallFont, $gold, 64, 167)
            $graphics.DrawString($title, $titleFont, $ivory, 58, 205)
            $graphics.DrawString("DEFEND  |  ADVANCE  |  EVOLVE", $taglineFont, $muted, 64, 352)
        }
        finally {
            $smallFont.Dispose()
            $titleFont.Dispose()
            $taglineFont.Dispose()
            $ivory.Dispose()
            $gold.Dispose()
            $muted.Dispose()
        }
    }
    finally { $graphics.Dispose() }
    $canvas.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
}
finally {
    $canvas.Dispose()
    $base.Dispose()
}

$result = [System.Drawing.Image]::FromFile($outputPath)
try {
    if ($result.Width -ne 1024 -or $result.Height -ne 500) { throw "Feature graphic output has wrong dimensions." }
    Write-Output "Wrote $outputPath ($($result.Width)x$($result.Height), $((Get-Item $outputPath).Length) bytes)"
}
finally { $result.Dispose() }
