<x-layouts.layout title="Edit Kategori" pageTitle="Kategori">

    <!-- Header -->
    <div class="flex items-center gap-3 mb-6">
        <a href="{{ route('categories.index') }}"
           class="w-8 h-8 sm:w-9 sm:h-9 flex items-center justify-center rounded-xl bg-white border border-gray-200 text-gray-500 hover:bg-gray-50 transition shadow-sm shrink-0">
            <i class="bi bi-arrow-left text-sm"></i>
        </a>
        <div>
            <h1 class="text-base sm:text-lg font-bold text-gray-900">Edit Kategori</h1>
            <p class="text-xs text-gray-400 mt-0.5">Perbarui informasi kategori</p>
        </div>
    </div>

    <div class="w-full max-w-lg">
        <div class="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">

            <!-- Card Header -->
            <div class="px-4 sm:px-6 py-4 border-b border-gray-100 flex items-center gap-2.5">
                <div class="w-8 h-8 bg-amber-50 rounded-lg flex items-center justify-center shrink-0">
                    <i class="bi bi-pencil-square text-amber-600 text-sm"></i>
                </div>
                <h2 class="text-sm font-bold text-gray-800 truncate">{{ $category->name }}</h2>
            </div>

            <form action="{{ route('categories.update', $category) }}" method="POST" class="p-4 sm:p-6 space-y-4 sm:space-y-5">
                @csrf
                @method('PUT')

                <x-form-input
                    label="Nama Kategori"
                    name="name"
                    :value="$category->name"
                    :required="true"
                />

                <x-form-textarea
                    label="Deskripsi"
                    name="description"
                    :value="$category->description"
                    :optional="true"
                />

                {{-- Toggle Aktif --}}
                <div class="flex items-center justify-between p-3 sm:p-3.5 bg-gray-50 rounded-xl border border-gray-200">
                    <div class="pr-4">
                        <p class="text-sm font-semibold text-gray-700">Status Kategori</p>
                        <p class="text-xs text-gray-400 mt-0.5">Kategori non-aktif tidak muncul di kasir</p>
                    </div>
                    <label class="relative inline-flex items-center cursor-pointer shrink-0">
                        <input type="hidden" name="is_active" value="0">
                        <input type="checkbox" name="is_active" value="1" class="sr-only peer"
                               @checked(old('is_active', $category->is_active))>
                        <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-emerald-500 rounded-full peer
                            peer-checked:after:translate-x-full peer-checked:after:border-white
                            after:content-[''] after:absolute after:top-[2px] after:left-[2px]
                            after:bg-white after:border-gray-300 after:border after:rounded-full
                            after:h-5 after:w-5 after:transition-all peer-checked:bg-emerald-600"></div>
                    </label>
                </div>

                <div class="flex flex-col sm:flex-row items-stretch sm:items-center gap-2 sm:gap-3 pt-2 border-t border-gray-100">
                    <x-button type="submit" icon="bi-check-circle" label="Simpan Perubahan" variant="primary" class="justify-center" />
                    <x-button :href="route('categories.index')" icon="bi-x-circle" label="Batal" variant="secondary" class="justify-center" />
                </div>

            </form>
        </div>
    </div>

</x-layouts.layout>