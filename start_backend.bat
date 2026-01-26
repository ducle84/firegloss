@echo off
echo Starting FireGloss Backend Server...
echo.
echo Navigate to backend directory
cd firegloss_backend

echo Activating virtual environment...
call venv\Scripts\activate.bat

echo.
echo Server will start at: http://127.0.0.1:8000
echo API Documentation: http://127.0.0.1:8000/docs
echo Press Ctrl+C to stop the server
echo.

python main.py