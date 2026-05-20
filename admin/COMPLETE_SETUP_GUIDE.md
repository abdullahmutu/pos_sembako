# 📋 COMPLETE SETUP GUIDE - POS Admin with Tailwind CSS

## 🎯 Overview

This is a complete POS (Point of Sale) system with:

- **Backend:** Laravel 13 REST API
- **Admin Dashboard:** Vite + Tailwind CSS
- **Mobile App:** Flutter (upcoming)
- **Database:** MySQL with 9 tables

All code is production-ready and fully documented!

---

## 🚀 QUICK START (60 seconds)

### Option 1: Automated (Recommended)

```bash
cd D:\skripsi\copilot\admin
START.bat
```

The batch file will automatically:

1. Reset database
2. Install dependencies
3. Build CSS
4. Start server

Done! Go to http://localhost:8000

### Option 2: Manual Setup

```bash
# 1. Navigate to project
cd D:\skripsi\copilot\admin

# 2. Install dependencies
npm install
composer install

# 3. Setup database
php artisan migrate:fresh --seed

# 4. Start development servers (in separate terminals)
npm run dev      # Terminal 1: Builds Tailwind CSS
php artisan serve # Terminal 2: Starts Laravel server
```

---

## 📖 Documentation Map

### Getting Started

- **THIS FILE** - Overview & quick start
- **SETUP_TAILWIND.md** - Detailed Tailwind setup
- **TAILWIND_CSS_MIGRATION.md** - CSS design details

### API & Testing

- **API_DOCUMENTATION.md** - Complete endpoint reference
- **POSTMAN_QUICK_GUIDE.md** ⭐ - Step-by-step API testing

### Dashboard

- **ADMIN_DASHBOARD_GUIDE.md** - Web interface guide
- **EXECUTION_SUMMARY.md** - Project file inventory

---

## 🔐 Demo Credentials

```
Admin User
├─ Email: admin@toko.local
└─ Password: password123

Kasir 1
├─ Email: kasir1@toko.local
└─ Password: password123

Kasir 2
├─ Email: kasir2@toko.local
└─ Password: password123
```

**Login URL:** http://localhost:8000/login

---

## 📊 Project Structure

```
Admin Dashboard (Web)
├─ Dashboard (Tailwind CSS)
│   ├─ 4-column stats grid
│   ├─ Top 5 products table
│   ├─ Recent transactions
│   └─ Low stock alerts
│
├─ Products
│   ├─ List with pagination
│   ├─ Create new product
│   ├─ Edit product
│   └─ Delete product
│
├─ Categories
│   ├─ List categories
│   ├─ Create category
│   ├─ Edit category
│   └─ Delete category
│
├─ Customers
│   ├─ List with search
│   ├─ Create customer
│   ├─ Edit customer
│   ├─ View customer debt history
│   └─ Manage receivables
│
└─ Reports
    ├─ Sales report (date range)
    ├─ Product sales report
    └─ Receivables/debt report

REST API (/api/v1)
├─ Authentication (Token-based)
│   ├─ Login → get token
│   ├─ Get current user
│   └─ Logout
│
├─ Products (CRUD)
│   ├─ List all products
│   ├─ Create product
│   ├─ Update product
│   └─ Delete product
│
├─ Transactions
│   ├─ Create sale transaction
│   ├─ Get transactions
│   └─ Generate reports
│
└─ Payments
    ├─ Record payment
    ├─ View receivables
    └─ Payment history

Database (MySQL)
├─ users (admin/kasir)
├─ products
├─ categories
├─ customers
├─ sales_transactions
├─ sale_items
├─ customer_receivables
├─ payment_history
└─ product_recommendations
```

---

## 📱 Features Checklist

### Admin Dashboard ✅

- [x] Authentication (login/logout)
- [x] Dashboard with statistics
- [x] Product management (CRUD)
- [x] Category management (CRUD)
- [x] Customer management (CRUD)
- [x] Customer debt tracking
- [x] Sales reports
- [x] Product reports
- [x] Receivables reports
- [x] Responsive design (Tailwind CSS)

### API Endpoints ✅

- [x] Authentication (token-based)
- [x] Product endpoints (35+)
- [x] Category endpoints
- [x] Customer endpoints
- [x] Transaction endpoints
- [x] Payment endpoints
- [x] Dashboard endpoints
- [x] Role-based access control

### Database ✅

- [x] 9 tables with relationships
- [x] Migrations & seeders
- [x] Sample data (admin, kasir, products, etc)
- [x] Soft deletes for data recovery

### Documentation ✅

- [x] API reference
- [x] Testing guides
- [x] Setup instructions
- [x] Postman collections
- [x] Tailwind CSS guide

### Flutter Mobile App ⏳

- [ ] To be implemented
- [ ] Will consume API from `/api/v1`

---

## 🧪 Testing the System

### 1. Test Web Dashboard

```bash
# Start server
php artisan serve

# Open browser
http://localhost:8000/login

# Login with admin@toko.local / password123

# Test features:
✓ Dashboard displays stats correctly
✓ Can create/edit/delete products
✓ Can create/edit/delete categories
✓ Can create/edit/delete customers
✓ Reports generate correctly
✓ Logout works
```

### 2. Test API with Postman

Follow **POSTMAN_QUICK_GUIDE.md**:

```bash
1. Download Postman (postman.com)
2. Open guide (POSTMAN_QUICK_GUIDE.md)
3. Test 10 steps:
   ✓ Login admin → get token
   ✓ Login kasir → get token
   ✓ Create product
   ✓ Create transaction
   ✓ Create debt transaction
   ✓ Record payment
   ✓ etc...
```

### 3. Build & Deploy

For production:

