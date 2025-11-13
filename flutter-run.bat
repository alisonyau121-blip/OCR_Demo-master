@echo off
REM Quick launcher for Flutter commands without PATH setup
REM Usage: flutter-run.bat [command] [args]
REM Example: flutter-run.bat run
REM Example: flutter-run.bat doctor

if "%1"=="" (
    echo Usage: flutter-run.bat [command] [args]
    echo.
    echo Common commands:
    echo   flutter-run.bat run          - Run the app
    echo   flutter-run.bat doctor       - Check Flutter setup
    echo   flutter-run.bat pub get      - Install dependencies
    echo   flutter-run.bat clean        - Clean build files
    echo   flutter-run.bat devices      - List available devices
    echo.
    exit /b 1
)

C:\flutter\bin\flutter.bat %*

