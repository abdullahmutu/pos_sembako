<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\SalesTransaction;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\Request;
use Carbon\CarbonPeriod;

class AdminDashboardController extends Controller
{
    public function index(Request $request)
    {
        $today = now()->toDateString();
        $mode = $request->get('mode', 'weekly');

        // ========================
        // 💰 PENDAPATAN HARI INI
        // ========================
        $todaysSales = SalesTransaction::whereDate('sold_at', $today)
            ->whereIn('status', ['completed', 'paid', 'success'])
            ->sum('total');

        // ========================
        // 💸 PENGELUARAN
        // ========================
        $todaysExpense = 0;
        $monthlyExpense = 0;

        if (\Schema::hasTable('purchases')) {
            $todaysExpense = DB::table('purchases')
                ->whereDate('created_at', $today)
                ->sum('total');

            $monthlyExpense = DB::table('purchases')
                ->whereMonth('created_at', now()->month)
                ->sum('total');
        }

        // ========================
        // 📦 PRODUK
        // ========================
        $totalProducts = Product::count();

        $lowStockProducts = Product::whereColumn('stock', '<=', 'min_stock')
            ->where('is_active', true)
            ->limit(5)
            ->get();

        // ========================
        // 🏆 PRODUK TERLARIS
        // ========================
        $topProducts = DB::table('sale_items')
            ->join('products', 'sale_items.product_id', '=', 'products.id')
            ->select(
                'products.id',
                'products.name',
                DB::raw('SUM(sale_items.quantity) as total_sold'),
                DB::raw('SUM(sale_items.subtotal) as revenue')
            )
            ->groupBy('products.id', 'products.name')
            ->orderByDesc('total_sold')
            ->limit(5)
            ->get();

        // ========================
        // 📊 TREND DATA
        // ========================
        if ($mode === 'monthly') {
            $salesRaw = SalesTransaction::selectRaw('MONTH(sold_at) as month, SUM(total) as total')
                ->whereYear('sold_at', now()->year)
                ->whereIn('status', ['completed', 'paid', 'success'])
                ->groupBy('month')
                ->get()
                ->keyBy('month');

            $chartData = collect();

            for ($m = 1; $m <= 12; $m++) {
                $total = $salesRaw[$m]->total ?? 0;
                $chartData->push([
                    'label' => \Carbon\Carbon::create()->month($m)->translatedFormat('M'),
                    'total' => $total,
                ]);
            }
        } else {
            // Mingguan: 7 hari terakhir termasuk hari ini
            $salesRaw = SalesTransaction::selectRaw('DATE(sold_at) as date, SUM(total) as total')
                ->whereBetween('sold_at', [
                    now()->subDays(6)->startOfDay(),
                    now()->endOfDay()
                ])
                ->whereIn('status', ['completed', 'paid', 'success'])
                ->groupBy('date')
                ->get()
                ->keyBy('date');

            $period = CarbonPeriod::create(now()->subDays(6), now());
            $chartData = collect();

            foreach ($period as $date) {
                $d = $date->format('Y-m-d');
                $chartData->push([
                    'label' => $date->translatedFormat('d M'),
                    'total' => $salesRaw[$d]->total ?? 0,
                ]);
            }
        }

        // ========================
        // 🔥 NORMALISASI DATA UNTUK CHART
        // ========================
        $nonZero = $chartData->filter(fn($x) => $x['total'] > 0);
        $max = $nonZero->max('total') ?? 1;
        $min = $nonZero->min('total') ?? 0;
        $range = ($max - $min) ?: 1;

        // Tentukan index bar tertinggi (untuk highlight)
        $topIndex = $nonZero->isNotEmpty()
            ? $nonZero->keys()->first(fn($i) => $nonZero[$i]['total'] === $max)
            : null;

        $salesChart = $chartData->values()->map(function ($item, $index) use ($min, $range, $topIndex) {
            // Hitung tinggi bar 0–100%
            $percent = $item['total'] > 0
                ? round((($item['total'] - $min) / $range) * 100)
                : 0;

            // Label hanya untuk bar tertinggi
            $display = $item['total'] > 0
                ? 'Rp ' . number_format($item['total'], 0, ',', '.')
                : '';

            return [
                'label'   => $item['label'],
                'value'   => $percent,          // tinggi bar
                'display' => $display,
                'active'  => ($index === $topIndex), // hanya satu bar yang di-highlight
            ];
        });

        // ========================
        // 📈 LABA BERSIH
        // ========================
        $monthlySales = SalesTransaction::whereIn('status', ['completed', 'paid', 'success'])
            ->whereMonth('sold_at', now()->month)
            ->sum('total');

        $netProfit = $monthlySales - $monthlyExpense;

        // ========================
        // 🚀 RETURN
        // ========================
        return view('admin.dashboard', compact(
            'todaysSales',
            'todaysExpense',
            'totalProducts',
            'lowStockProducts',
            'topProducts',
            'salesChart',
            'mode',
            'netProfit'
        ));
    }
}