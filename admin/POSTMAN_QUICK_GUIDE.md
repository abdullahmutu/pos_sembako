# 🧪 Testing API Dengan Postman - Step by Step

## Step 1: Download & Install Postman

1. Buka https://www.postman.com/downloads/
2. Download sesuai OS (Windows/Mac/Linux)
3. Install dan buka aplikasi

---

## Step 2: Setup Environment Variables

1. Klik **Environments** di kiri
2. Klik **Create New**
3. Beri nama: `POS Development`
4. Tambah variable:
    - `base_url` = `http://localhost:8000`
    - `api_version` = `/api/v1`
    - `admin_token` = (kosongkan, akan diisi nanti)
    - `kasir_token` = (kosongkan, akan diisi nanti)
5. Klik **Save**

---

## Step 3: Test Authentication

### 3.1 Login Admin

**Step:**

1. Klik **New** → **Request**
2. Ubah method ke **POST**
3. URL: `{{base_url}}{{api_version}}/auth/login`
4. Pilih tab **Body**
5. Pilih **raw** → **JSON**
6. Copy-paste:

```json
{
    "email": "admin@toko.local",
    "password": "password123"
}
```

7. Klik **Send**

**Expected Response:**

- Status: **200 OK**
- Dapat `token` di response
- **Copy token**, paste ke environment `admin_token`

### 3.2 Login Kasir

**Step:**

1. Buat request baru (POST)
2. URL: `{{base_url}}{{api_version}}/auth/login`
3. Body:

```json
{
    "email": "kasir1@toko.local",
    "password": "password123"
}
```

4. Klik **Send**
5. **Copy token**, paste ke environment `kasir_token`

### 3.3 Get Profile

**Step:**

1. Buat request baru (GET)
2. URL: `{{base_url}}{{api_version}}/auth/me`
3. Pilih tab **Headers**
4. Tambah:
    - Key: `Authorization`
    - Value: `Bearer {{admin_token}}`
5. Klik **Send**

---

## Step 4: Test Produk (Admin)

### 4.1 Get All Produk

```
Method: GET
URL: {{base_url}}{{api_version}}/products
Header: Authorization: Bearer {{admin_token}}
```

### 4.2 Create Produk

```
Method: POST
URL: {{base_url}}{{api_version}}/products
Header: Authorization: Bearer {{admin_token}}
Body (JSON):
{
  "sku": "TEST001",
  "name": "Produk Test",
  "category_id": 1,
  "purchase_price": 10000,
  "selling_price": 15000,
  "stock": 100,
  "min_stock": 10,
  "unit": "pcs"
}
```

### 4.3 Update Produk

```
Method: PUT
URL: {{base_url}}{{api_version}}/products/1
Header: Authorization: Bearer {{admin_token}}
Body (JSON):
{
  "name": "Produk Updated",
  "stock": 80
}
```

### 4.4 Delete Produk

```
Method: DELETE
URL: {{base_url}}{{api_version}}/products/1
Header: Authorization: Bearer {{admin_token}}
```

---

## Step 5: Test Kategori (Admin)

### 5.1 Get All Kategori

```
Method: GET
URL: {{base_url}}{{api_version}}/categories
Header: Authorization: Bearer {{admin_token}}
```

### 5.2 Create Kategori

```
Method: POST
URL: {{base_url}}{{api_version}}/categories
Header: Authorization: Bearer {{admin_token}}
Body (JSON):
{
  "name": "Kategori Baru",
  "description": "Deskripsi kategori"
}
```

---

## Step 6: Test Pelanggan

### 6.1 Get All Pelanggan

```
Method: GET
URL: {{base_url}}{{api_version}}/customers
Header: Authorization: Bearer {{admin_token}}
```

### 6.2 Get Debtors (Pelanggan dengan Utang)

```
Method: GET
URL: {{base_url}}{{api_version}}/customers/debtors
Header: Authorization: Bearer {{admin_token}}
```

### 6.3 Create Pelanggan

```
Method: POST
URL: {{base_url}}{{api_version}}/customers
Header: Authorization: Bearer {{kasir_token}}
Body (JSON):
{
  "name": "Pelanggan Baru",
  "phone": "081234567890",
  "address": "Jl. Test No. 1",
  "customer_type": "regular"
}
```

---

## Step 7: Test Transaksi Penjualan (Kasir)

### 7.1 Get All Transaksi

