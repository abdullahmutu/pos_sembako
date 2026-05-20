<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\CustomerReceivable;
use Illuminate\Http\Request;

class AdminDebtBookController extends Controller
{
    public function index(Request $request)
    {
        $status = $request->input('status', 'all');

        $query = CustomerReceivable::with(['customer', 'salesTransaction'])
            ->where('remaining', '>', 0); // hanya utang aktif

        if ($status !== 'all') {
            $query->where('status', $status);
        }

        $receivables = $query->latest()->paginate(10);

        // Summary untuk stat card
        $summary = [
            'total'   => CustomerReceivable::sum('amount'),
            'unpaid'  => CustomerReceivable::where('status', 'unpaid')->sum('remaining'),
            'partial' => CustomerReceivable::where('status', 'partial')->sum('remaining'),
        ];

        return view('admin.debt_book.index', compact('receivables', 'summary', 'status'));
    }

    public function show(Customer $customer)
    {
        // nanti diisi
    }
}