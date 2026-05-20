@if(!$isHero)
<div class="bg-white rounded-2xl p-4 sm:p-5 border border-gray-100 shadow-sm">
    <div class="flex items-start justify-between mb-3">
        <div class="w-9 h-9 sm:w-10 sm:h-10 bg-{{ $color }}-50 rounded-xl flex items-center justify-center">
            <i class="bi {{ $icon }} text-{{ $color }}-600 text-base sm:text-lg"></i>
        </div>
        @if($percentage)
        <span class="text-xs font-semibold text-{{ $color }}-600 bg-{{ $color }}-50 px-2 py-0.5 rounded-full">
            {{ $percentage }}
        </span>
        @endif
    </div>
    <p class="text-[10px] sm:text-xs text-gray-400 uppercase tracking-wider font-semibold mb-1">
        {{ $title }}
    </p>
    <p class="text-xl sm:text-2xl font-bold text-gray-900 truncate">
        {{ $value }}
    </p>
</div>
@else
<div class="bg-{{ $color }}-600 rounded-2xl p-4 sm:p-5 shadow-sm relative overflow-hidden sm:col-span-2 lg:col-span-1">
    <div class="absolute top-0 right-0 w-32 h-32 bg-{{ $color }}-500 rounded-full -translate-y-10 translate-x-10 opacity-40"></div>
    <div class="relative z-10">
        <div class="flex items-center justify-between mb-3">
            <div class="w-9 h-9 sm:w-10 sm:h-10 bg-white/20 rounded-xl flex items-center justify-center">
                <i class="bi {{ $icon }} text-white text-base sm:text-lg"></i>
            </div>
            <span class="text-xs text-{{ $color }}-100">Bulan Ini</span>
        </div>
        <p class="text-[10px] sm:text-xs text-{{ $color }}-200 uppercase tracking-wider font-semibold mb-1">
            {{ $title }}
        </p>
        <p class="text-2xl sm:text-3xl font-bold text-white truncate">
            {{ $value }}
        </p>
    </div>
</div>
@endif