```bash
# Build CSS
npm run build

# Build assets
php artisan build

# Deploy to hosting
# (See .env configuration)
```

---

## 🎨 Tailwind CSS Guide

### Colors Used

- **Primary:** Indigo (indigo-600, indigo-500)
- **Success:** Green (green-600)
- **Warning:** Amber (amber-600)
- **Danger:** Red (red-600)

### Common Patterns

#### Form Input

```html
<input
    class="w-full px-4 py-3 border-2 border-gray-300 rounded-lg focus:border-indigo-600"
/>
```

#### Button

```html
<button
    class="bg-indigo-600 text-white px-6 py-2 rounded-lg hover:bg-indigo-700"
>
    Submit
</button>
```

#### Card

```html
<div class="bg-white rounded-lg shadow p-6">
    <!-- Content -->
</div>
```

#### Table

```html
<div class="overflow-x-auto">
    <table class="w-full text-sm">
        <!-- Rows with hover:bg-gray-50 -->
    </table>
</div>
```

---

## ⚙️ Configuration

### .env File

```env
APP_NAME="POS Admin"
APP_URL=http://localhost:8000
DB_DATABASE=toko_pos
DB_USERNAME=root
DB_PASSWORD=
```

### Database Connection

MySQL must be running and `toko_pos` database created:

```bash
# Via MySQL CLI
mysql -u root -p
CREATE DATABASE toko_pos;
```

Or use XAMPP/Laragon which creates it automatically.

---

## 🔧 Troubleshooting

| Issue                      | Solution                                                  |
| -------------------------- | --------------------------------------------------------- |
| **CSS not loading**        | Run `npm run build`                                       |
| **Database error**         | Check `.env` - DB_HOST, DB_USERNAME, DB_PASSWORD          |
| **Port 8000 in use**       | Use `php artisan serve --port=8001`                       |
| **npm not found**          | Install Node.js from nodejs.org                           |
| **PHP not found**          | Use XAMPP/Laragon or add PHP to PATH                      |
| **Blade syntax errors**    | Check `resources/views/admin/` files for typos            |
| **Login page not showing** | Ensure migrations ran: `php artisan migrate:fresh --seed` |

---

## 📝 Development Workflow

### Making Changes

1. Edit `.blade.php` files in `resources/views/admin/`
2. CSS reloads automatically (if `npm run dev` running)
3. Refresh browser to see changes
4. No need to restart servers!

### Adding New Pages

1. Create file: `resources/views/admin/[module]/[page].blade.php`
2. Use Tailwind classes (see examples in dashboard)
3. Add route in `routes/web.php`
4. Use Tailwind's responsive prefixes: `md:`, `lg:`, etc

### Adding API Endpoints

1. Create controller in `app/Http/Controllers/API/`
2. Add routes in `routes/api.php`
3. Use role-based middleware: `'admin'`, `'kasir'`
4. Test with Postman

---

## 🚢 Deployment Checklist

Before going to production:

- [ ] Run `npm run build` (production CSS)
- [ ] Set `APP_ENV=production` in `.env`
- [ ] Set `APP_DEBUG=false` in `.env`
- [ ] Update database credentials
- [ ] Run `php artisan config:cache`
- [ ] Run `php artisan route:cache`
- [ ] Run `php artisan migrate --force` on server
- [ ] Setup HTTPS certificate
- [ ] Configure backups
- [ ] Monitor logs: `storage/logs/laravel.log`

---

## 📞 Support & Resources

### Documentation

- Laravel: https://laravel.com/docs
- Tailwind: https://tailwindcss.com/docs
- Bootstrap Icons: https://icons.getbootstrap.com/
- Postman: https://learning.postman.com/

### Common Commands

```bash
# Database
php artisan migrate:fresh --seed   # Reset database
php artisan migrate               # Run migrations
php artisan db:seed              # Seed data only

# Cache
php artisan cache:clear          # Clear all cache
php artisan config:cache         # Cache config
php artisan route:cache          # Cache routes

# Build
npm run dev                       # Development build
npm run build                     # Production build
php artisan serve                # Start server

# Utilities
php artisan tinker              # Interactive shell
php artisan queue:work          # Process jobs
php artisan schedule:work       # Run scheduled tasks
```

---

## 🎯 Next Phase: Flutter Mobile App

After testing the web dashboard and API:

1. Create new Flutter project
2. Setup API client to call `/api/v1` endpoints
3. Implement kasir (cashier) interface:
    - Dashboard (sales summary)
    - Transaction creation
    - Payment method selection
    - Customer selection (for debt)
    - Debt management
    - Profile page

See **API_DOCUMENTATION.md** for complete endpoint reference.

---

## ✅ Checklist for First Run

- [ ] Downloaded and extracted project
- [ ] Database `toko_pos` created
- [ ] Node.js and npm installed
- [ ] Ran `npm install && composer install`
- [ ] Ran `php artisan migrate:fresh --seed`
- [ ] Ran `npm run dev` (in background or separate terminal)
- [ ] Ran `php artisan serve`
- [ ] Opened http://localhost:8000/login
- [ ] Successfully logged in with demo credentials
- [ ] Saw dashboard with stats
- [ ] Clicked sidebar links and verified they load
- [ ] Read **POSTMAN_QUICK_GUIDE.md** for API testing

---

## 🎉 Success!

If everything loaded correctly, you have:

- ✅ Fully functional Laravel backend
- ✅ Beautiful Tailwind CSS dashboard
- ✅ Complete REST API (35+ endpoints)
- ✅ Database with sample data
- ✅ Production-ready code

**Next:** Test API with Postman, then build Flutter app! 🚀

---

**Questions?** Check the documentation files in this directory!
