<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\View\View;

class AdminRecommendationController extends Controller
{
    public function index(): View
    {
        // Nanti bisa diganti dengan query dari DB / service AI
        $insight = [
            'headline'    => 'Kebutuhan Minyak Goreng diprediksi naik 24% minggu depan.',
            'description' => 'Berdasarkan tren pasar lokal dan pola belanja pelanggan Anda selama 30 hari terakhir.',
            'date'        => now()->translatedFormat('d M Y'),
        ];

        $trends = [
            ['name' => 'Richeese Mie', 'label' => 'Tingkat Minat: Tinggi', 'label_cls' => 'text-emerald-600', 'icon' => 'bi-fire',    'icon_bg' => 'bg-red-50',  'icon_color' => 'text-red-500'],
            ['name' => 'Susu Oat',     'label' => 'Mulai Menanjak',        'label_cls' => 'text-blue-500',   'icon' => 'bi-cup-hot', 'icon_bg' => 'bg-blue-50', 'icon_color' => 'text-blue-400'],
        ];

        $products = [
            [
                'icon'       => 'bi-droplet-fill',
                'icon_bg'    => 'bg-yellow-50',
                'icon_color' => 'text-yellow-500',
                'name'       => 'Minyak Bimoli 2L',
                'badge'      => 'LOW STOCK',
                'badge_cls'  => 'badge-low',
                'stok'       => '12',
                'unit'       => 'pcs',
                'prediksi'   => '2 Hari lagi',
                'pred_cls'   => 'text-gray-700',
                'saran'      => '+48',
                'saran_unit' => 'PCS',
                'saran_note' => 'Sesuai Tren Promo',
                'saran_cls'  => 'restock-up',
            ],
            [
                'icon'       => 'bi-bag-fill',
                'icon_bg'    => 'bg-orange-50',
                'icon_color' => 'text-orange-400',
                'name'       => 'Beras Setra Ramos 5kg',
                'badge'      => 'NORMAL',
                'badge_cls'  => 'badge-normal',
                'stok'       => '5',
                'unit'       => 'karung',
                'prediksi'   => '5 Hari lagi',
                'pred_cls'   => 'text-gray-700',
                'saran'      => '+10',
                'saran_unit' => 'KARUNG',
                'saran_note' => 'Permintaan Stabil',
                'saran_cls'  => 'restock-up',
            ],
            [
                'icon'       => 'bi-egg-fill',
                'icon_bg'    => 'bg-amber-50',
                'icon_color' => 'text-amber-500',
                'name'       => 'Telur Ayam Negeri (kg)',
                'badge'      => 'CRITICAL',
                'badge_cls'  => 'badge-critical',
                'stok'       => '3.5',
                'unit'       => 'kg',
                'prediksi'   => 'Besok Pagi',
                'pred_cls'   => 'text-red-500 font-semibold',
                'saran'      => '+15',
                'saran_unit' => 'KG',
                'saran_note' => 'Perputaran Cepat',
                'saran_cls'  => 'restock-up',
            ],
            [
                'icon'       => 'bi-droplet-half',
                'icon_bg'    => 'bg-sky-50',
                'icon_color' => 'text-sky-400',
                'name'       => 'Sunlight Jeruk Nipis 700ml',
                'badge'      => 'AMAN',
                'badge_cls'  => 'badge-aman',
                'stok'       => '24',
                'unit'       => 'pcs',
                'prediksi'   => '12 Hari lagi',
                'pred_cls'   => 'text-gray-700',
                'saran'      => '+0',
                'saran_unit' => 'PCS',
                'saran_note' => 'Belum Perlu Restock',
                'saran_cls'  => 'restock-zero',
            ],
        ];

        $stats = [
            'efisiensi'    => ['value' => '92%',     'badge' => '+5% MoM',   'badge_cls' => 'text-emerald-600 bg-emerald-50', 'desc' => "Alokasi modal Anda sangat efisien. Tidak banyak barang 'mati'."],
            'potensi_rugi' => ['value' => 'Rp 450k', 'badge' => 'High Risk', 'badge_cls' => 'text-red-600 bg-red-50',         'desc' => 'Estimasi keuntungan yang hilang jika barang kritikal tidak di-restock hari ini.'],
        ];

        return view('admin.recommendations.index', compact(
            'insight', 'trends', 'products', 'stats'
        ));
    }
}