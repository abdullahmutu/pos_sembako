<x-layouts.layout title="Detail Utang" pageTitle="Detail Utang Pelanggan">
    <div class="container mx-auto">
        <div class="flex justify-between items-center mb-4">
            <h1 class="text-2xl font-bold">Detail Utang: {{ $customer->name }}</h1>
            <a href="{{ route('debt-book.index') }}" class="bg-gray-500 text-white px-4 py-2 rounded-lg hover:bg-gray-600">← Kembali</a>
        </div>

        <div class="bg-white rounded-lg shadow p-6 mb-6">
            <h2 class="text-lg font-semibold mb-3">Informasi Pelanggan</h2>
            <p><strong>Nama:</strong> {{ $customer->name }}</p>
            <p><strong>Telepon:</strong> {{ $customer->phone ?? '-' }}</p>
            <p><strong>Alamat:</strong> {{ $customer->address ?? '-' }}</p>
        </div>

        <div class="bg-white rounded-lg shadow overflow-hidden">
            <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                    <tr>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Tanggal</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Jenis</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Nominal</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Sisa Utang</th>
                    </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                    @foreach($receivables as $rec)
                    <tr>
                        <td class="px-6 py-4 whitespace-nowrap">{{ $rec->created_at->format('d/m/Y H:i') }}</td>
                        <td class="px-6 py-4 whitespace-nowrap">Utang Baru</td>
                        <td class="px-6 py-4 whitespace-nowrap">Rp {{ number_format($rec->amount, 0, ',', '.') }}</td>
                        <td class="px-6 py-4 whitespace-nowrap">Rp {{ number_format($rec->remaining, 0, ',', '.') }}</td>
                    </tr>
                    @endforeach
                    @foreach($paymentHistories as $payment)
                    <tr class="bg-gray-50">
                        <td class="px-6 py-4 whitespace-nowrap">{{ $payment->paid_at->format('d/m/Y H:i') }}</td>
                        <td class="px-6 py-4 whitespace-nowrap text-green-600">Pembayaran</td>
                        <td class="px-6 py-4 whitespace-nowrap text-green-600">- Rp {{ number_format($payment->amount, 0, ',', '.') }}</td>
                        <td class="px-6 py-4 whitespace-nowrap"></td>
                    </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    </div>
</x-layouts.layout>