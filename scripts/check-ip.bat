@echo off
echo 🌐 Checking Current IP Address...
echo ================================

REM Get current public IP
for /f "delims=" %%i in ('curl -s https://api.ipify.org') do set CURRENT_IP=%%i

echo Current Public IP: %CURRENT_IP%
echo.

REM Check if IP file exists
if exist "last_ip.txt" (
    set /p LAST_IP=<last_ip.txt
    echo Last Known IP: %LAST_IP%
    
    if "%CURRENT_IP%"=="%LAST_IP%" (
        echo ✅ IP unchanged - No action needed
    ) else (
        echo 🔄 IP CHANGED! Action required:
        echo.
        echo 📝 Manual Steps:
        echo    1. Go to https://developer.clashofclans.com/
        echo    2. Create new API key for IP: %CURRENT_IP%
        echo    3. Update application.properties with new key
        echo    4. Restart Spring Boot application
        echo.
        echo %CURRENT_IP% > last_ip.txt
        echo 💾 Saved new IP to file
    )
) else (
    echo 📝 First run - saving current IP
    echo %CURRENT_IP% > last_ip.txt
)

echo.
echo Press any key to exit...
pause >nul
