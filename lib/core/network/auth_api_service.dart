import 'dart:convert';

import 'package:http/http.dart' as http;

import '../storage/local_storage_service.dart';
import '../../features/collector/data/collector_repository.dart';
import '../../features/consumer/data/consumer_repository.dart';
import '../../features/distributor/data/distributor_repository.dart';
import '../../features/farmer/data/farmer_repository.dart';
import '../../features/umkm/data/umkm_repository.dart';
import '../../features/umkm/models/umkm_profile.dart';
import 'app_api_config.dart';

class AuthApiException implements Exception {
  AuthApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class AuthApiUser {
  const AuthApiUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.role,
    this.username,
    this.isActive,
    this.lastLoginAt,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String role;
  final String? username;
  final bool? isActive;
  final String? lastLoginAt;
  final String? createdAt;
  final String? updatedAt;

  factory AuthApiUser.fromJson(Map<String, dynamic> json) {
    return AuthApiUser(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      username: json['username'] as String?,
      isActive: json['is_active'] is bool ? json['is_active'] as bool : null,
      lastLoginAt: json['last_login_at'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'email': email,
      'username': username,
      'role': role,
      'is_active': isActive,
      'last_login_at': lastLoginAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class AuthApiResult {
  const AuthApiResult({
    required this.success,
    required this.message,
    required this.user,
    required this.token,
    required this.dashboard,
  });

  final bool success;
  final String message;
  final AuthApiUser user;
  final String token;
  final String dashboard;

  factory AuthApiResult.fromResponse(Map<String, dynamic> json) {
    final data = Map<String, dynamic>.from(
      (json['data'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    return AuthApiResult(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      user: AuthApiUser.fromJson(
        Map<String, dynamic>.from(data['user'] as Map? ?? const {}),
      ),
      token: (data['token'] ?? '').toString(),
      dashboard: (data['dashboard'] ?? data['role'] ?? '').toString(),
    );
  }
}

class AuthApiService {
  AuthApiService._();

  static final AuthApiService instance = AuthApiService._();
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';
  static const String _dashboardKey = 'auth_dashboard';

  final http.Client _client = http.Client();

  Map<String, String> get _headers => const {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Future<AuthApiResult> login({
    required String identifier,
    required String password,
    required String role,
  }) {
    return _post(AuthEndpoints.login, <String, dynamic>{
      'identifier': identifier,
      'password': password,
      'role': role,
    });
  }

  Future<AuthApiResult> register({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String role,
  }) {
    return _post(AuthEndpoints.register, <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'role': role,
    });
  }

  Future<AuthApiResult> _post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post(
      AppApiConfig.uri(endpoint),
      headers: _headers,
      body: jsonEncode(body),
    );

    final decoded = _decodeJson(response.body);
    final message =
        _extractMessage(decoded) ??
        _defaultMessageForStatus(response.statusCode);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (decoded is! Map<String, dynamic>) {
        throw AuthApiException(
          'Response backend tidak valid.',
          statusCode: response.statusCode,
        );
      }
      final result = AuthApiResult.fromResponse(decoded);
      await _persistSession(result);
      _syncActiveProfile(result.user);
      return result;
    }

    throw AuthApiException(message, statusCode: response.statusCode);
  }

  Future<void> _persistSession(AuthApiResult result) async {
    await LocalStorageService.saveString(_tokenKey, result.token);
    await LocalStorageService.saveJson(_userKey, result.user.toJson());
    await LocalStorageService.saveString(_dashboardKey, result.dashboard);
  }

  void _syncActiveProfile(AuthApiUser user) {
    final fullName = '${user.firstName} ${user.lastName}'.trim();
    final phone = user.phone.startsWith('0')
        ? user.phone.substring(1)
        : user.phone;

    switch (user.role) {
      case 'petani':
        FarmerRepository.instance.registerFarmer(
          firstName: user.firstName,
          lastName: user.lastName,
          phone: phone,
          email: user.email,
        );
        break;
      case 'pengepul':
        CollectorRepository.instance.registerCollector(
          firstName: user.firstName,
          lastName: user.lastName,
          phone: phone,
          email: user.email,
        );
        break;
      case 'distributor':
        DistributorRepository.instance.registerDistributor(
          firstName: user.firstName,
          lastName: user.lastName,
          phone: phone,
          email: user.email,
        );
        break;
      case 'umkm':
        UmkmRepository.instance.updateProfile(
          UmkmProfile(
            umkmId:
                'umkm-auth-${user.id ?? DateTime.now().millisecondsSinceEpoch}',
            name: fullName.isEmpty ? 'UMKM Durian' : fullName,
            ownerName: fullName.isEmpty ? 'Pemilik UMKM' : fullName,
            contact: user.phone,
            email: user.email,
            location: '',
            about: 'Profil aktif dari backend.',
          ),
        );
        break;
      case 'konsumen':
        ConsumerRepository.instance.registerConsumer(
          firstName: user.firstName,
          lastName: user.lastName,
          phone: phone,
          email: user.email,
        );
        break;
    }
  }

  dynamic _decodeJson(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  String? _extractMessage(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      final message = decoded['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
      final errors = decoded['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final firstValue = errors.values.first;
        if (firstValue is List && firstValue.isNotEmpty) {
          return firstValue.first.toString();
        }
        return firstValue?.toString();
      }
    }
    return null;
  }

  String _defaultMessageForStatus(int statusCode) {
    switch (statusCode) {
      case 401:
        return 'Password salah';
      case 403:
        return 'Role tidak sesuai';
      case 404:
        return 'Akun tidak ditemukan';
      case 422:
        return 'Data tidak valid';
      default:
        return 'Terjadi kesalahan pada server';
    }
  }
}
