<?php

namespace Database\Seeders;

use App\Models\Product;
use Illuminate\Database\Seeder;

class ProductSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $products = [
            // Makanan (kategori 1)
            [
                'sku' => 'MKN001',
                'name' => 'Mie Instant',
                'description' => 'Mie instant rasa ayam',
                'category_id' => 1,
                'purchase_price' => 1500,
                'selling_price' => 2500,
                'stock' => 50,
                'min_stock' => 10,
                'unit' => 'pcs',
            ],
            [
                'sku' => 'MKN002',
                'name' => 'Biscuit Cokelat',
                'description' => 'Biscuit cokelat kemasan 200g',
                'category_id' => 1,
                'purchase_price' => 8000,
                'selling_price' => 12000,
                'stock' => 30,
                'min_stock' => 5,
                'unit' => 'pcs',
            ],
            // Minuman (kategori 2)
            [
                'sku' => 'MNM001',
                'name' => 'Minuman Soda',
                'description' => 'Soda botol 1.5L',
                'category_id' => 2,
                'purchase_price' => 5000,
                'selling_price' => 8000,
                'stock' => 40,
                'min_stock' => 10,
                'unit' => 'botol',
            ],
            [
                'sku' => 'MNM002',
                'name' => 'Air Mineral',
                'description' => 'Air mineral kemasan 600ml',
                'category_id' => 2,
                'purchase_price' => 2000,
                'selling_price' => 3500,
                'stock' => 100,
                'min_stock' => 20,
                'unit' => 'botol',
            ],
            // Peralatan (kategori 3)
            [
                'sku' => 'PRL001',
                'name' => 'Gelas Kaca',
                'description' => 'Gelas kaca set 6 pcs',
                'category_id' => 3,
                'purchase_price' => 25000,
                'selling_price' => 40000,
                'stock' => 15,
                'min_stock' => 3,
                'unit' => 'set',
            ],
            // Elektronik (kategori 4)
            [
                'sku' => 'ELK001',
                'name' => 'Lampu LED',
                'description' => 'Lampu LED 12W',
                'category_id' => 4,
                'purchase_price' => 30000,
                'selling_price' => 50000,
                'stock' => 20,
                'min_stock' => 5,
                'unit' => 'pcs',
            ],
            // Pakaian (kategori 5)
            [
                'sku' => 'PKN001',
                'name' => 'Kaos Polos',
                'description' => 'Kaos polos ukuran M',
                'category_id' => 5,
                'purchase_price' => 20000,
                'selling_price' => 35000,
                'stock' => 50,
                'min_stock' => 10,
                'unit' => 'pcs',
            ],
        ];

        foreach ($products as $product) {
            Product::create($product);
        }
    }
}
