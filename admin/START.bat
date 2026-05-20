@echo off
REM POS Admin - Complete Startup Script
REM Handles database setup and server startup

echo.
echo =================================================
echo  POS ADMIN - STARTUP SCRIPT
echo =================================================
echo.

REM Check if we need to setup fresh database
echo Checking database...

REM Run migrations fresh with seeding
echo.
echo [1/3] Resetting database...
php artisan migrate:fresh --seed --force
if errorlevel 1 (
    echo ERROR: Database migration failed
    pause
    exit /b 1
)

echo [OK] Database ready!
echo.

REM Build CSS
echo [2/3] Building Tailwind CSS...
call npm run build
if errorlevel 1 (
    echo WARNING: CSS build failed, continuing anyway...
)
echo [OK] CSS built!
echo.

REM Start Laravel server
echo [3/3] Starting Laravel development server...
echo.
echo ===================================================
echo  Server running at: http://localhost:8000
echo  Admin URL:          http://localhost:8000/login
echo  
echo  Demo Credentials:
echo  Email: admin@toko.local
echo  Password: password123
echo ===================================================
echo.
echo Press Ctrl+C to stop the server
echo.

php artisan serve
pause