```
Method: GET
URL: {{base_url}}{{api_version}}/sales-transactions
Header: Authorization: Bearer {{kasir_token}}
```

### 7.2 Get Today's Report

```
Method: GET
URL: {{base_url}}{{api_version}}/sales-transactions/reports/today
Header: Authorization: Bearer {{kasir_token}}
```

### 7.3 Create Transaksi (CASH)

```
Method: POST
URL: {{base_url}}{{api_version}}/sales-transactions
Header: Authorization: Bearer {{kasir_token}}
Body (JSON):
{
  "customer_id": null,
  "payment_type": "cash",
  "discount": 5000,
  "tax": 2500,
  "items": [
    {
      "product_id": 1,
      "quantity": 2,
      "unit_price": 2500
    }
  ]
}
```

### 7.4 Create Transaksi (UTANG)

```
Method: POST
URL: {{base_url}}{{api_version}}/sales-transactions
Header: Authorization: Bearer {{kasir_token}}
Body (JSON):
{
  "customer_id": 2,
  "payment_type": "debt",
  "items": [
    {
      "product_id": 1,
      "quantity": 5,
      "unit_price": 8000
    }
  ]
}
```

---

## Step 8: Test Pembayaran Utang

### 8.1 Get Receivables (Utang)

```
Method: GET
URL: {{base_url}}{{api_version}}/payments/receivables
Header: Authorization: Bearer {{admin_token}}
```

### 8.2 Record Pembayaran

```
Method: POST
URL: {{base_url}}{{api_version}}/payments/record
Header: Authorization: Bearer {{admin_token}}
Body (JSON):
{
  "customer_receivable_id": 1,
  "amount": 50000,
  "payment_method": "cash",
  "reference": "payment-001"
}
```

### 8.3 Get Payment History

```
Method: GET
URL: {{base_url}}{{api_version}}/payments/history
Header: Authorization: Bearer {{admin_token}}
```

---

## Step 9: Test Dashboard

### 9.1 Admin Dashboard

```
Method: GET
URL: {{base_url}}{{api_version}}/dashboard/admin
Header: Authorization: Bearer {{admin_token}}
```

**Response:**

```json
{
  "todays_sales": 250000,
  "total_debt": 400000,
  "low_stock_count": 2,
  "top_products": [...]
}
```

### 9.2 Kasir Dashboard

```
Method: GET
URL: {{base_url}}{{api_version}}/dashboard/kasir
Header: Authorization: Bearer {{kasir_token}}
```

---

## Step 10: Test Authorization (Security)

### 10.1 Kasir Coba Akses Admin Endpoint (SHOULD FAIL)

```
Method: POST
URL: {{base_url}}{{api_version}}/products
Header: Authorization: Bearer {{kasir_token}}
Body: {...}

Expected: 403 Forbidden
```

### 10.2 Request Tanpa Token (SHOULD FAIL)

```
Method: GET
URL: {{base_url}}{{api_version}}/products

Expected: 401 Unauthenticated
```

### 10.3 Invalid Token (SHOULD FAIL)

```
Method: GET
URL: {{base_url}}{{api_version}}/products
Header: Authorization: Bearer invalid_token

Expected: 401 Unauthenticated
```

---

## Checklist Testing

- [ ] Login admin berhasil, dapat token
- [ ] Login kasir berhasil, dapat token
- [ ] Get all products
- [ ] Get all categories
- [ ] Create product (admin)
- [ ] Update product (admin)
- [ ] Delete product (admin)
- [ ] Kasir blocked dari product creation
- [ ] Create customer
- [ ] Create transaksi cash
- [ ] Create transaksi utang
- [ ] Verify stock berkurang setelah transaksi
- [ ] Get receivables
- [ ] Record payment
- [ ] Verify utang berkurang setelah pembayaran
- [ ] Admin dashboard stats
- [ ] Kasir dashboard stats

---

## Tips

1. **Gunakan Environment Variables**
    - Jangan hardcode URL
    - Gunakan `{{base_url}}` untuk reusable

2. **Simpan Token Setelah Login**
    - Copy paste ke environment setelah login
    - Atau gunakan test script untuk auto-update

3. **Debug Response**
    - Lihat status code (200/201/400/401/403/422)
    - Lihat response body untuk error detail

4. **Test Urutan**
    - Auth dulu
    - Produk & kategori
    - Pelanggan
    - Transaksi
    - Pembayaran

---

**Selesai! Semua API endpoints sudah teruji** ✅
