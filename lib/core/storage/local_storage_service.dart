import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

// [FE - State Management] Service ini menjadi adapter SharedPreferences untuk
// menyimpan mock data FE sebagai JSON agar bertahan setelah aplikasi restart.
class LocalStorageService {
  LocalStorageService._();

  static SharedPreferences? _prefs;

  // [CONFIG - Environment] Init ini wajib dipanggil sebelum repository dibuat
  // agar semua load/save lokal memiliki instance SharedPreferences.
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // [UTIL - Helper Function] Helper ini menyimpan object Map sebagai JSON
  // string sehingga model mock tidak perlu tahu detail SharedPreferences.
  static Future<bool> saveJson(String key, Map<String, dynamic> json) {
    return _prefs!.setString(key, jsonEncode(json));
  }

  // [UTIL - Helper Function] Helper ini membaca JSON object dari storage dan
  // mengembalikan null bila data belum pernah disimpan.
  static Map<String, dynamic>? loadJson(String key) {
    final raw = _prefs?.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      // [ERROR - Exception Handling] JSON rusak dianggap tidak ada data agar
      // repository bisa fallback ke seed mock tanpa crash saat startup.
      return null;
    }
  }

  // [UTIL - Helper Function] Helper ini menyimpan list model sebagai JSON
  // string untuk data seperti daftar kebun dan batch.
  static Future<bool> saveJsonList(
    String key,
    List<Map<String, dynamic>> list,
  ) {
    return _prefs!.setString(key, jsonEncode(list));
  }

  // [UTIL - Helper Function] Helper ini membaca list JSON dan mengubah setiap
  // item menjadi Map agar bisa dipakai factory fromJson model.
  static List<Map<String, dynamic>>? loadJsonList(String key) {
    final raw = _prefs?.getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      // [ERROR - Exception Handling] List JSON lama/korup diabaikan agar
      // aplikasi tetap bisa dibuka dan memakai seed default.
      return null;
    }
  }

  // [UTIL - Helper Function] Helper ini menyimpan nilai string sederhana
  // seperti current user/session id mock.
  static Future<bool> saveString(String key, String value) {
    return _prefs!.setString(key, value);
  }

  // [UTIL - Helper Function] Helper ini membaca string sederhana dari storage
  // dan mengembalikan null bila key belum ada.
  static String? loadString(String key) {
    return _prefs?.getString(key);
  }

  // [UTIL - Helper Function] Helper ini menyimpan angka sederhana seperti
  // batch counter agar kode batch tidak mundur setelah restart.
  static Future<bool> saveInt(String key, int value) {
    return _prefs!.setInt(key, value);
  }

  // [UTIL - Helper Function] Helper ini membaca integer sederhana dari storage
  // dan mengembalikan null bila key belum ada.
  static int? loadInt(String key) {
    return _prefs?.getInt(key);
  }

  // [FE - State Management] Reset ini menghapus local storage mock; gunakan
  // hanya untuk aksi reset penuh, bukan logout biasa antar-role.
  static Future<bool> clear() {
    return _prefs!.clear();
  }
}
