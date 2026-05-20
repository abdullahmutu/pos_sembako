#!/bin/bash
# Laravel Admin Backend - Setup Script

echo "=========================================="
echo "POS System - Laravel Admin Backend Setup"
echo "=========================================="
echo ""

# Change to project directory
cd "D:\skripsi\copilot\admin"

echo "1️⃣  Installing Composer dependencies..."
composer install
if [ $? -ne 0 ]; then
    echo "❌ Composer install failed"
    exit 1
fi
echo "✅ Dependencies installed"
echo ""

echo "2️⃣  Generating application key..."
php artisan key:generate
if [ $? -ne 0 ]; then
    echo "❌ Key generation failed"
    exit 1
fi
echo "✅ Application key generated"
echo ""

echo "3️⃣  Running database migrations..."
php artisan migrate
if [ $? -ne 0 ]; then
    echo "❌ Migrations failed"
    exit 1
fi
echo "✅ Migrations completed"
echo ""

echo "4️⃣  Seeding database with sample data..."
php artisan db:seed
if [ $? -ne 0 ]; then
    echo "❌ Seeding failed"
    exit 1
fi
echo "✅ Database seeded"
echo ""

echo "=========================================="
echo "✅ Setup completed successfully!"
echo "=========================================="
echo ""
echo "📝 Sample credentials:"
echo "   Admin: admin@toko.local / password123"
echo "   Kasir 1: kasir1@toko.local / password123"
echo "   Kasir 2: kasir2@toko.local / password123"
echo ""
echo "🚀 To start the server, run:"
echo "   php artisan serve"
echo ""
echo "📚 API documentation: API_DOCUMENTATION.md"
echo "=========================================="
