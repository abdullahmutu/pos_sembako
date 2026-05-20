<?php

namespace App\Http\Controllers\Admin;


use App\Http\Controllers\Controller;

use App\Models\SalesTransaction;
use App\Models\Product;
use App\Models\CustomerReceivable;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Contracts\View\View;

class AdminReportController extends Controller
{
    public function sales(Request $request)
    {
        $dateFrom = $request->input('date_from', now()->subDays(30)->toDateString());
        $dateTo = $request->input('date_to', now()->toDateString());

        $sales = SalesTransaction::selectRaw('DATE(sold_at) as date, SUM(total) as total, COUNT(*) as count')
                                ->whereDate('sold_at', '>=', $dateFrom)
                                ->whereDate('sold_at', '<=', $dateTo)
                                ->where('status', 'completed')
                                ->groupBy('date')
                                ->orderBy('date')
                                ->get();

        $totalSales = $sales->sum('total');
        $totalTransactions = $sales->sum('count');

        return view('admin.reports.sales', compact(
            'sales',
            'totalSales',
            'totalTransactions',
            'dateFrom',
            'dateTo'
        ));
    }

    public function products(Request $request)
    {
        $dateFrom = $request->input('date_from', now()->subDays(30)->toDateString());
        $dateTo = $request->input('date_to', now()->toDateString());

        $products = DB::table('sale_items')
                    ->join('products', 'sale_items.product_id', '=', 'products.id')
                    ->select('products.id', 'products.name', 'products.sku',
                            DB::raw('SUM(sale_items.quantity) as total_sold'),
                            DB::raw('SUM(sale_items.subtotal) as revenue'))
                    ->whereDate('sale_items.created_at', '>=', $dateFrom)
                    ->whereDate('sale_items.created_at', '<=', $dateTo)
                    ->groupBy('products.id', 'products.name', 'products.sku')
                    ->orderBy('total_sold', 'desc')
                    ->paginate(15);

        return view('admin.reports.products', compact('products', 'dateFrom', 'dateTo'));
    }

    public function receivables(Request $request): View
    {
        $status = $request->input('status', 'all');
    
        $query = CustomerReceivable::with(['customer', 'salesTransaction'])
            ->when($status !== 'all', fn($q) => $q->where('status', $status));
    
        $receivables = $query->latest()->paginate(10);
    
        $summary = [
            'total'   => CustomerReceivable::sum('amount'),
            'unpaid'  => CustomerReceivable::where('status', 'unpaid')->sum('remaining'),
            'partial' => CustomerReceivable::where('status', 'partial')->sum('remaining'),
        ];
    
        return view('admin.reports.receivables', compact('receivables', 'summary', 'status'));
    }
}
