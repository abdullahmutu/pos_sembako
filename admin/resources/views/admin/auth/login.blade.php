<x-layouts.layout title="Login" pageTitle="Login" :hideSidebar="true">

    <div class="w-full max-w-md">
        <!-- Card -->
        <div class="bg-white rounded-2xl shadow-2xl overflow-hidden">
            <!-- Header -->
            <div class="bg-gradient-to-r from-indigo-600 to-indigo-500 p-8 text-center">
                <div class="inline-block p-3 bg-white/20 rounded-full mb-4">
                    <i class="bi bi-shop text-white text-3xl"></i>
                </div>
                <h1 class="text-2xl font-bold text-white mb-1">TokoPos Admin</h1>
                <p class="text-indigo-100">Masuk ke Dashboard</p>
            </div>

            <!-- Body -->
            <div class="p-8">
                <!-- Session Error -->
                @if (session('error'))
                    <div class="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg">
                        <p class="text-red-800 text-sm">{{ session('error') }}</p>
                    </div>
                @endif

                <!-- Form -->
                <form action="{{ route('login.post') }}" method="POST" class="space-y-4">
                    @csrf

                    <!-- Email -->
                    <div>
                        <label for="email" class="block text-sm font-semibold text-gray-700 mb-2">
                            Email
                        </label>
                        <input type="email" id="email" name="email" value="{{ old('email') }}" required autofocus
                            class="w-full px-4 py-3 border-2 border-gray-300 rounded-lg focus:border-indigo-600 focus:outline-none transition @error('email') border-red-500 @enderror"
                            placeholder="admin@toko.local">
                        @error('email')
                            <p class="text-red-600 text-sm mt-2">{{ $message }}</p>
                        @enderror
                    </div>

                    <!-- Password -->
                    <div>
                        <label for="password" class="block text-sm font-semibold text-gray-700 mb-2">
                            Password
                        </label>
                        <input type="password" id="password" name="password" required
                            class="w-full px-4 py-3 border-2 border-gray-300 rounded-lg focus:border-indigo-600 focus:outline-none transition @error('password') border-red-500 @enderror"
                            placeholder="••••••••">
                        @error('password')
                            <p class="text-red-600 text-sm mt-2">{{ $message }}</p>
                        @enderror
                    </div>

                    <!-- Login Button -->
                    <button type="submit" class="w-full bg-gradient-to-r from-indigo-600 to-indigo-500 text-white font-semibold py-3 rounded-lg hover:shadow-lg transition mt-6 flex items-center justify-center gap-2">
                        <i class="bi bi-box-arrow-in-right"></i> Login
                    </button>
                </form>

                <!-- Divider -->
                <div class="relative my-6">
                    <div class="absolute inset-0 flex items-center">
                        <div class="w-full border-t border-gray-300"></div>
                    </div>
                    <div class="relative flex justify-center text-sm">
                        <span class="px-2 bg-white text-gray-500">Demo</span>
                    </div>
                </div>

                <!-- Demo Info -->
                <div class="p-4 bg-blue-50 border border-blue-200 rounded-lg">
                    <p class="text-blue-900 font-semibold text-sm mb-2">Demo Credentials:</p>
                    <div class="space-y-1">
                        <p class="text-blue-800 text-sm"><span class="font-medium">Email:</span> admin@toko.local</p>
                        <p class="text-blue-800 text-sm"><span class="font-medium">Password:</span> password123</p>
                    </div>
                </div>
            </div>
        </div>

        <!-- Footer -->
        <p class="text-center text-white/70 text-sm mt-6">
            © 2026 POS Admin. All rights reserved.
        </p>
    </div>

</x-layouts.layout>