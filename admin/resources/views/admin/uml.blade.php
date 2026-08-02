<x-layouts.layout title="UML Diagram" pageTitle="UML Diagram">
    <div class="w-full">
        <div class="mb-6">
            <h2 class="text-xl font-semibold text-gray-900">Buat UML di Web Sendiri</h2>
            <p class="text-sm text-gray-500 mt-2">Tulis sintaks Mermaid di kiri, lalu lihat diagram UML muncul secara langsung di kanan.</p>
        </div>

        <div class="grid gap-6 lg:grid-cols-[minmax(0,1fr)_minmax(320px,420px)]">
            <div class="space-y-4">
                <label for="umlInput" class="block text-sm font-medium text-gray-700">Kode UML (Mermaid)</label>
                <textarea id="umlInput" rows="20"
                          class="w-full rounded-3xl border border-gray-200 bg-white p-4 text-sm text-slate-900 shadow-sm focus:border-emerald-500 focus:ring-emerald-100"
                          spellcheck="false">classDiagram
    class Customer {
      +String name
      +String email
      +void placeOrder()
    }
    class Order {
      +int id
      +float total
      +void checkout()
    }
    Customer --> Order
</textarea>
                <div class="rounded-3xl border border-gray-200 bg-white p-4 shadow-sm">
                    <h3 class="text-sm font-semibold text-gray-900">Petunjuk Singkat</h3>
                    <p class="mt-2 text-sm text-gray-500">Anda bisa membuat berbagai diagram UML dengan <strong>Mermaid</strong>, misalnya classDiagram, sequenceDiagram, atau stateDiagram.</p>
                    <div class="mt-4 space-y-3 text-xs text-slate-600">
                        <div><strong>Contoh classDiagram:</strong></div>
                        <pre class="rounded-2xl bg-slate-950/5 p-3 text-[0.85rem] text-slate-700">classDiagram
    class Product {
      +String name
      +float price
    }
    class Category {
      +String title
    }
    Product --> Category</pre>
                    </div>
                </div>
            </div>

            <div class="space-y-4">
                <div class="rounded-3xl border border-gray-200 bg-white p-4 shadow-sm">
                    <div class="flex items-start justify-between gap-4">
                        <div>
                            <h3 class="text-sm font-semibold text-gray-900">Preview Diagram</h3>
                            <p class="text-sm text-gray-500">Perubahan akan di-render otomatis setiap kali Anda mengetik.</p>
                        </div>
                        <button id="resetExample"
                                class="inline-flex items-center gap-2 rounded-full border border-gray-200 bg-white px-3 py-1 text-xs font-semibold text-gray-700 hover:bg-gray-50 transition">Reset contoh</button>
                    </div>
                    <div id="umlPreview" class="mt-4 min-h-[320px] overflow-auto rounded-3xl border border-dashed border-gray-200 bg-slate-50 p-4"></div>
                </div>
                <div class="rounded-3xl border border-gray-200 bg-white p-4 shadow-sm">
                    <h3 class="text-sm font-semibold text-gray-900">Contoh Sintaks Mermaid</h3>
                    <pre class="mt-3 whitespace-pre-wrap rounded-2xl bg-slate-950/5 p-3 text-[0.85rem] leading-6 text-slate-600">sequenceDiagram
    Alice-&gt;&gt;Bob: Hello Bob, how are you?
    Bob--&gt;&gt;Alice: I am good thanks!

classDiagram
    class Product {
      +String name
      +float price
      +int stock
    }
    class Category {
      +String name
    }
    Product --> Category</pre>
                </div>
            </div>
        </div>
    </div>

    @push('scripts')
        <script src="https://cdn.jsdelivr.net/npm/mermaid@9.4.2/dist/mermaid.min.js"></script>
        <script>
            function escapeHtml(text) {
                return text
                    .replace(/&/g, '&amp;')
                    .replace(/</g, '&lt;')
                    .replace(/>/g, '&gt;')
                    .replace(/"/g, '&quot;')
                    .replace(/'/g, '&#039;');
            }

            mermaid.initialize({ startOnLoad: false, theme: 'default' });

            const input = document.getElementById('umlInput');
            const preview = document.getElementById('umlPreview');
            const resetExample = document.getElementById('resetExample');
            const defaultDiagram = input.value.trim();

            function showPreview(html) {
                preview.innerHTML = html;
            }

            function showError(error) {
                const message = escapeHtml(error?.str || error?.message || String(error));
                preview.innerHTML = '<div class="rounded-3xl border border-red-200 bg-red-50 p-4 text-sm text-red-700">Error merender diagram: ' + message + '</div>';
            }

            async function renderUml() {
                const code = input.value.trim();
                if (!code) {
                    showPreview('<div class="text-sm text-gray-500">Tuliskan diagram UML di sisi kiri untuk melihat preview.</div>');
                    return;
                }

                showPreview('<div class="text-sm text-gray-500">Memuat preview...</div>');

                try {
                    const renderResult = mermaid.render('umlDiagram', code);
                    if (renderResult && typeof renderResult.then === 'function') {
                        const svgCode = await renderResult;
                        showPreview(svgCode);
                    } else if (typeof renderResult === 'string') {
                        showPreview(renderResult);
                    } else if (renderResult && renderResult.svg) {
                        showPreview(renderResult.svg);
                    } else {
                        showPreview('<div class="text-sm text-gray-500">Diagram berhasil dibuat.</div>');
                    }
                } catch (error) {
                    showError(error);
                }
            }

            function debounce(fn, delay) {
                let timer;
                return function () {
                    const args = arguments;
                    clearTimeout(timer);
                    timer = setTimeout(() => fn.apply(this, args), delay);
                };
            }

            input.addEventListener('input', debounce(renderUml, 250));
            resetExample.addEventListener('click', () => {
                input.value = defaultDiagram;
                renderUml();
            });

            renderUml();
        </script>
    @endpush
</x-layouts.layout>
