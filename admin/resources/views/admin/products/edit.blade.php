<x-layouts.layout title="Edit Produk" pageTitle="Produk">

    <div class="flex items-center gap-3 mb-6">
        <a href="{{ route('products.index') }}"
           class="w-9 h-9 flex items-center justify-center rounded-xl bg-white border border-gray-200 text-gray-500 hover:bg-gray-50 transition shadow-sm shrink-0">
            <i class="bi bi-arrow-left text-sm"></i>
        </a>
        <div>
            <h1 class="text-lg font-bold text-gray-900">Edit Produk</h1>
            <p class="text-xs text-gray-400 mt-0.5 hidden sm:block">Perbarui informasi produk</p>
        </div>
    </div>

    <div class="w-full max-w-2xl">
        <div class="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">

            <div class="px-4 sm:px-6 py-4 border-b border-gray-100 flex items-center justify-between">
                <div class="flex items-center gap-2.5">
                    <div class="w-8 h-8 bg-amber-50 rounded-lg flex items-center justify-center shrink-0">
                        <i class="bi bi-pencil-square text-amber-600 text-sm"></i>
                    </div>
                    <div>
                        <h2 class="text-sm font-bold text-gray-800">{{ $product->name }}</h2>
                        <p class="text-[10px] font-mono text-gray-400">{{ $product->sku }}</p>
                    </div>
                </div>
                @if ($product->stock <= $product->min_stock)
                    <span class="text-[10px] font-bold text-red-600 bg-red-50 px-2 py-1 rounded-full flex items-center gap-1 shrink-0">
                        <i class="bi bi-exclamation-circle"></i>
                        <span class="hidden sm:inline">Stok Rendah</span>
                    </span>
                @endif
            </div>

            <form action="{{ route('products.update', $product) }}" method="POST" class="p-4 sm:p-6 space-y-5">
                @csrf
                @method('PUT')

                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <x-form-input label="SKU" name="sku" :value="$product->sku" :required="true" />
                    <x-form-input label="Nama Produk" name="name" :value="$product->name" :required="true" />
                </div>

                <x-form-select
                    label="Kategori"
                    name="category_id"
                    :options="$categories->toArray()"
                    placeholder="-- Pilih Kategori --"
                    :required="true"
                    :value="$product->category_id"
                />

                <x-form-textarea
                    label="Deskripsi"
                    name="description"
                    :value="$product->description"
                    :optional="true"
                />

                <x-form-section title="Harga">
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                        <x-form-input label="Harga Beli" name="purchase_price" type="number" :value="$product->purchase_price" prefix="Rp" :required="true" />
                        <x-form-input label="Harga Jual" name="selling_price" type="number" :value="$product->selling_price" prefix="Rp" :required="true" />
                    </div>
                </x-form-section>

                <x-form-section title="Stok & Satuan">
                    <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
                        <x-form-input label="Stok" name="stock" type="number" :value="$product->stock" :required="true" />
                        <x-form-input label="Min. Stok" name="min_stock" type="number" :value="$product->min_stock" />
                        <x-form-input label="Satuan" name="unit" :value="$product->unit" :required="true" />
                    </div>
                </x-form-section>

                <div class="flex flex-wrap items-center gap-3 pt-2 border-t border-gray-100">
                    <x-button type="submit" icon="bi-check-circle" label="Simpan Perubahan" variant="primary" />
                    <x-button :href="route('products.index')" icon="bi-x-circle" label="Batal" variant="secondary" />
                </div>

            </form>
        </div>
    </div>

</x-layouts.layout>