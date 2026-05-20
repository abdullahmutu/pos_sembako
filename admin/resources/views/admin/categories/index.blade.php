<x-layouts.layout title="Kategori" pageTitle="Kategori">

    <!-- Header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 mb-6">
        <div>
            <h1 class="text-base sm:text-lg font-bold text-gray-900">Manajemen Kategori</h1>
            <p class="text-xs text-gray-400 mt-0.5">Kelola kategori produk toko Anda</p>
        </div>
        <x-button
            :href="route('categories.create')"
            icon="bi-plus-lg"
            label="Tambah Kategori"
            variant="primary"
        />
    </div>

    <x-widget::list-card
        :total="$categories->total()"
        search-placeholder="Cari kategori..."
        empty-text="Belum ada kategori"
        empty-icon="bi-tags"
        :is-empty="$categories->isEmpty()"
    >
        <x-slot:head>
            <th class="text-left px-3 sm:px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Nama</th>
            <th class="hidden sm:table-cell text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Deskripsi</th>
            <th class="text-left px-3 sm:px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Status</th>
            <th class="text-right px-3 sm:px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Aksi</th>
        </x-slot:head>

        @foreach ($categories as $category)
            <tr class="hover:bg-gray-50/70 transition">
                <td class="px-3 sm:px-5 py-3 sm:py-4">
                    <p class="font-semibold text-gray-900 text-sm">{{ $category->name }}</p>
                    {{-- Deskripsi muncul di bawah nama saat mobile --}}
                    <p class="sm:hidden text-xs text-gray-400 mt-0.5 truncate max-w-[160px]">
                        {{ $category->description ?? '-' }}
                    </p>
                </td>
                <td class="hidden sm:table-cell px-5 py-4 text-sm text-gray-500">
                    {{ $category->description ?? '-' }}
                </td>
                <td class="px-3 sm:px-5 py-3 sm:py-4">
                    <span class="text-xs font-semibold px-2 sm:px-2.5 py-1 rounded-full whitespace-nowrap
                        {{ $category->is_active ? 'bg-emerald-50 text-emerald-700' : 'bg-red-50 text-red-600' }}">
                        {{ $category->is_active ? 'Aktif' : 'Non-Aktif' }}
                    </span>
                </td>
                <td class="px-3 sm:px-5 py-3 sm:py-4">
                    <div class="flex items-center justify-end gap-1.5 sm:gap-2">
                        <x-button
                            :href="route('categories.edit', $category)"
                            icon="bi-pencil"
                            label="Edit"
                            variant="icon-warning"
                        />
                        <form action="{{ route('categories.destroy', $category) }}" method="POST"
                              onsubmit="return confirm('Hapus kategori ini?')">
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
            {{ $categories->links() }}
        </x-slot:pagination>

    </x-widget::list-card>

</x-layouts.layout>