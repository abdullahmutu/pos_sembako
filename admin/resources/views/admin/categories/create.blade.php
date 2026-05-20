<x-layouts.layout title="Tambah Kategori" pageTitle="Kategori">

    <!-- Header -->
    <div class="flex items-center gap-3 mb-6">
        <a href="{{ route('categories.index') }}"
           class="w-8 h-8 sm:w-9 sm:h-9 flex items-center justify-center rounded-xl bg-white border border-gray-200 text-gray-500 hover:bg-gray-50 transition shadow-sm shrink-0">
            <i class="bi bi-arrow-left text-sm"></i>
        </a>
        <div>
            <h1 class="text-base sm:text-lg font-bold text-gray-900">Tambah Kategori</h1>
            <p class="text-xs text-gray-400 mt-0.5">Isi detail kategori baru</p>
        </div>
    </div>

    <div class="w-full max-w-lg">
        <div class="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">

            <!-- Card Header -->
            <div class="px-4 sm:px-6 py-4 border-b border-gray-100 flex items-center gap-2.5">
                <div class="w-8 h-8 bg-emerald-50 rounded-lg flex items-center justify-center shrink-0">
                    <i class="bi bi-tags text-emerald-600 text-sm"></i>
                </div>
                <h2 class="text-sm font-bold text-gray-800">Informasi Kategori</h2>
            </div>

            <form action="{{ route('categories.store') }}" method="POST" class="p-4 sm:p-6 space-y-4 sm:space-y-5">
                @csrf

                <x-form-input
                    label="Nama Kategori"
                    name="name"
                    placeholder="cth: Minuman, Makanan..."
                    :required="true"
                />

                <x-form-textarea
                    label="Deskripsi"
                    name="description"
                    placeholder="Deskripsi singkat kategori..."
                    :optional="true"
                />

                <div class="flex flex-col sm:flex-row items-stretch sm:items-center gap-2 sm:gap-3 pt-2 border-t border-gray-100">
                    <x-button type="submit" icon="bi-check-circle" label="Simpan Kategori" variant="primary" class="justify-center" />
                    <x-button :href="route('categories.index')" icon="bi-x-circle" label="Batal" variant="secondary" class="justify-center" />
                </div>
            </form>

        </div>
    </div>

</x-layouts.layout>