<?php

namespace Database\Seeders;

use App\Models\Customer;
use Illuminate\Database\Seeder;

class CustomerSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $customers = [
            [
                'name' => 'Budi Santoso',
                'phone' => '081234567890',
                'address' => 'Jl. Merdeka No. 123, Jakarta',
                'email' => 'budi@example.com',
                'customer_type' => 'regular',
                'total_debt' => 0,
            ],
            [
                'name' => 'Siti Nurhaliza',
                'phone' => '081234567891',
                'address' => 'Jl. Ahmad Yani No. 45, Bandung',
                'email' => 'siti@example.com',
                'customer_type' => 'reseller',
                'total_debt' => 150000,
            ],
            [
                'name' => 'Ahmad Rahman',
                'phone' => '081234567892',
                'address' => 'Jl. Sudirman No. 67, Surabaya',
                'email' => 'ahmad@example.com',
                'customer_type' => 'regular',
                'total_debt' => 75000,
            ],
            [
                'name' => 'Eka Putri',
                'phone' => '081234567893',
                'address' => 'Jl. Diponegoro No. 89, Medan',
                'email' => 'eka@example.com',
                'customer_type' => 'reseller',
                'total_debt' => 250000,
            ],
            [
                'name' => 'Rudi Hermawan',
                'phone' => '081234567894',
                'address' => 'Jl. Gatot Subroto No. 101, Jakarta',
                'email' => 'rudi@example.com',
                'customer_type' => 'regular',
                'total_debt' => 0,
            ],
        ];

        foreach ($customers as $customer) {
            Customer::create($customer);
        }
    }
}
