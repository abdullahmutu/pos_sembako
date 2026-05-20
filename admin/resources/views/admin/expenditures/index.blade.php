<x-layouts.layout title="Pengeluaran" pageTitle="Manajemen Pengeluaran">
    <div class="container mx-auto">
        <div class="flex justify-between items-center mb-4">
            <h1 class="text-2xl font-bold">💰 Pengeluaran Toko</h1>
            <a href="{{ route('expenditures.create') }}" class="bg-emerald-600 text-white px-4 py-2 rounded-lg hover:bg-emerald-700">+ Tambah Pengeluaran</a>
        </div>

        @if($expenditures->count() > 0)
            <div class="bg-white rounded-lg shadow overflow-hidden">
                <table class="min-w-full divide-y divide-gray-200">
                    <thead class="bg-gray-50">
                        <tr>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Deskripsi</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Jumlah</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Tanggal</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Kategori</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Dicatat oleh</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Aksi</th>
                        </tr>
                    </thead>
                    <tbody class="bg-white divide-y divide-gray-200">
                        @foreach($expenditures as $exp)
                        <tr>
                            <td class="px-6 py-4">{{ $exp->description }}</td>
                            <td class="px-6 py-4 font-semibold text-red-600">- Rp {{ number_format($exp->amount, 0, ',', '.') }}</td>
                            <td class="px-6 py-4 whitespace-nowrap">{{ $exp->expense_date }}</td>
                            <td class="px-6 py-4">{{ $exp->category ?? '-' }}</td>
                            <td class="px-6 py-4">{{ $exp->user->name ?? '-' }}</td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <a href="{{ route('expenditures.edit', $exp) }}" class="text-emerald-600 hover:text-emerald-900 mr-2">Edit</a>
                                <form action="{{ route('expenditures.destroy', $exp) }}" method="POST" class="inline">
                                    @csrf @method('DELETE')
                                    <button type="submit" class="text-red-600 hover:text-red-900" onclick="return confirm('Yakin hapus?')">Hapus</button>
                                </form>
                            </td>
                        </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
            <div class="mt-4">
                {{ $expenditures->links() }}
            </div>
        @else
            <div class="bg-white rounded-lg shadow p-6 text-center">
                <p class="text-gray-500">Belum ada pengeluaran.</p>
            </div>
        @endif
    </div>
</x-layouts.layout>