# 📋 Panduan Testing API dengan Postman

## 1. Setup Postman

### Download & Install

- Download dari: https://www.postman.com/downloads/
- Install sesuai OS Anda (Windows/Mac/Linux)
- Buka Postman dan buat akun (opsional)

### Import Collection

1. Buka Postman
2. Klik **Import** (top-left)
3. Pilih file `POS_API_Collection.json` (lihat bawah)
4. Klik **Import**
5. Collection otomatis tersedia di sidebar

---

## 2. Setup Environment Variables

Sebelum testing, setup environment untuk base URL dan token.

### Cara:

1. Klik **Environments** (tab samping)
2. Klik **Create New** atau **+**
3. Name: `POS Development`
4. Tambah variables:

| Variable    | Initial Value         | Current Value             |
| ----------- | --------------------- | ------------------------- |
| base_url    | http://localhost:8000 | http://localhost:8000     |
| api_version | /api/v1               | /api/v1                   |
| admin_token |                       | (auto-fill setelah login) |
| kasir_token |                       | (auto-fill setelah login) |

5. Klik **Save**

### Gunakan di Requests:

- URL: `{{base_url}}{{api_version}}/auth/login`
- Header: `Authorization: Bearer {{admin_token}}`

---

## 3. Testing Sequence

### Phase 1: Authentication ✅

**Goal:** Login dan dapatkan token

#### 1.1 Register Kasir Baru (Optional)

```
POST http://localhost:8000/api/v1/auth/register
Content-Type: application/json

{
  "name": "Kasir Baru",
  "email": "kasir_baru@toko.local",
  "password": "password123",
  "password_confirmation": "password123",
  "role": "kasir",
  "phone": "081234567890",
  "address": "Jl. Test No. 1"
}
```

**Expected Response:** 201 Created

```json
{
  "message": "User registered successfully",
  "user": {
    "id": 4,
    "name": "Kasir Baru",
    "email": "kasir_baru@toko.local",
    "role": "kasir",
    ...
  },
  "token": "token_string_here"
}
```

#### 1.2 Login Admin

```
POST http://localhost:8000/api/v1/auth/login
Content-Type: application/json

{
  "email": "admin@toko.local",
  "password": "password123"
}
```

**Expected Response:** 200 OK

```json
{
    "message": "Login successful",
    "user": {
        "id": 1,
        "name": "Admin Toko",
        "email": "admin@toko.local",
        "role": "admin"
    },
    "token": "ADMIN_TOKEN_HERE"
}
```

**✅ ACTION:** Copy token, paste ke environment variable `admin_token`

#### 1.3 Login Kasir

```
POST http://localhost:8000/api/v1/auth/login
Content-Type: application/json

{
  "email": "kasir1@toko.local",
  "password": "password123"
}
```

**✅ ACTION:** Copy token, paste ke environment variable `kasir_token`

#### 1.4 Get Profile

```
GET http://localhost:8000/api/v1/auth/me
Authorization: Bearer {{admin_token}}
```

**Expected:** User info dari token

---

### Phase 2: Products Management (Admin) ✅

#### 2.1 Get All Products

```
GET http://localhost:8000/api/v1/products
Authorization: Bearer {{admin_token}}
```

**Query Params (optional):**

- `?search=mie` - cari produk
- `?category_id=1` - filter kategori
- `?is_active=true` - aktif saja
- `?page=1` - pagination

**Expected:** List produk dengan pagination

#### 2.2 Get Low Stock Products

```
GET http://localhost:8000/api/v1/products/low-stock
Authorization: Bearer {{admin_token}}
```

**Expected:** Produk dengan stock ≤ min_stock

#### 2.3 Get Specific Product

```
GET http://localhost:8000/api/v1/products/1
Authorization: Bearer {{admin_token}}
```

**Expected:** Detail produk dengan relasi

#### 2.4 Create Product

```
POST http://localhost:8000/api/v1/products
Authorization: Bearer {{admin_token}}
Content-Type: application/json

{
  "sku": "TST001",
  "name": "Produk Test",
  "description": "Produk untuk testing",
  "category_id": 1,
  "purchase_price": 10000,
  "selling_price": 15000,
  "stock": 100,
  "min_stock": 10,
  "unit": "pcs"
}
```

**Expected:** 201 Created dengan product id

#### 2.5 Update Product

