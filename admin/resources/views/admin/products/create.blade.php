<x-layouts.layout title="Produk" pageTitle="Produk">

    <!-- Header -->
    <div class="flex items-center gap-3 mb-6">
        <a href="{{ route('products.index') }}"
           class="w-9 h-9 flex items-center justify-center rounded-xl bg-white border border-gray-200 text-gray-500 hover:bg-gray-50 transition shadow-sm shrink-0">
            <i class="bi bi-arrow-left text-sm"></i>
        </a>
        <div>
            <h1 class="text-lg font-bold text-gray-900">Tambah Produk</h1>
            <p class="text-xs text-gray-400 mt-0.5 hidden sm:block">Isi detail produk baru</p>
        </div>
    </div>

    <div class="w-full max-w-2xl">
        <div class="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">

            <div class="px-4 sm:px-6 py-4 border-b border-gray-100 flex items-center gap-2.5">
                <div class="w-8 h-8 bg-emerald-50 rounded-lg flex items-center justify-center shrink-0">
                    <i class="bi bi-box-seam text-emerald-600 text-sm"></i>
                </div>
                <h2 class="text-sm font-bold text-gray-800">Informasi Produk</h2>
            </div>

            <form action="{{ route('products.store') }}" method="POST" class="p-4 sm:p-6 space-y-5">
                @csrf

                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <x-form-input
                        label="SKU"
                        name="sku"
                        placeholder="Otomatis terisi..."
                        :required="true"
                        :readonly="true"
                    />

                    <x-form-input
                        label="Nama Produk"
                        name="name"
                        placeholder="Nama produk"
                        :required="true"
                    />
                </div>

                <div>
                    <div class="flex gap-2 items-end">
                        <div class="flex-1">
                            <x-form-select
                                name="category_id"
                                label="Kategori"
                                :options="$categories->toArray()"
                                placeholder="-- Pilih Kategori --"
                                :required="true"
                            />
                        </div>
                        <button type="button"
                                onclick="bukaModal()"
                                class="mb-0.5 w-10 h-10 flex items-center justify-center rounded-xl bg-emerald-50 text-emerald-600 hover:bg-emerald-100 transition shrink-0"
                                title="Tambah Kategori Baru">
                            <i class="bi bi-plus-lg"></i>
                        </button>
                    </div>
                </div>

                <x-form-textarea
                    label="Deskripsi"
                    name="description"
                    placeholder="Deskripsi singkat produk..."
                    :optional="true"
                />

                <x-form-section title="Harga">
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                        <x-form-input label="Harga Beli" name="purchase_price" type="number" placeholder="0" prefix="Rp" :required="true" />
                        <x-form-input label="Harga Jual" name="selling_price" type="number" placeholder="0" prefix="Rp" :required="true" />
                    </div>
                </x-form-section>

                <x-form-section title="Stok & Satuan">
                    <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
                        <x-form-input label="Stok Awal" name="stock" type="number" value="0" :required="true" />
                        <x-form-input label="Min. Stok" name="min_stock" type="number" value="5" />
                        <x-form-input label="Satuan" name="unit" value="pcs" placeholder="pcs, kg, liter..." :required="true" />
                    </div>
                </x-form-section>

                <div class="flex flex-wrap items-center gap-3 pt-2 border-t border-gray-100">
                    <x-button type="submit" icon="bi-check-circle" label="Simpan Produk" variant="primary" />
                    <x-button :href="route('products.index')" icon="bi-x-circle" label="Batal" variant="secondary" />
                </div>

            </form>
        </div>
    </div>

    <!-- Modal Tambah Kategori -->
    <div id="modal-kategori"
         class="hidden fixed inset-0 z-50 items-center justify-center bg-black/40 backdrop-blur-sm p-4">
        <div class="bg-white rounded-2xl shadow-xl w-full max-w-sm overflow-hidden">
            <div class="px-6 py-4 border-b border-gray-100 flex items-center justify-between">
                <div class="flex items-center gap-2.5">
                    <div class="w-8 h-8 bg-emerald-50 rounded-lg flex items-center justify-center">
                        <i class="bi bi-tag text-emerald-600 text-sm"></i>
                    </div>
                    <h3 class="text-sm font-bold text-gray-800">Tambah Kategori</h3>
                </div>
                <button onclick="tutupModal()"
                        class="w-7 h-7 flex items-center justify-center rounded-lg hover:bg-gray-100 text-gray-400 transition">
                    <i class="bi bi-x-lg text-sm"></i>
                </button>
            </div>
            <form id="form-kategori" class="p-6 space-y-4">
                @csrf
                <x-form-input
                    label="Nama Kategori"
                    name="category_name"
                    placeholder="cth: Minuman, Makanan..."
                    :required="true"
                />
                <div class="flex gap-3 pt-1">
                    <x-button type="submit" icon="bi-check-circle" label="Simpan" variant="primary" class="flex-1 justify-center" />
                    <x-button type="button" icon="bi-x-circle" label="Batal" variant="secondary" class="flex-1 justify-center" />
                </div>
            </form>
        </div>
    </div>

    @push('scripts')
    <script>
    function bukaModal() {
        const modal = document.getElementById('modal-kategori');
        modal.classList.remove('hidden');
        modal.classList.add('flex');
    }

    function tutupModal() {
        const modal = document.getElementById('modal-kategori');
        modal.classList.add('hidden');
        modal.classList.remove('flex');
    }

    document.getElementById('modal-kategori').addEventListener('click', function(e) {
        if (e.target === this) tutupModal();
    });

    document.getElementById('form-kategori').addEventListener('submit', async function(e) {
        e.preventDefault();
        const input = this.querySelector('input[name="category_name"]');
        const name = input.value.trim();
        if (!name) return;
        try {
            const response = await fetch('{{ route('categories.quick-store') }}', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': '{{ csrf_token() }}',
                },
                body: JSON.stringify({ name }),
            });
            const data = await response.json();
            if (data.success) {
                const select = document.getElementById('category_id');
                const option = new Option(data.category.name, data.category.id, true, true);
                select.add(option);
                input.value = '';
                tutupModal();
            }
        } catch (error) {
            console.error('Gagal:', error);
        }
    });

    // SKU Otomatis
    function bukaModal() {
    const modal = document.getElementById('modal-kategori');
    modal.classList.remove('hidden');
    modal.classList.add('flex');
}

