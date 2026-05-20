@props([
    'total' => 0,
    'searchPlaceholder' => 'Cari data...',
    'emptyIcon' => 'bi-inbox',
    'emptyText' => 'Belum ada data',
    'isEm pty' => false,
])

<div class="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">

    <!-- Top Bar -->
    <div class="px-5 py-4 border-b border-gray-100 flex items-center justify-between gap-4">
        <div class="relative">
            <i class="bi bi-search absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-sm"></i>
            <input type="text" placeholder="{{ $searchPlaceholder }}"
                   class="pl-9 pr-4 py-2 text-sm bg-gray-50 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-transparent w-56">
        </div>
        <div class="flex items-center gap-3">
            {{-- Slot filters opsional (dropdown kategori, status, dll) --}}
            {{ $filters ?? '' }}
            <span class="text-xs text-gray-400 font-medium">{{ $total }} data</span>
        </div>
    </div>

    <!-- Table -->
    <div class="overflow-x-auto">
        <table class="w-full text-sm">
            <thead>
                <tr class="bg-gray-50 border-b border-gray-100">
                    {{ $head }}
                </tr>
            </thead>
            <tbody class="divide-y divide-gray-50">
                @if($isEmpty)
                    <tr>
                        <td colspan="99" class="text-center py-16">
                            <i class="bi {{ $emptyIcon }} text-gray-300 text-4xl block mb-3"></i>
                            <p class="text-gray-400 font-medium">{{ $emptyText }}</p>
                            {{ $emptyAction ?? '' }}
                        </td>
                    </tr>
                @else
                    {{ $slot }}
                @endif
            </tbody>
        </table>
    </div>

    <!-- Pagination -->
    @isset($pagination)
        <div class="px-5 py-4 border-t border-gray-100">
            {{ $pagination }}
        </div>
    @endisset

</div>