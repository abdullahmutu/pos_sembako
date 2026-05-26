import '../../core/api/api_service.dart';

class CartService {
  static List<Map<String, dynamic>> cart = [];

  static void addToCart(dynamic item) {
    final index = cart.indexWhere((e) => e['id'] == item['id']);
    if (index != -1) {
      cart[index]['qty'] += 1;
    } else {
      cart.add({...Map<String, dynamic>.from(item), 'qty': 1});
    }
  }

  static void removeFromCart(int index) {
    cart.removeAt(index);
  }

  static void clearCart() => cart.clear();

  static int get totalHarga {
    return cart.fold(0, (sum, item) {
      final harga = double.parse(item['selling_price'].toString()).toInt();
      return sum + (harga * (item['qty'] as int));
    });
  }

  static Future<Map<String, dynamic>> checkout({
  String paymentType = 'cash',
  int? customerId,
  String? dueDate,      // opsional
  String? notes,        // opsional
}) async {
  if (cart.isEmpty) throw Exception('Keranjang kosong, tidak dapat checkout.');
  const allowed = ['cash', 'debt', 'qris', 'transfer'];
  if (!allowed.contains(paymentType)) {
    throw Exception('Tipe pembayaran tidak valid: $paymentType');
  }

  final items = cart.map((item) => {
    'product_id' : item['id'],
    'quantity'   : item['qty'],
    'unit_price' : item['selling_price'],
  }).toList();

  final response = await ApiService.post('sales-transactions', {
    'customer_id'      : customerId,
    'items'            : items,
    'total_amount'     : totalHarga,
    'payment_type'     : paymentType,
    'due_date'         : dueDate,
    'notes_receivable' : notes,
  });

  cart.clear();
  return Map<String, dynamic>.from(response);
}
}