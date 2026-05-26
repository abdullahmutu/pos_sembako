@props(['title' => 'TokoPos Admin', 'pageTitle' => '', 'hideSidebar' => false])
<!DOCTYPE html>
<html lang="id" class="h-full">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ $title ?? 'TokoPos Admin' }}</title>

    @vite(['resources/css/app.css', 'resources/js/app.js'])
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
        @include('partials.nav-bar')
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