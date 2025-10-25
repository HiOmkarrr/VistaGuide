# Quick Model Install Script
# Run this in PowerShell to copy the model to your device

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " VistaGuide Model Installation Script  " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if device is connected
Write-Host "Checking for connected device..." -ForegroundColor Yellow
$devices = adb devices
if ($devices -match "device$") {
    Write-Host "✅ Device found!" -ForegroundColor Green
} else {
    Write-Host "❌ No device found. Please connect your phone via USB." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "📁 Pushing model file to device..." -ForegroundColor Yellow
Write-Host "   Size: 524 MB" -ForegroundColor Gray
Write-Host "   This will take 5-10 minutes..." -ForegroundColor Gray
Write-Host ""

# Push to Download folder first
$modelPath = "assets\models\gemma3-1B-it-int4.tflite"
adb push $modelPath /sdcard/Download/gemma3-1B-it-int4.tflite

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ File uploaded to /sdcard/Download/" -ForegroundColor Green
    Write-Host ""
    Write-Host "📦 Moving to app directory..." -ForegroundColor Yellow
    
    # Move to app directory
    adb shell "mkdir -p /data/user/0/com.example.vistaguide/app_flutter/models/ && cp /sdcard/Download/gemma3-1B-it-int4.tflite /data/user/0/com.example.vistaguide/app_flutter/models/"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Model installed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "📱 Now restart the app on your device" -ForegroundColor Cyan
        Write-Host "   The app will detect the model and skip the download" -ForegroundColor Gray
        Write-Host ""
    } else {
        Write-Host ""
        Write-Host "⚠️  Automatic move failed. Trying alternative method..." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Please run these commands manually in ADB shell:" -ForegroundColor Yellow
        Write-Host "  adb shell" -ForegroundColor Gray
        Write-Host "  run-as com.example.vistaguide" -ForegroundColor Gray
        Write-Host "  mkdir -p /data/data/com.example.vistaguide/app_flutter/models/" -ForegroundColor Gray
        Write-Host "  exit" -ForegroundColor Gray
        Write-Host "  cp /sdcard/Download/gemma3-1B-it-int4.tflite /data/data/com.example.vistaguide/app_flutter/models/" -ForegroundColor Gray
        Write-Host "  exit" -ForegroundColor Gray
    }
} else {
    Write-Host ""
    Write-Host "❌ Upload failed!" -ForegroundColor Red
    Write-Host "   Make sure:" -ForegroundColor Yellow
    Write-Host "   - Device is connected via USB" -ForegroundColor Gray
    Write-Host "   - USB debugging is enabled" -ForegroundColor Gray
    Write-Host "   - You have enough storage (600+ MB free)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
