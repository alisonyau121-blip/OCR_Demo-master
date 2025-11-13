# Quick launcher for Flutter commands without PATH setup
# Usage: .\flutter-run.ps1 [command] [args]
# Example: .\flutter-run.ps1 run
# Example: .\flutter-run.ps1 doctor

param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$FlutterArgs
)

$FlutterPath = "C:\flutter\bin\flutter.bat"

if ($FlutterArgs.Count -eq 0) {
    Write-Host "Usage: .\flutter-run.ps1 [command] [args]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Common commands:" -ForegroundColor Cyan
    Write-Host "  .\flutter-run.ps1 run          - Run the app"
    Write-Host "  .\flutter-run.ps1 doctor       - Check Flutter setup"
    Write-Host "  .\flutter-run.ps1 pub get      - Install dependencies"
    Write-Host "  .\flutter-run.ps1 clean        - Clean build files"
    Write-Host "  .\flutter-run.ps1 devices      - List available devices"
    Write-Host "  .\flutter-run.ps1 --version    - Show Flutter version"
    Write-Host ""
    exit 1
}

& $FlutterPath $FlutterArgs

