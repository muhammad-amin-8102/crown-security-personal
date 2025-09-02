@echo off
echo ========================================
echo Crown Security - Stop Application
echo ========================================
echo.

echo Stopping Crown Security application...

docker-compose down

if %errorlevel% equ 0 (
    echo.
    echo ✅ Crown Security has been stopped successfully
    echo.
    choice /C YN /M "Remove all data (complete reset)"
    if errorlevel 2 goto :end
    if errorlevel 1 (
        echo.
        echo Removing all data and volumes...
        docker-compose down -v
        echo ✅ Complete reset performed
    )
) else (
    echo.
    echo ❌ Failed to stop the application
    echo You may need to manually stop containers:
    echo docker ps
    echo docker stop container_name
)

:end
echo.
echo Press any key to exit...
pause >nul
