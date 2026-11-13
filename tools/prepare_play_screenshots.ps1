Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "Stop"

$screenshotsDir = Join-Path $PSScriptRoot "..\store_assets\draft\screenshots"
foreach ($name in @("campaign-api37-draft", "m1-defense-api37-draft")) {
    $inputPath = Join-Path $screenshotsDir "$name.png"
    $outputPath = Join-Path $screenshotsDir "$name.jpg"
    if (-not (Test-Path -LiteralPath $inputPath)) { throw "Missing captured screenshot: $inputPath" }
    $image = [System.Drawing.Bitmap]::FromFile($inputPath)
    try {
        if ($image.Width -lt 320 -or $image.Height -lt 320 -or [Math]::Max($image.Width, $image.Height) -gt 3840) { throw "Screenshot dimensions are outside Play's documented range: $($image.Width)x$($image.Height)" }
        if ([Math]::Max($image.Width, $image.Height) -gt 2 * [Math]::Min($image.Width, $image.Height)) { Write-Warning "$name is $($image.Width)x$($image.Height), over Play's 2:1 aspect-ratio limit; recapture/crop before upload." }
        $encoder = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object MimeType -eq "image/jpeg" | Select-Object -First 1
        $parameters = [System.Drawing.Imaging.EncoderParameters]::new(1)
        $parameters.Param[0] = [System.Drawing.Imaging.EncoderParameter]::new([System.Drawing.Imaging.Encoder]::Quality, [long]95)
        try { $image.Save($outputPath, $encoder, $parameters) }
        finally { $parameters.Dispose() }
    }
    finally { $image.Dispose() }
    Write-Output "Wrote $outputPath"
}