```
PUT http://localhost:8000/api/v1/products/1
Authorization: Bearer {{admin_token}}
Content-Type: application/json

{
  "name": "Mie Instant Premium",
  "selling_price": 3000,
  "stock": 60
}
```

**Expected:** 200 OK dengan updated product

#### 2.6 Delete Product

```
DELETE http://localhost:8000/api/v1/products/1
Authorization: Bearer {{admin_token}}
```

**Expected:** 200 OK dengan message

---

### Phase 3: Categories (Admin) ✅

#### 3.1 Get All Categories

```
GET http://localhost:8000/api/v1/categories
Authorization: Bearer {{admin_token}}
```

#### 3.2 Get Category with Products

```
GET http://localhost:8000/api/v1/categories/1
Authorization: Bearer {{admin_token}}
```

**Expected:** Category dengan list products

#### 3.3 Create Category

```
POST http://localhost:8000/api/v1/categories
Authorization: Bearer {{admin_token}}
Content-Type: application/json

{
  "name": "Kategori Baru",
  "description": "Deskripsi kategori"
}
```

#### 3.4 Update Category

```
PUT http://localhost:8000/api/v1/categories/1
Authorization: Bearer {{admin_token}}
Content-Type: application/json

{
  "name": "Kategori Updated",
  "is_active": true
}
```

#### 3.5 Delete Category

```
DELETE http://localhost:8000/api/v1/categories/1
Authorization: Bearer {{admin_token}}
```

---

### Phase 4: Customers ✅

#### 4.1 Get All Customers

```
GET http://localhost:8000/api/v1/customers
Authorization: Bearer {{admin_token}}
```

**Query Params:**

- `?search=budi` - cari nama/phone/email
- `?customer_type=regular` - filter regular/reseller
- `?with_debt=true` - hanya punya utang

#### 4.2 Get Debtors Only

```
GET http://localhost:8000/api/v1/customers/debtors
Authorization: Bearer {{admin_token}}
```

**Expected:** Customers dengan total_debt > 0, sorted by debt amount

#### 4.3 Get Customer Details

```
GET http://localhost:8000/api/v1/customers/2
Authorization: Bearer {{admin_token}}
```

**Expected:** Customer dengan relasi receivables & payment history

#### 4.4 Create Customer

```
POST http://localhost:8000/api/v1/customers
Authorization: Bearer {{kasir_token}}
Content-Type: application/json

{
  "name": "Pelanggan Baru",
  "phone": "081234567890",
  "address": "Jl. Test No. 123",
  "email": "pelanggan@test.com",
  "customer_type": "regular"
}
```

#### 4.5 Update Customer

```
PUT http://localhost:8000/api/v1/customers/2
Authorization: Bearer {{admin_token}}
Content-Type: application/json

{
  "name": "Pelanggan Updated",
  "phone": "081234567891"
}
```

---

### Phase 5: Sales Transactions (Kasir) ✅

#### 5.1 Get All Transactions

```
GET http://localhost:8000/api/v1/sales-transactions
Authorization: Bearer {{kasir_token}}
```

**Query Params:**

- `?date_from=2026-04-20` - filter dari tanggal
- `?date_to=2026-04-24` - filter sampai tanggal
- `?payment_type=cash` - filter cash/debt
- `?status=completed` - filter status

#### 5.2 Get Today's Sales Report

```
GET http://localhost:8000/api/v1/sales-transactions/reports/today
Authorization: Bearer {{kasir_token}}
```

**Expected:**

```json
{
    "date": "2026-04-24",
    "total_sales": 500000,
    "cash_sales": 350000,
    "debt_sales": 150000,
    "transaction_count": 5
}
```

#### 5.3 Get Transaction Details

```
GET http://localhost:8000/api/v1/sales-transactions/1
Authorization: Bearer {{kasir_token}}
```

#### 5.4 Create Sales Transaction (CASH)

```
POST http://localhost:8000/api/v1/sales-transactions
Authorization: Bearer {{kasir_token}}
Content-Type: application/json

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
    },
    {
      "product_id": 2,
      "quantity": 1,
      "unit_price": 12000
    }
  ],
  "notes": "Transaksi test kasir"
}
```

**Expected Response:**

```json
{
  "id": 1,
  "invoice_number": "INV-20260424061234",
  "kasir_id": 2,
  "customer_id": null,
  "subtotal": 17000,
  "discount": 5000,
  "tax": 2500,
  "total": 14500,
  "payment_type": "cash",
  "status": "completed",
  "sale_items": [...]
}
```

