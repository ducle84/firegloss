@echo off
echo ==========================================
echo      FireGloss Backend Server Startup
echo ==========================================
echo.

echo [1/5] Checking current directory...
cd /d "%~dp0"
echo Current directory: %cd%
echo.

echo [2/5] Navigating to backend directory...
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

echo [3/5] Checking Python installation...
python --version
if %ERRORLEVEL% neq 0 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python 3.8+ from python.org
    goto :error
)
echo.

echo [4/5] Checking virtual environment...
if exist "venv\Scripts\activate.bat" (
    echo Found virtual environment. Activating...
    call venv\Scripts\activate.bat
    echo Virtual environment activated successfully
) else (
    echo WARNING: Virtual environment not found in venv\Scripts\
    echo Attempting to create virtual environment...
    python -m venv venv
    if %ERRORLEVEL% neq 0 (
        echo ERROR: Failed to create virtual environment
        goto :error
    )
    echo Virtual environment created successfully
    call venv\Scripts\activate.bat
    echo Installing dependencies...
    pip install -r requirements.txt
)
echo.

echo [5/5] Starting the backend server...
echo.
echo Server will start at: http://127.0.0.1:8000
echo API Documentation: http://127.0.0.1:8000/docs
echo.
echo Press Ctrl+C to stop the server
echo ==========================================
echo.

python main.py

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