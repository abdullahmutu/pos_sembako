<x-layouts.layout title="Produk" pageTitle="Produk">

    <!-- Header -->
    <div class="flex items-center justify-between mb-6">
        <div>
            <h1 class="text-lg font-bold text-gray-900">Manajemen Produk</h1>
            <p class="text-xs text-gray-400 mt-0.5 hidden sm:block">Kelola semua produk toko Anda</p>
        </div>
        <x-button
            :href="route('products.create')"
            icon="bi-plus-lg"
            label="Tambah Produk"
            variant="primary"
        />
    </div>

    <x-widget::list-card
        :total="$products->total()"
        search-placeholder="Cari produk..."
        empty-text="Belum ada produk"
        empty-icon="bi-box"
        :is-empty="$products->isEmpty()"
    >
        <x-slot:head>
            {{-- Sembunyikan kolom SKU & Kategori di HP --}}
            <th class="hidden sm:table-cell text-left px-3 sm:px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">SKU</th>
            <th class="text-left px-3 sm:px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Produk</th>
            <th class="hidden md:table-cell text-left px-3 sm:px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Kategori</th>
            <th class="hidden sm:table-cell text-left px-3 sm:px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Harga Jual</th>
            <th class="text-left px-3 sm:px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Stok</th>
            <th class="text-right px-3 sm:px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Aksi</th>
        </x-slot:head>

        @foreach ($products as $product)
            <tr class="hover:bg-gray-50/70 transition">
                {{-- SKU: hidden di HP --}}
                <td class="hidden sm:table-cell px-3 sm:px-5 py-3 sm:py-4">
                    <span class="font-mono text-xs font-semibold text-gray-500 bg-gray-100 px-2 py-1 rounded-lg">
                        {{ $product->sku }}
                    </span>
                </td>
                {{-- Nama --}}
                <td class="px-3 sm:px-5 py-3 sm:py-4">
                    <p class="font-semibold text-gray-900 text-sm">{{ $product->name }}</p>
                    {{-- Tampilkan SKU di HP sebagai subtitle --}}
                    <p class="sm:hidden text-[10px] font-mono text-gray-400 mt-0.5">{{ $product->sku }}</p>
                </td>
                {{-- Kategori: hidden di HP --}}
                <td class="hidden md:table-cell px-3 sm:px-5 py-3 sm:py-4">
                    <span class="text-xs font-medium text-gray-600 bg-gray-100 px-2.5 py-1 rounded-full">
                        {{ $product->category->name }}
                    </span>
                </td>
                {{-- Harga: hidden di HP --}}
                <td class="hidden sm:table-cell px-3 sm:px-5 py-3 sm:py-4 font-semibold text-gray-900 text-sm">
                    Rp {{ number_format($product->selling_price, 0, ',', '.') }}
                </td>
                {{-- Stok --}}
                <td class="px-3 sm:px-5 py-3 sm:py-4">
                    @php $isLow = $product->stock <= $product->min_stock; @endphp
                    <span class="text-xs font-semibold px-2 sm:px-2.5 py-1 rounded-full
                        {{ $isLow ? 'bg-red-50 text-red-700' : 'bg-emerald-50 text-emerald-700' }}">
                        {{ $product->stock }} {{ $product->unit }}
                    </span>
                </td>
                {{-- Aksi --}}
                <td class="px-3 sm:px-5 py-3 sm:py-4">
                    <div class="flex items-center justify-end gap-1 sm:gap-2">
                        <x-button
                            :href="route('products.edit', $product)"
                            icon="bi-pencil"
                            label="Edit"
                            variant="icon-warning"
                        />
                        <form action="{{ route('products.destroy', $product) }}" method="POST"
                            onsubmit="return confirm('Hapus produk ini?')">
                            @csrf @method('DELETE')
                            <x-button
                                type="submit"
                                icon="bi-trash"
                                label="Hapus"
                                variant="icon-danger"
                            />
                        </form>
                    </div>
                </td>
            </tr>
        @endforeach

        <x-slot:pagination>
            {{ $products->links() }}
        </x-slot:pagination>

    </x-widget::list-card>

</x-layouts.layout>