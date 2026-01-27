@echo off
echo ==========================================
echo   FireGloss Backend Server (Python Mode)
echo ==========================================
echo.

echo [1/3] Checking current directory...
cd /d "%~dp0"
echo Current directory: %cd%
echo.

echo [2/3] Navigating to backend directory...
if exist "firegloss_backend" (
    cd firegloss_backend
    echo Success: Changed to firegloss_backend directory
    echo Current directory: %cd%
) else (
    echo ERROR: firegloss_backend directory not found!
    echo Make sure you're running this from the project root directory.
    goto :error
)
echo.

echo [3/3] Starting backend server using Python...
echo Note: This method doesn't use virtual environment
echo.
echo Server will start at: http://127.0.0.1:8000
echo API Documentation: http://127.0.0.1:8000/docs
echo.
echo Press Ctrl+C to stop the server
echo ==========================================
echo.

python start_server.py

echo.
echo ==========================================
echo Server has stopped.
goto :end

:error
echo.
echo ==========================================
echo STARTUP FAILED!
echo Check the error messages above.
echo ==========================================

:end
echo.
echo Press any key to close this window...
pause > nul