**⚠️ TEST:** Cek bahwa product stock berkurang

#### 5.5 Create Sales Transaction (DEBT)

```
POST http://localhost:8000/api/v1/sales-transactions
Authorization: Bearer {{kasir_token}}
Content-Type: application/json

{
  "customer_id": 2,
  "payment_type": "debt",
  "discount": 0,
  "tax": 5000,
  "items": [
    {
      "product_id": 3,
      "quantity": 5,
      "unit_price": 8000
    }
  ],
  "notes": "Kredit untuk Siti Nurhaliza"
}
```

**Expected:** Transaction dengan payment_type = "debt"

**⚠️ TEST:** Cek bahwa:

- Customer total_debt bertambah
- CustomerReceivable dibuat
- Stock berkurang

---

### Phase 6: Payments & Receivables ✅

#### 6.1 Get All Receivables

```
GET http://localhost:8000/api/v1/payments/receivables
Authorization: Bearer {{admin_token}}
```

**Query Params:**

- `?status=unpaid` - hanya unpaid
- `?customer_id=2` - receivable pelanggan spesifik

#### 6.2 Get Payment History

```
GET http://localhost:8000/api/v1/payments/history
Authorization: Bearer {{admin_token}}
```

**Query Params:**

- `?customer_id=2` - history pelanggan
- `?date_from=2026-04-20` - filter tanggal

#### 6.3 Record Payment

```
POST http://localhost:8000/api/v1/payments/record
Authorization: Bearer {{admin_token}}
Content-Type: application/json

{
  "customer_receivable_id": 1,
  "amount": 50000,
  "payment_method": "cash",
  "reference": "payment-001",
  "notes": "Pembayaran sebagian"
}
```

**Expected:** 201 Created

**⚠️ TEST:** Cek bahwa:

- PaymentHistory dibuat
- CustomerReceivable: `paid` bertambah, `remaining` berkurang
- Status berubah jadi "partial" atau "paid"
- Customer total_debt berkurang

---

### Phase 7: Recommendations (Admin) ✅

#### 7.1 Get Recommendations

```
GET http://localhost:8000/api/v1/recommendations
Authorization: Bearer {{admin_token}}
```

**Expected:** Active recommendations sorted by priority

#### 7.2 Create Recommendation

```
POST http://localhost:8000/api/v1/recommendations
Authorization: Bearer {{admin_token}}
Content-Type: application/json

{
  "product_id": 1,
  "priority": 1,
  "description": "Produk best-seller minggu ini"
}
```

#### 7.3 Update Recommendation

```
PUT http://localhost:8000/api/v1/recommendations/1
Authorization: Bearer {{admin_token}}
Content-Type: application/json

{
  "priority": 2,
  "is_active": true
}
```

#### 7.4 Delete Recommendation

```
DELETE http://localhost:8000/api/v1/recommendations/1
Authorization: Bearer {{admin_token}}
```

---

### Phase 8: Dashboard ✅

#### 8.1 Admin Dashboard

```
GET http://localhost:8000/api/v1/dashboard/admin
Authorization: Bearer {{admin_token}}
```

**Expected:**

```json
{
  "todays_sales": 250000,
  "total_debt": 400000,
  "low_stock_count": 2,
  "top_products": [...]
}
```

#### 8.2 Kasir Dashboard

```
GET http://localhost:8000/api/v1/dashboard/kasir
Authorization: Bearer {{kasir_token}}
```

**Expected:**

```json
{
    "todays_sales": 100000,
    "pending_transactions": 1,
    "debt_sales": 50000
}
```

---

### Phase 9: Authorization Testing ⚠️

Test bahwa authorization bekerja:

#### 9.1 Kasir coba akses Admin endpoint (SHOULD FAIL)

```
POST http://localhost:8000/api/v1/products
Authorization: Bearer {{kasir_token}}
Content-Type: application/json

{
  "sku": "TST002",
  "name": "Test",
  ...
}
```

**Expected:** 403 Unauthorized

#### 9.2 Tanpa token (SHOULD FAIL)

```
GET http://localhost:8000/api/v1/products
(no Authorization header)
```

**Expected:** 401 Unauthenticated

#### 9.3 Invalid token (SHOULD FAIL)

```
GET http://localhost:8000/api/v1/products
Authorization: Bearer invalid_token_here
```

**Expected:** 401 Unauthenticated

