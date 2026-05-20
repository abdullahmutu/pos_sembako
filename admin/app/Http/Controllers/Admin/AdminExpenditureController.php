<?php
// app/Http/Controllers/Admin/AdminExpenditureController.php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Expenditure;
use Illuminate\Http\Request;

class AdminExpenditureController extends Controller
{
    public function index()
    {
        $expenditures = Expenditure::with('user')->latest()->paginate(15);
        return view('admin.expenditures.index', compact('expenditures'));
    }

    public function create()
    {
        return view('admin.expenditures.create');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'description' => 'required|string',
            'amount'      => 'required|numeric|min:0',
            'expense_date'=> 'required|date',
            'category'    => 'nullable|string',
        ]);

        $validated['created_by'] = auth()->id();
        Expenditure::create($validated);

        return redirect()->route('expenditures.index')->with('success', 'Pengeluaran berhasil dicatat');
    }

    public function edit(Expenditure $expenditure)
    {
        return view('admin.expenditures.edit', compact('expenditure'));
    }

    public function update(Request $request, Expenditure $expenditure)
    {
        $validated = $request->validate([
            'description' => 'required|string',
            'amount'      => 'required|numeric|min:0',
            'expense_date'=> 'required|date',
            'category'    => 'nullable|string',
        ]);

        $expenditure->update($validated);
        return redirect()->route('expenditures.index')->with('success', 'Pengeluaran diperbarui');
    }

    public function destroy(Expenditure $expenditure)
    {
        $expenditure->delete();
        return redirect()->route('expenditures.index')->with('success', 'Pengeluaran dihapus');
    }
}