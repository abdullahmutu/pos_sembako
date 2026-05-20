# 🚀 SETUP TAILWIND CSS + START SERVER

## Quick Start (1 Command)

Double-click **`START.bat`** from the project folder

This will:

1. ✅ Reset database with fresh migrations + sample data
2. ✅ Build Tailwind CSS
3. ✅ Start Laravel development server
4. ✅ Open http://localhost:8000 in browser

---

## Manual Setup (Step by Step)

### Step 1: Install Node Dependencies

```bash
npm install
```

### Step 2: Build Tailwind CSS

```bash
# Development (with watch mode)
npm run dev

# Or production build
npm run build
```

### Step 3: Setup Database

```bash
# Reset database fresh with sample data
php artisan migrate:fresh --seed
```

### Step 4: Start Laravel Server

```bash
php artisan serve
```

Server will run at: **http://localhost:8000**

---

## Login Credentials

After setup, open http://localhost:8000/login

| Role    | Email               | Password      |
| ------- | ------------------- | ------------- |
| Admin   | `admin@toko.local`  | `password123` |
| Kasir 1 | `kasir1@toko.local` | `password123` |
| Kasir 2 | `kasir2@toko.local` | `password123` |

---

## Troubleshooting

### Issue: "npm command not found"

**Solution:** Install Node.js from https://nodejs.org/

### Issue: "PHP command not found"

**Solution:** Install PHP and add to PATH, or use XAMPP/Laragon

### Issue: Database connection error

**Solution:** Check `.env` file:

```env
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=toko_pos
DB_USERNAME=root
DB_PASSWORD=
```

### Issue: "Port 8000 already in use"

**Solution:** Change port:

```bash
php artisan serve --port=8001
```

### Issue: CSS not loading (blank page)

**Solution:** Rebuild CSS:

```bash
npm run build
# or
npm run dev
```

---

## File Structure

```
admin/
├── START.bat                          ← Double-click to start
├── package.json                       ← Node dependencies
├── vite.config.js                     ← Vite + Tailwind config
│
├── resources/
│   ├── css/
│   │   └── app.css                   ← Tailwind CSS import
│   │
│   ├── js/
│   │   └── app.js                    ← Main JS entry
│   │
│   └── views/
│       └── admin/
│           ├── layouts/
│           │   └── app.blade.php     ← Master layout (Tailwind)
│           ├── auth/
│           │   └── login.blade.php   ← Login page (Tailwind)
│           ├── dashboard.blade.php   ← Dashboard (Tailwind)
│           ├── products/             ← Product pages (To convert)
│           ├── categories/           ← Category pages (To convert)
│           ├── customers/            ← Customer pages (To convert)
│           └── reports/              ← Report pages (To convert)
│
├── app/
│   ├── Http/Controllers/              ← API & Web controllers
│   └── Models/                        ← Database models
│
├── database/
│   ├── migrations/                    ← Database schema
│   └── seeders/                       ← Sample data
│
└── routes/
    ├── api.php                        ← API routes
    └── web.php                        ← Web routes
```

---

## Documentation Files

- **API_DOCUMENTATION.md** - Complete API reference
- **POSTMAN_QUICK_GUIDE.md** - API testing guide
- **ADMIN_DASHBOARD_GUIDE.md** - Dashboard usage guide
- **TAILWIND_CSS_MIGRATION.md** - CSS migration details
- **EXECUTION_SUMMARY.md** - Project overview

---

## Features Implemented

### ✅ Dashboard

- 4-column stats grid (responsive)
- Top 5 products table
- Recent transactions table
- Low stock warning

### ✅ Authentication

- Session-based login
- Demo credentials pre-loaded
- Remember me option

### ✅ API (Complete)

- 35+ RESTful endpoints
- Token-based authentication (Sanctum)
- Role-based access control
- Pagination & filtering

### ⏳ Admin Pages (To Convert to Tailwind)

- Product management (CRUD)
- Category management (CRUD)
- Customer management (CRUD)
- Sales reports
- Product reports
- Receivables reports

---

## Technology Stack

- **Backend:** Laravel 13
- **Frontend:** Vite + Tailwind CSS 4.0
- **Database:** MySQL
- **Authentication:** Session (web) + Sanctum (API)
- **Icons:** Bootstrap Icons
- **Development:** Node.js + npm

---

## Next Steps

1. **Start the server** with `START.bat`
2. **Login** with admin@toko.local / password123
3. **Test dashboard** - verify all stats display correctly
4. **Convert remaining pages** to Tailwind CSS
5. **Build Flutter kasir** app to consume the API

---

## Development Tips

### Hot Reload CSS

While `npm run dev` is running:

- Edit `.blade.php` files → CSS updates instantly
- Edit `resources/css/app.css` → refreshes automatically
- No need to restart servers

### Build for Production

```bash
npm run build
```

Creates optimized CSS in `public/build/`

### Testing API

Use **POSTMAN_QUICK_GUIDE.md** for step-by-step instructions

### Database Reset

If you mess up data:

```bash
php artisan migrate:fresh --seed
```

This deletes all data and restarts fresh!

---

## Support

**Q: Can I use this with production servers?**
A: Yes! Follow deployment guide for your hosting provider.

**Q: How do I add new pages?**
A: Create `.blade.php` files in `resources/views/admin/` and use Tailwind classes. See `dashboard.blade.php` for examples.

**Q: Can I customize colors?**
A: Edit `resources/css/app.css` to change Tailwind colors, or use a `tailwind.config.js` file.

---

**Ready to go!** 🚀 Double-click **START.bat** to begin.
