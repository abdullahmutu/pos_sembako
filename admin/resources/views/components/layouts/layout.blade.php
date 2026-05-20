@props(['title' => 'TokoPos Admin', 'pageTitle' => '', 'hideSidebar' => false])
<!DOCTYPE html>
<html lang="id" class="h-full">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ $title ?? 'TokoPos Admin' }}</title>

    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">

    <style>
        html, body {
            height: 100%;
            margin: 0;
            padding: 0;
            overflow: hidden;
        }
        body {
            font-family: 'Plus Jakarta Sans', sans-serif;
            background-color: #f3f4f6;
            padding-top: 3.5rem;            /* tinggi navbar */
            padding-left: 224px;           /* lebar sidebar */
            transition: padding-left 0.3s ease;
        }
        body.sidebar-closed {
            padding-left: 0;
        }

        #sidebar {
            position: fixed;
            top: 0;
            left: 0;
            height: 100%;
            width: 224px;
            background: white;
            border-right: 1px solid #e5e7eb;
            z-index: 50;
            transform: translateX(0);
            transition: transform 0.3s ease;
        }
        body.sidebar-closed #sidebar {
            transform: translateX(-100%);
        }

        #navbar {
            position: fixed;
            top: 0;
            left: 224px;
            right: 0;
            height: 3.5rem;
            background: white;
            border-bottom: 1px solid #e5e7eb;
            z-index: 30;
            transition: left 0.3s ease;
        }
        body.sidebar-closed #navbar {
            left: 0;
        }

        /* Mobile: sidebar jadi overlay, navbar full width */
        @media (max-width: 1023px) {
            body {
                padding-left: 0 !important;
            }
            body #navbar {
                left: 0 !important;
            }
            body.sidebar-closed #sidebar {
                transform: translateX(-100%);
            }
            body:not(.sidebar-closed) #sidebar {
                transform: translateX(0);
            }
            #sidebarOverlay {
                z-index: 40;
            }
        }
    </style>

    {{ $styles ?? '' }}
</head>

<body class="bg-gray-100 {{ $hideSidebar ? '!p-0 bg-gradient-to-br from-indigo-600 to-indigo-500' : '' }}">

    @unless($hideSidebar)
        <!-- Sidebar -->
        @include('partials.sidebar')

        <!-- Navbar -->
        <nav id="navbar" class="px-4 sm:px-6 flex items-center justify-between">
            <div class="flex items-center gap-3">
                <button onclick="toggleSidebar()"
                        class="w-9 h-9 flex items-center justify-center rounded-lg hover:bg-gray-100 text-gray-500 transition">
                    <i class="bi bi-list text-xl"></i>
                </button>
                <h2 class="text-gray-900 font-bold text-base">{{ $pageTitle ?? 'Dashboard' }}</h2>
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
    @endunless

    <!-- Konten utama yang bisa di‑scroll -->
    <main class="{{ $hideSidebar ? 'flex items-center justify-center min-h-screen p-4' : 'h-full overflow-y-auto p-3 sm:p-6' }}">
        {{ $slot }}
    </main>

    <!-- Overlay mobile -->
    <div id="sidebarOverlay" class="fixed inset-0 bg-black/40 hidden" onclick="closeSidebar()"></div>

    {{ $scripts ?? '' }}
    @stack('scripts')

    <script>
        const sidebar = document.getElementById('sidebar');
        const overlay = document.getElementById('sidebarOverlay');
        const isMobile = () => window.innerWidth < 1024;

        function openSidebar() {
            document.body.classList.remove('sidebar-closed');
            if (isMobile()) {
                overlay.classList.remove('hidden');
                document.body.style.overflow = 'hidden';
            }
            localStorage.setItem('sidebarOpen', 'true');
        }

        function closeSidebar() {
            document.body.classList.add('sidebar-closed');
            overlay.classList.add('hidden');
            document.body.style.overflow = '';
            localStorage.setItem('sidebarOpen', 'false');
        }

        function toggleSidebar() {
            if (document.body.classList.contains('sidebar-closed')) {
                openSidebar();
            } else {
                closeSidebar();
            }
        }

        // Inisialisasi
        const saved = localStorage.getItem('sidebarOpen');
        if (saved === 'false') {
            closeSidebar();
        } else {
            openSidebar();
        }

        window.addEventListener('resize', function () {
            if (!isMobile()) {
                overlay.classList.add('hidden');
                document.body.style.overflow = '';
            }
        });

        // Global scope
        window.openSidebar = openSidebar;
        window.closeSidebar = closeSidebar;
        window.toggleSidebar = toggleSidebar;
    </script>
</body>
</html>