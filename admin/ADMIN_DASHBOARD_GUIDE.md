# 🖥️ Panduan Menjalankan Admin Dashboard

## 1. Setup Database

```bash
cd D:\skripsi\copilot\admin
php artisan migrate
php artisan db:seed
```

## 2. Jalankan Server

```bash
php artisan serve
```

Server akan berjalan di: **http://localhost:8000**

## 3. Login ke Admin Dashboard

Buka browser dan akses: http://localhost:8000/admin/dashboard

**Credentials:**

- **Email:** admin@toko.local
- **Password:** password123

## 4. Halaman-halaman yang Tersedia

### 📊 Dashboard

- Akses: http://localhost:8000/admin/dashboard
- **Fitur:**
    - Total penjualan hari ini
    - Total utang pelanggan
    - Total produk
    - Jumlah stok rendah
    - Top 5 produk terjual
    - Transaksi terbaru

### 📦 Manajemen Produk

- Akses: http://localhost:8000/admin/products
- **Fitur:**
    - Lihat semua produk dengan pagination
    - Tambah produk baru
    - Edit produk
    - Hapus produk
    - Indikator stok rendah

### 🏷️ Manajemen Kategori

- Akses: http://localhost:8000/admin/categories
- **Fitur:**
    - Lihat semua kategori
    - Tambah kategori
    - Edit kategori
    - Hapus kategori
    - Aktifkan/Nonaktifkan kategori

### 👥 Manajemen Pelanggan

- Akses: http://localhost:8000/admin/customers
- **Fitur:**
    - Lihat semua pelanggan
    - Tambah pelanggan
    - Edit data pelanggan
    - Hapus pelanggan
    - Lihat detail pelanggan
    - **Riwayat Utang:** Lihat semua transaksi utang pelanggan
    - **Riwayat Pembayaran:** Tracking pembayaran yang sudah diterima

### 📈 Laporan

#### Laporan Penjualan

- Akses: http://localhost:8000/admin/reports/sales
- **Fitur:**
    - Filter penjualan berdasarkan tanggal
    - Total penjualan periode
    - Rincian penjualan harian
    - Rata-rata transaksi per hari

#### Laporan Produk

- Akses: http://localhost:8000/admin/reports/products
- **Fitur:**
    - Laporan top produk terjual
    - Revenue per produk
    - Rata-rata harga jual
    - Filter berdasarkan periode

#### Laporan Utang

- Akses: http://localhost:8000/admin/reports/receivables
- **Fitur:**
    - List semua utang pelanggan
    - Filter berdasarkan status (Belum Dibayar, Sebagian, Lunas)
    - Summary total utang
    - Detail pembayaran untuk setiap utang

---

## 5. Fitur Web Admin

### ✅ Sudah Diimplementasikan

- [x] User authentication (login/logout)
- [x] Dashboard dengan statistics
- [x] CRUD Produk dengan category
- [x] CRUD Kategori
- [x] CRUD Pelanggan
- [x] Detail pelanggan + utang + payment history
- [x] Laporan penjualan (daily, dengan filter)
- [x] Laporan produk (top sellers)
- [x] Laporan utang (receivables dengan status)
- [x] Responsive design (Bootstrap 5)
- [x] Form validation
- [x] Flash messages (success/error)

### 🔒 Security Features

- [x] Admin role checking
- [x] Session authentication
- [x] CSRF protection
- [x] SQL injection protection (Eloquent ORM)
- [x] Password hashing

---

## 6. Database Schema (Web Admin)

Admin dashboard menggunakan table yang sama dengan API:

- `users` - untuk admin login
- `categories` - produk kategori
- `products` - master produk
- `customers` - data pelanggan
- `sales_transactions` - transaksi penjualan
- `sale_items` - detail item transaksi
- `customer_receivables` - buku utang
- `payment_history` - riwayat pembayaran

---

## 7. URL Routes

### Auth Routes

- `GET /login` - Halaman login
- `POST /login` - Process login
- `POST /admin/logout` - Logout

### Admin Routes (Protected)

