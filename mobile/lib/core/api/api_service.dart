import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';

import '../config/app_config.dart';

class ApiService {
  // Ambil token dari SharedPreferences
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Header default + token jika tersedia
  static Future<Map<String, String>> _buildHeaders({bool withToken = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (withToken) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // GET
  static Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('${AppConfig.baseUrl}/$endpoint');
    final headers = await _buildHeaders();

    final response = await http.get(url, headers: headers);
    return _handleResponse(response);
  }

  // POST
  static Future<dynamic> post(String endpoint, Map<String, dynamic> data,
      {bool withToken = true}) async {
    // Guard khusus untuk transaksi
    if (endpoint == 'sales-transactions') {
      final items = data['items'] as List?;
      final paymentType = data['payment_type'] as String?;

      if (items == null || items.isEmpty) {
        throw Exception('Tidak bisa checkout dengan keranjang kosong.');
      }
      const allowed = ['cash', 'debt', 'qris', 'transfer'];
      if (paymentType == null || !allowed.contains(paymentType)) {
        throw Exception('Tipe pembayaran "$paymentType" tidak diizinkan.');
      }
    }

    final url = Uri.parse('${AppConfig.baseUrl}/$endpoint');
    final headers = await _buildHeaders(withToken: withToken);

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  // PUT
  static Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('${AppConfig.baseUrl}/$endpoint');
    final headers = await _buildHeaders();

    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  // DELETE
  static Future<dynamic> delete(String endpoint) async {
    final url = Uri.parse('${AppConfig.baseUrl}/$endpoint');
    final headers = await _buildHeaders();

    final response = await http.delete(url, headers: headers);
    return _handleResponse(response);
  }

  // Base URL (untuk keperluan eksternal)
  static String get baseUrl => AppConfig.baseUrl;

  // Helper untuk Multipart Request (POST/PUT)
  static Future<dynamic> _multipartRequest(
    String method,
    String endpoint,
    Map<String, String> fields,
    File? imageFile,
  ) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/$endpoint');
    final request = http.MultipartRequest(method, uri);

    final token = await _getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'application/json';

    request.fields.addAll(fields);

    if (imageFile != null) {
      final ext = imageFile.path.split('.').last.toLowerCase();
      final mimeType = ext == 'png' ? 'png' : 'jpeg';
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType('image', mimeType),
      ));
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _handleResponse(response);
  }

  // POST Multipart (upload gambar baru)
  static Future<dynamic> postMultipart(
    String endpoint,
    Map<String, String> fields,
    File? imageFile,
  ) => _multipartRequest('POST', endpoint, fields, imageFile);

  // PUT Multipart (update dengan gambar baru)
  static Future<dynamic> putMultipart(
    String endpoint,
    Map<String, String> fields,
    File? imageFile,
  ) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/$endpoint');
    final request = http.MultipartRequest('POST', uri); // ← POST, bukan PUT

    final token = await _getToken();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    request.fields['_method'] = 'PUT'; // ← method spoofing Laravel
    request.fields.addAll(fields);

    if (imageFile != null) {
      final ext = imageFile.path.split('.').last.toLowerCase();
      final mimeType = ext == 'png' ? 'png' : 'jpeg';
      request.files.add(await http.MultipartFile.fromPath(
        'image', imageFile.path,
        contentType: MediaType('image', mimeType),
      ));
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _handleResponse(response);
  }
  // Handler response terpusat
  static dynamic _handleResponse(http.Response response) {
    debugPrint('STATUS : ${response.statusCode}');
    debugPrint('URL    : ${response.request?.url}');
    debugPrint('BODY   : ${response.body}');

    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Server error (${response.statusCode})');
    }

    switch (response.statusCode) {
      case 200:
      case 201:
        return body;
      case 401:
        throw Exception('Sesi habis, silakan login ulang');
      case 403:
        throw Exception('Akses ditolak');
      case 404:
        throw Exception('Data tidak ditemukan');
      case 422:
        final errors = body['errors'] as Map?;
        final msg = errors?.values.first?.first ?? body['message'] ?? 'Validasi gagal';
        throw Exception(msg);
      default:
        throw Exception(body['message'] ?? 'Error ${response.statusCode}');
    }
  }
}