---

### Phase 10: Validation Testing ✅

#### 10.1 Create product tanpa SKU (SHOULD FAIL)

```
POST http://localhost:8000/api/v1/products
Authorization: Bearer {{admin_token}}
Content-Type: application/json

{
  "name": "Test",
  "category_id": 1,
  "purchase_price": 10000,
  "selling_price": 15000,
  "stock": 100,
  "min_stock": 10,
  "unit": "pcs"
}
```

**Expected:** 422 Unprocessable Entity dengan error detail

#### 10.2 Create customer tanpa name (SHOULD FAIL)

```
POST http://localhost:8000/api/v1/customers
Authorization: Bearer {{admin_token}}
Content-Type: application/json

{
  "phone": "081234567890",
  "customer_type": "regular"
}
```

**Expected:** 422 dengan "name required"

---

## 4. Test Checklist

### Authentication ✅

- [ ] Register user baru
- [ ] Login admin mendapat token
- [ ] Login kasir mendapat token
- [ ] Get profile dengan token
- [ ] Logout

### Products ✅

- [ ] Get all products
- [ ] Get low stock products
- [ ] Get product details
- [ ] Create product
- [ ] Update product
- [ ] Delete product

### Categories ✅

- [ ] Get all categories
- [ ] Get category with products
- [ ] Create category
- [ ] Update category
- [ ] Delete category

### Customers ✅

- [ ] Get all customers
- [ ] Get debtors
- [ ] Get customer details
- [ ] Create customer
- [ ] Update customer

### Sales Transactions ✅

- [ ] Get all transactions
- [ ] Get today's sales report
- [ ] Get transaction details
- [ ] Create transaction (cash)
- [ ] Create transaction (debt)
- [ ] Verify stock decreased
- [ ] Verify receivable created (debt)

### Payments ✅

- [ ] Get receivables
- [ ] Get payment history
- [ ] Record payment
- [ ] Verify debt decreased
- [ ] Verify payment history recorded

### Recommendations ✅

- [ ] Get recommendations
- [ ] Create recommendation
- [ ] Update recommendation
- [ ] Delete recommendation

### Dashboard ✅

- [ ] Admin dashboard
- [ ] Kasir dashboard

### Authorization ✅

- [ ] Kasir blocked dari admin endpoint
- [ ] Request tanpa token rejected
- [ ] Invalid token rejected

### Validation ✅

- [ ] Required field validation
- [ ] Unique field validation
- [ ] Numeric validation

---

## 5. Common Response Codes

| Code | Meaning          | Example                  |
| ---- | ---------------- | ------------------------ |
| 200  | OK               | Successful GET/PUT       |
| 201  | Created          | Successful POST          |
| 400  | Bad Request      | Malformed request        |
| 401  | Unauthorized     | Invalid/missing token    |
| 403  | Forbidden        | Insufficient permissions |
| 404  | Not Found        | Resource tidak ada       |
| 422  | Validation Error | Invalid input data       |
| 500  | Server Error     | Bug di backend           |

---

## 6. Tips Testing

1. **Set Environment Variables:**
    - Jangan hardcode URL & token
    - Gunakan `{{variable}}` untuk reusability

2. **Use Postman Tests:**
    - Klik tab **Tests** setelah request body
    - Auto-save token dari response:

    ```javascript
    var jsonData = pm.response.json();
    pm.environment.set("admin_token", jsonData.token);
    ```

3. **Collections Organization:**
    - Group requests dengan folder
    - Add descriptions untuk setiap request
    - Use pre-request scripts untuk setup data

4. **Keep Track:**
    - Catat response times
    - Monitor status codes
    - Verify data di database

5. **Load Testing (Advanced):**
    - Use Postman Runner untuk bulk requests
    - Monitor performance

---

## 7. Troubleshooting

**Error: 404 Not Found**

- Pastikan route path benar
- Server running di correct port
- Check base_url di environment

**Error: 401 Unauthorized**

- Token expired/invalid
- Re-login dan update token
- Check Authorization header format

**Error: 422 Validation Error**

- Check required fields
- Verify data types
- See error message details

**Error: 500 Server Error**

- Check server logs: `php artisan serve`
- Review database connectivity
- Check model relationships

---

## Next: Flutter Integration

Setelah sukses test semua endpoints, Anda siap:

- Integrate dengan Flutter app
- Use sama request format
- Manage tokens di Flutter secara lokal