```
GET    /admin/dashboard                    - Dashboard
GET    /admin/products                     - List produk
GET    /admin/products/create              - Tambah produk
POST   /admin/products                     - Save produk
GET    /admin/products/{id}/edit           - Edit produk
PUT    /admin/products/{id}                - Update produk
DELETE /admin/products/{id}                - Hapus produk

GET    /admin/categories                   - List kategori
GET    /admin/categories/create            - Tambah kategori
POST   /admin/categories                   - Save kategori
GET    /admin/categories/{id}/edit         - Edit kategori
PUT    /admin/categories/{id}              - Update kategori
DELETE /admin/categories/{id}              - Hapus kategori

GET    /admin/customers                    - List pelanggan
GET    /admin/customers/create             - Tambah pelanggan
POST   /admin/customers                    - Save pelanggan
GET    /admin/customers/{id}               - Detail pelanggan
GET    /admin/customers/{id}/edit          - Edit pelanggan
PUT    /admin/customers/{id}               - Update pelanggan
DELETE /admin/customers/{id}               - Hapus pelanggan
GET    /admin/customers/{id}/receivables   - Utang pelanggan

GET    /admin/reports/sales                - Laporan penjualan
GET    /admin/reports/products             - Laporan produk
GET    /admin/reports/receivables          - Laporan utang

POST   /admin/logout                       - Logout
```

---

## 8. Teknologi

- **Framework:** Laravel 13
- **Database:** MySQL
- **Frontend:** Bootstrap 5 + Blade templating
- **Authentication:** Session-based (web)
- **API:** RESTful (untuk mobile app)

---

## 9. Next Steps

1. **Test semua fitur** di admin dashboard
2. **Verify data** di database setelah setiap operasi
3. **Create Flutter kasir app** yang consume API dari backend
4. **Test integration** antara web admin dan mobile kasir

---

## 10. Troubleshooting

### Error: "Hanya admin yang dapat login"

- Pastikan user yang login memiliki `role = 'admin'` di database
- Check: `SELECT * FROM users WHERE email = 'admin@toko.local';`

### Error: 404 Page Not Found

- Jalankan `php artisan migrate` dulu
- Pastikan server running di port 8000

### Error: CSRF token mismatch

- Reload halaman
- Clear browser cache
- Pastikan `SESSION_DRIVER=database` di .env

### Database tidak ter-update

- Pastikan database `toko_pos` sudah dibuat
- Check connection di .env (DB_HOST, DB_USERNAME, DB_PASSWORD)

---

## File Struktur Admin Web

```
resources/views/admin/
├── layouts/
│   └── app.blade.php          (Master layout)
├── auth/
│   └── login.blade.php        (Login page)
├── dashboard.blade.php        (Dashboard)
├── products/
│   ├── index.blade.php        (List produk)
│   ├── create.blade.php       (Tambah produk)
│   └── edit.blade.php         (Edit produk)
├── categories/
│   ├── index.blade.php        (List kategori)
│   ├── create.blade.php       (Tambah kategori)
│   └── edit.blade.php         (Edit kategori)
├── customers/
│   ├── index.blade.php        (List pelanggan)
│   ├── create.blade.php       (Tambah pelanggan)
│   ├── edit.blade.php         (Edit pelanggan)
│   ├── show.blade.php         (Detail pelanggan)
│   └── receivables.blade.php  (Riwayat utang)
└── reports/
    ├── sales.blade.php        (Laporan penjualan)
    ├── products.blade.php     (Laporan produk)
    └── receivables.blade.php  (Laporan utang)

app/Http/Controllers/
├── AdminAuthController.php      (Login/Logout)
├── AdminDashboardController.php (Dashboard)
├── AdminProductController.php   (Product CRUD)
├── AdminCategoryController.php  (Category CRUD)
├── AdminCustomerController.php  (Customer CRUD)
└── AdminReportController.php    (Reports)

app/Http/Middleware/
└── AdminWebMiddleware.php       (Role checking)
```

---

**Admin Dashboard siap digunakan!** 🎉
