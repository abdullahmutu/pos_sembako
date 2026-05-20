<x-layouts.layout title="Tambah Pengeluaran" pageTitle="Tambah Pengeluaran">
    <div class="container mx-auto max-w-lg">
        <div class="bg-white rounded-lg shadow p-6">
            <h1 class="text-xl font-bold mb-4">Tambah Pengeluaran Baru</h1>
            <form action="{{ route('expenditures.store') }}" method="POST">
                @csrf
                <div class="mb-4">
                    <label class="block text-gray-700 text-sm font-bold mb-2">Deskripsi *</label>
                    <input type="text" name="description" class="w-full border rounded-lg px-3 py-2" required>
                </div>
                <div class="mb-4">
                    <label class="block text-gray-700 text-sm font-bold mb-2">Jumlah (Rp) *</label>
                    <input type="number" name="amount" class="w-full border rounded-lg px-3 py-2" step="100" required>
                </div>
                <div class="mb-4">
                    <label class="block text-gray-700 text-sm font-bold mb-2">Tanggal *</label>
                    <input type="date" name="expense_date" class="w-full border rounded-lg px-3 py-2" value="{{ date('Y-m-d') }}" required>
                </div>
                <div class="mb-4">
                    <label class="block text-gray-700 text-sm font-bold mb-2">Kategori</label>
                    <select name="category" class="w-full border rounded-lg px-3 py-2">
                        <option value="">-- Pilih --</option>
                        <option value="stok">Pembelian Stok</option>
                        <option value="listrik">Listrik</option>
                        <option value="gaji">Gaji Karyawan</option>
                        <option value="sewa">Sewa Tempat</option>
                        <option value="lainnya">Lainnya</option>
                    </select>
                </div>
                <div class="flex justify-end gap-2">
                    <a href="{{ route('expenditures.index') }}" class="bg-gray-500 text-white px-4 py-2 rounded-lg">Batal</a>
                    <button type="submit" class="bg-emerald-600 text-white px-4 py-2 rounded-lg">Simpan</button>
                </div>
            </form>
        </div>
    </div>
</x-layouts.layout>