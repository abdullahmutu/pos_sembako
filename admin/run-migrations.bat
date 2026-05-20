@echo off
cd /d "D:\skripsi\copilot\admin"
php artisan migrate --force
php artisan db:seed
pause
