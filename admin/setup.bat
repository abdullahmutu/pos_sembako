@echo off
REM Laravel Admin Backend - Setup Script (Windows)

echo ==========================================
echo POS System - Laravel Admin Backend Setup
echo ==========================================
echo.

cd /d "D:\skripsi\copilot\admin"

echo 1. Installing Composer dependencies...
call composer install
if %ERRORLEVEL% neq 0 (
    echo ERROR: Composer install failed
    exit /b 1
)
echo Done - Dependencies installed
echo.

echo 2. Generating application key...
php artisan key:generate
if %ERRORLEVEL% neq 0 (
    echo ERROR: Key generation failed
    exit /b 1
)
echo Done - Application key generated
echo.

echo 3. Running database migrations...
php artisan migrate
if %ERRORLEVEL% neq 0 (
    echo ERROR: Migrations failed
    exit /b 1
)
echo Done - Migrations completed
echo.

echo 4. Seeding database with sample data...
php artisan db:seed
if %ERRORLEVEL% neq 0 (
    echo ERROR: Seeding failed
    exit /b 1
)
echo Done - Database seeded
echo.

echo ==========================================
echo SUCCESS - Setup completed!
echo ==========================================
echo.
echo Sample credentials:
echo   Admin: admin@toko.local / password123
echo   Kasir 1: kasir1@toko.local / password123
echo   Kasir 2: kasir2@toko.local / password123
echo.
echo To start the server, run:
echo   php artisan serve
echo.
echo API documentation: API_DOCUMENTATION.md
echo ==========================================
pause
