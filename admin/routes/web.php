<?php

use App\Http\Controllers\Admin\AdminAuthController;
use App\Http\Controllers\Admin\AdminDashboardController;
use App\Http\Controllers\Admin\AdminDebtBookController;
use App\Http\Controllers\Admin\AdminExpenditureController;
use App\Http\Controllers\Admin\AdminProductController;
use App\Http\Controllers\Admin\AdminCategoryController;
use App\Http\Controllers\Admin\AdminCustomerController;
use App\Http\Controllers\Admin\AdminReceivableController;
use App\Http\Controllers\Admin\AdminReportController;
use App\Http\Controllers\Admin\AdminRecommendationController;
use App\Http\Controllers\Admin\AdminStoreSettingController;
use Illuminate\Support\Facades\Route;

// Public routes
Route::middleware('guest:web')->group(function () {
    Route::get('/login', [AdminAuthController::class, 'showLogin'])->name('login');
    Route::post('/login', [AdminAuthController::class, 'login'])->name('login.post');
});

// Protected routes
Route::middleware(['auth:web', 'admin'])->prefix('admin')->group(function () {
    Route::get('/dashboard', [AdminDashboardController::class, 'index'])->name('dashboard');

    // products
    Route::resource('products', AdminProductController::class);

    // categories
    Route::resource('categories', AdminCategoryController::class);
    Route::post('categories/quick-store', [AdminCategoryController::class, 'quickStore'])
        ->name('categories.quick-store');

    Route::resource('expenditures', AdminExpenditureController::class)->except(['show']);

    // Buku utang
    Route::prefix('debt-book')->name('debt-book.')->group(function () {
        Route::get('/', [AdminDebtBookController::class, 'index'])->name('index');
        Route::get('/{customer}', [AdminDebtBookController::class, 'show'])->name('show');
    });

    // customers
    Route::resource('customers', AdminCustomerController::class);
    Route::get('customers/{customer}/receivables', [AdminCustomerController::class, 'receivables'])
        ->name('customers.receivables');

    // recommendations
    Route::get('/recommendations', [AdminRecommendationController::class, 'index'])
    ->name('recommendations.index');

    // reports
    Route::get('/reports/sales', [AdminReportController::class, 'sales'])->name('reports.sales');
    Route::get('/reports/products', [AdminReportController::class, 'products'])->name('reports.products');
    Route::get('/reports/receivables', [AdminReportController::class, 'receivables'])->name('reports.receivables');

    Route::get('/profile', [AdminStoreSettingController::class, 'edit'])->name('profile');
    Route::put('/profile', [AdminStoreSettingController::class, 'update'])->name('profile.update');

    Route::post('/logout', [AdminAuthController::class, 'logout'])->name('logout');
});

Route::get('/', function () {
    if (auth('web')->check()) {
        return redirect('/admin/dashboard');
    }
    return redirect('/login');
});