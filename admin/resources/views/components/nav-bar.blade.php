@props(['pageTitle' => 'Dashboard'])

<nav id="navbar"
     class="fixed top-0 left-56 right-0 h-14 bg-white border-b border-gray-200 px-4 sm:px-6 flex items-center justify-between z-30 shadow-sm transition-all duration-300">

    <div class="flex items-center gap-3">
        <button onclick="toggleSidebar()"
                class="w-9 h-9 flex items-center justify-center rounded-lg hover:bg-gray-100 text-gray-500 transition">
            <i class="bi bi-list text-xl"></i>
        </button>

        <h2 class="text-gray-900 font-bold text-base">{{ $pageTitle }}</h2>
    </div>

    <div class="flex items-center gap-2 sm:gap-4">
        <div class="relative hidden md:block">
            <i class="bi bi-search absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-sm"></i>
            <input type="text" placeholder="Cari transaksi..."
                   class="pl-9 pr-4 py-2 text-sm bg-gray-50 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-transparent w-52">
        </div>

        <button class="relative w-9 h-9 flex items-center justify-center rounded-lg hover:bg-gray-100 text-gray-500 transition">
            <i class="bi bi-bell text-base"></i>
            <span class="absolute top-1.5 right-1.5 w-2 h-2 bg-red-500 rounded-full"></span>
        </button>

        <div class="flex items-center gap-2.5 pl-2 sm:pl-3 border-l border-gray-200">
            <div class="text-right hidden sm:block">
                <p class="text-sm font-semibold text-gray-800">{{ auth()->user()->name ?? 'Admin' }}</p>
                <p class="text-xs text-gray-400">Pemilik Toko</p>
            </div>
            <div class="w-9 h-9 bg-emerald-600 rounded-full flex items-center justify-center text-white font-bold text-sm shrink-0">
                {{ strtoupper(substr(auth()->user()->name ?? 'A', 0, 1)) }}
            </div>
        </div>
    </div>
</nav>