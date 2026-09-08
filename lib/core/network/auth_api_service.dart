import 'dart:async';

import 'package:flutter/foundation.dart';

import 'app_api_config.dart';
import '../storage/local_storage_service.dart';
import 'backend_api_client.dart';
import '../../features/collector/data/collector_repository.dart';
import '../../features/consumer/data/consumer_repository.dart';
import '../../features/distributor/data/distributor_repository.dart';
import '../../features/farmer/data/farmer_repository.dart';
import '../../features/umkm/data/umkm_repository.dart';

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
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
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

  String? get accessToken => LocalStorageService.loadString(_tokenKey);
  String? get dashboard => LocalStorageService.loadString(_dashboardKey);

  AuthApiUser? get activeUser {
    final raw = LocalStorageService.loadJson(_userKey);
    if (raw == null) return null;
    try {
      return AuthApiUser.fromJson(raw);
    } catch (_) {
      return null;
    }
  }

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
    try {
      final response = await BackendApiClient.instance.post(
        endpoint,
        body: body,
        authenticated: false,
      );

      if (response.data is! Map<String, dynamic>) {
        throw AuthApiException(
          'Response backend tidak valid.',
          statusCode: response.statusCode,
        );
      }

      final result = AuthApiResult.fromResponse(
        <String, dynamic>{
          'success': response.success,
          'message': response.message,
          'data': response.data,
        },
      );
      if (kDebugMode) {
        debugPrint(
          '[AUTH] ${endpoint == AuthEndpoints.login ? 'login' : 'register'} '
          'ok for ${result.user.email} | ${result.user.firstName} ${result.user.lastName} '
          '| role=${result.user.role} | dashboard=${result.dashboard}',
        );
      }
      await _persistSession(result);
      _syncActiveProfile(result.user);
      await _refreshRoleData(result.user.role);
      return result;
    } on BackendApiException catch (e) {
      throw AuthApiException(e.message, statusCode: e.statusCode);
    }
  }

  Future<void> _persistSession(AuthApiResult result) async {
    await LocalStorageService.saveString(_tokenKey, result.token);
    await LocalStorageService.saveJson(_userKey, result.user.toJson());
    await LocalStorageService.saveString(_dashboardKey, result.dashboard);
  }

  void _syncActiveProfile(AuthApiUser user) {
    if (kDebugMode) {
      debugPrint(
        '[AUTH] syncing active profile from backend user: '
        '${user.email} (${user.role})',
      );
    }
  }

  Future<AuthApiResult> restoreSession() async {
    final response = await BackendApiClient.instance.get(
      AuthEndpoints.me,
    );
    if (response.data is! Map<String, dynamic>) {
      throw AuthApiException('Response backend tidak valid.');
    }
    final data = response.data as Map<String, dynamic>;
    final result = AuthApiResult(
      success: response.success,
      message: response.message,
      user: AuthApiUser.fromJson(
        Map<String, dynamic>.from(data['user'] as Map? ?? const {}),
      ),
      token: accessToken ?? '',
      dashboard: (data['dashboard'] ?? '').toString(),
    );
    if (kDebugMode) {
      debugPrint(
        '[AUTH] session restored for ${result.user.email} | '
        '${result.user.firstName} ${result.user.lastName} | '
        'role=${result.user.role} | dashboard=${result.dashboard}',
      );
    }
    _syncActiveProfile(result.user);
    await _refreshRoleData(result.user.role);
    return result;
  }

  Future<void> logout() async {
    try {
      await BackendApiClient.instance.post(AuthEndpoints.logout);
    } catch (_) {
      // Logout lokal tetap dibersihkan walau backend sedang offline.
    } finally {
      await LocalStorageService.remove(_tokenKey);
      await LocalStorageService.remove(_dashboardKey);
      await LocalStorageService.remove(_userKey);
    }
  }

  Future<void> _refreshRoleData(String role) async {
    try {
      switch (role) {
        case 'petani':
          await FarmerRepository.instance.refreshFromBackend();
          break;
        case 'pengepul':
          await Future.wait([
            CollectorRepository.instance.refreshFromBackend(),
            FarmerRepository.instance.refreshFromBackend(),
          ]);
          break;
        case 'distributor':
          await Future.wait([
            CollectorRepository.instance.refreshFromBackend(),
            DistributorRepository.instance.refreshFromBackend(),
            FarmerRepository.instance.refreshFromBackend(),
          ]);
          break;
        case 'umkm':
          await Future.wait([
            UmkmRepository.instance.refreshFromBackend(),
            FarmerRepository.instance.refreshFromBackend(),
          ]);
          break;
        case 'konsumen':
          await Future.wait([
            ConsumerRepository.instance.refreshFromBackend(),
            UmkmRepository.instance.refreshFromBackend(),
          ]);
          break;
      }
    } catch (_) {
      // Backend refresh gagal tidak boleh menghalangi login.
    }
  }
}
