import '../core/api/api_service.dart';
import '../models/customer_model.dart';

class CustomerService {
  static Future<List<CustomerModel>> getCustomers({String search = ''}) async {
    final response = await ApiService.get('customers?search=$search');
    final List data = response is List ? response : (response['data'] ?? []);
    return data.map((e) => CustomerModel.fromJson(e)).toList();
  }
}