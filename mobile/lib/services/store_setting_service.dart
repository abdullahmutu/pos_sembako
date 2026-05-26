// lib/services/store_setting_service.dart

import '../core/api/api_service.dart';
import '../models/store_setting_model.dart'; // ← path dari lib/services/

class StoreSettingService {
  static Future<StoreSettingModel> getStoreSetting() async {
    final response = await ApiService.get('store-setting');
    return StoreSettingModel.fromJson(response);
  }
}