function tutupModal() {
    const modal = document.getElementById('modal-kategori');
    modal.classList.add('hidden');
    modal.classList.remove('flex');
}

document.getElementById('modal-kategori').addEventListener('click', function(e) {
    if (e.target === this) tutupModal();
});

document.getElementById('form-kategori').addEventListener('submit', async function(e) {
    e.preventDefault();
    const input = this.querySelector('input[name="category_name"]');
    const name = input.value.trim();
    if (!name) return;
    try {
        const response = await fetch('{{ route('categories.quick-store') }}', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-TOKEN': '{{ csrf_token() }}',
            },
            body: JSON.stringify({ name }),
        });
        const data = await response.json();
        if (data.success) {
            const select = document.getElementById('category_id');
            const option = new Option(data.category.name, data.category.id, true, true);
            select.add(option);
            input.value = '';
            tutupModal();
        }
    } catch (error) {
        console.error('Gagal:', error);
    }
});

// ← Generate SKU hanya saat tombol diklik
function generateSKU() {
    const categorySelect = document.getElementById('category_id');
    const nameInput      = document.getElementById('name');
    const skuInput       = document.getElementById('sku');

    const categoryText = categorySelect.options[categorySelect.selectedIndex]?.text ?? '';
    const nameText     = nameInput.value ?? '';

    // Hanya generate kalau keduanya sudah terisi
    if (!categoryText || categoryText === '-- Pilih Kategori --' || !nameText.trim()) {
        skuInput.value = '';
        return;
    }

    const catCode   = categoryText.replace(/[^a-zA-Z]/g, '').substring(0, 3).toUpperCase();
    const nameCode  = nameText.replace(/[^a-zA-Z]/g, '').substring(0, 3).toUpperCase();
    const randomNum = Math.floor(100 + Math.random() * 900);

    skuInput.value = `${catCode}-${nameCode}-${randomNum}`;
}

// Trigger otomatis saat kategori atau nama berubah
document.getElementById('category_id').addEventListener('change', generateSKU);
document.getElementById('name').addEventListener('input', generateSKU);
    </script>
    @endpush

</x-layouts.layout>