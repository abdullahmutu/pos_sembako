<?php

use App\Http\Controllers\API\AuthController;
use App\Http\Controllers\API\CategoryController;
use App\Http\Controllers\API\CustomerController;
use App\Http\Controllers\API\DashboardController;
use App\Http\Controllers\API\PaymentController;
use App\Http\Controllers\API\ProductController;
use App\Http\Controllers\API\RecommendationController;
use App\Http\Controllers\API\SalesTransactionController;
use App\Http\Controllers\API\StoreSettingController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->name('api.')->group(function () {
    // Public routes
    Route::post('/auth/register', [AuthController::class, 'register']);
    Route::post('/auth/login', [AuthController::class, 'login']);

    Route::get('products', [ProductController::class, 'index']);
    // Protected routes
    Route::middleware('auth:sanctum')->group(function () {
        // Auth routes
        Route::post('/auth/logout', [AuthController::class, 'logout']);
        Route::get('/auth/me', [AuthController::class, 'me']);

        // Dashboard
        Route::get('/dashboard/admin', [DashboardController::class, 'adminDashboard'])->middleware('admin');
        Route::get('/dashboard/kasir', [DashboardController::class, 'kasirDashboard'])->middleware('kasir');

        // Categories (Admin only)
        Route::middleware('admin')->group(function () {
            Route::apiResource('categories', CategoryController::class);
        });

        // Products (Admin CRUD, Kasir read-only)
        
        Route::get('products/low-stock', [ProductController::class, 'lowStock']);
        Route::get('products/{product}', [ProductController::class, 'show']);
        Route::middleware('admin')->group(function () {
            Route::post('products', [ProductController::class, 'store']);
            Route::put('products/{product}', [ProductController::class, 'update']);
            Route::delete('products/{product}', [ProductController::class, 'destroy']);
        });

        // Customers
        Route::get('customers', [CustomerController::class, 'index']);
        Route::get('customers/debtors', [CustomerController::class, 'getDebtors']);
        Route::get('customers/{customer}', [CustomerController::class, 'show']);

        Route::middleware('kasir_or_admin')->group(function () {
            Route::post('customers', [CustomerController::class, 'store']); // ✅ kasir & admin bisa
        });

        Route::middleware('admin')->group(function () {
            Route::put('customers/{customer}', [CustomerController::class, 'update']);
            Route::delete('customers/{customer}', [CustomerController::class, 'destroy']);
        });

        // Sales Transactions (Kasir create, Admin read)
        Route::get('sales-transactions', [SalesTransactionController::class, 'index']);
        Route::get('sales-transactions/reports/today', [SalesTransactionController::class, 'todaysSalesReport']);
        Route::get('sales-transactions/{salesTransaction}', [SalesTransactionController::class, 'show']);
        Route::post('sales-transactions', [SalesTransactionController::class, 'store'])->middleware('kasir');

        // Payments
        Route::get('payments/receivables', [PaymentController::class, 'getReceivables']);
        Route::post('payments/record', [PaymentController::class, 'recordPayment']);
        Route::get('payments/history', [PaymentController::class, 'getPaymentHistory']);

        // Product Recommendations (Admin only)
        Route::middleware('admin')->group(function () {
            Route::get('recommendations', [RecommendationController::class, 'index']);
            Route::post('recommendations', [RecommendationController::class, 'store']);
            Route::put('recommendations/{recommendation}', [RecommendationController::class, 'update']);
            Route::delete('recommendations/{recommendation}', [RecommendationController::class, 'destroy']);
        });

        Route::get('store-setting', [StoreSettingController::class, 'show']);
        Route::middleware('admin')->group(function () {
            Route::put('store-setting', [StoreSettingController::class, 'update']);
        });
    });
});
