@props([
    'title' => 'Chart',
    'subtitle' => '',
    'data' => [],
    'mode' => 'monthly'
])

<div class="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">

    <!-- Header -->
    <div class="px-4 sm:px-5 pt-4 sm:pt-5 pb-3 sm:pb-4 flex items-center justify-between border-b border-gray-50">
        <div>
            <h3 class="text-sm font-bold text-gray-900">{{ $title }}</h3>
            <p class="text-xs text-gray-400 mt-0.5">{{ $subtitle }}</p>
        </div>

        <!-- BUTTON -->
        <div class="flex gap-1">
            <a href="{{ request()->fullUrlWithQuery(['mode' => 'weekly']) }}"
               class="px-2 sm:px-3 py-1.5 text-xs font-medium rounded-lg transition
               {{ $mode === 'weekly'
                    ? 'bg-emerald-600 text-white'
                    : 'text-gray-500 hover:bg-gray-100' }}">
                Mingguan
            </a>
            <a href="{{ request()->fullUrlWithQuery(['mode' => 'monthly']) }}"
               class="px-2 sm:px-3 py-1.5 text-xs font-medium rounded-lg transition
               {{ $mode === 'monthly'
                    ? 'bg-emerald-600 text-white'
                    : 'text-gray-500 hover:bg-gray-100' }}">
                Bulanan
            </a>
        </div>
    </div>

    <!-- Chart -->
    <div class="p-4 sm:p-5">
        <div class="relative h-36 sm:h-44 px-1 sm:px-2">

            <!-- LINE (polyline) – semua titik diikutkan, termasuk nilai 0 -->
            <svg class="absolute inset-0 w-full h-full" preserveAspectRatio="none">
                @php
                    $points = [];
                    $count = count($data);
                @endphp

                @foreach($data as $i => $item)
                    @php
                        $x = $count > 1 ? ($i / ($count - 1)) * 100 : 0;
                        $y = 100 - ($item['value'] ?? 0);
                        $points[] = "$x,$y";
                    @endphp
                @endforeach

                @if(count($points) > 1)
                    <polyline
                        fill="none"
                        stroke="#059669"
                        stroke-width="2"
                        points="{{ implode(' ', $points) }}"
                    />
                @endif

                {{-- Lingkaran untuk semua titik --}}
                @foreach($data as $i => $item)
                    @php
                        $x = $count > 1 ? ($i / ($count - 1)) * 100 : 0;
                        $y = 100 - ($item['value'] ?? 0);
                    @endphp
                    <circle cx="{{ $x }}%" cy="{{ $y }}%" r="2" fill="#059669" />
                @endforeach
            </svg>

            <!-- BAR -->
            <div class="absolute inset-0 flex items-end gap-1.5 sm:gap-3">
                @foreach($data as $item)
                    <div class="flex-1 flex flex-col items-center gap-1">

                        <div class="w-full rounded-t-lg relative"
                             style="height: {{ $item['value'] }}%; background: {{ $item['active'] ? '#059669' : '#d1fae5' }}">

                            {{-- Label hanya untuk bar yang aktif (tertinggi) --}}
                            @if($item['active'] && !empty($item['display']))
                                <span class="absolute -top-6 left-1/2 -translate-x-1/2 text-[10px] font-bold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded whitespace-nowrap">
                                    {{ $item['display'] }}
                                </span>
                            @endif
                        </div>

                        <span class="text-[10px] text-gray-400">
                            {{ $item['label'] ?? '-' }}
                        </span>
                    </div>
                @endforeach
            </div>

        </div>
    </div>

</div>