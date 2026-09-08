import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'app_api_config.dart';
import '../storage/local_storage_service.dart';

class BackendApiException implements Exception {
  BackendApiException(
    this.message, {
    this.statusCode,
    this.errors,
  });

  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  @override
  String toString() => message;
}

class BackendApiResponse {
  const BackendApiResponse({
    required this.success,
    required this.message,
    required this.data,
    this.errors,
    required this.statusCode,
  });

  final bool success;
  final String message;
  final dynamic data;
  final Map<String, dynamic>? errors;
  final int statusCode;

  factory BackendApiResponse.fromHttp(http.Response response) {
    dynamic decoded;
    try {
      decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }

    if (decoded is Map<String, dynamic>) {
      final errors = decoded['errors'];
      return BackendApiResponse(
        success: decoded['success'] == true,
        message: (decoded['message'] ?? '').toString(),
        data: decoded['data'],
        errors: errors is Map<String, dynamic>
            ? errors
            : errors is Map
                ? Map<String, dynamic>.from(errors)
                : null,
        statusCode: response.statusCode,
      );
    }

    return BackendApiResponse(
      success: response.statusCode >= 200 && response.statusCode < 300,
      message: response.body,
      data: decoded,
      statusCode: response.statusCode,
    );
  }
}

class BackendApiClient {
  BackendApiClient._();

  static final BackendApiClient instance = BackendApiClient._();

  final http.Client _client = http.Client();

  Map<String, String> _headers({bool authenticated = true}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (!authenticated) return headers;

    final token = LocalStorageService.loadString('auth_token');
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<BackendApiResponse> get(
    String path, {
    bool authenticated = true,
  }) {
    return _request('GET', path, authenticated: authenticated);
  }

  Future<BackendApiResponse> post(
    String path, {
    Object? body,
    bool authenticated = true,
  }) {
    return _request('POST', path, body: body, authenticated: authenticated);
  }

  Future<BackendApiResponse> put(
    String path, {
    Object? body,
    bool authenticated = true,
  }) {
    return _request('PUT', path, body: body, authenticated: authenticated);
  }

  Future<BackendApiResponse> patch(
    String path, {
    Object? body,
    bool authenticated = true,
  }) {
    return _request('PATCH', path, body: body, authenticated: authenticated);
  }

  Future<BackendApiResponse> delete(
    String path, {
    Object? body,
    bool authenticated = true,
  }) {
    return _request('DELETE', path, body: body, authenticated: authenticated);
  }

  Future<BackendApiResponse> _request(
    String method,
    String path, {
    Object? body,
    bool authenticated = true,
  }) async {
    final uri = AppApiConfig.uri(path);
    if (kDebugMode) {
      debugPrint('[API] -> $method ${uri.toString()}');
      if (body != null) {
        debugPrint('[API] -> body: ${jsonEncode(body)}');
      }
    }

    final response = await switch (method) {
      'GET' => _client.get(uri, headers: _headers(authenticated: authenticated)),
      'POST' => _client.post(
          uri,
          headers: _headers(authenticated: authenticated),
          body: body == null ? null : jsonEncode(body),
        ),
      'PUT' => _client.put(
          uri,
          headers: _headers(authenticated: authenticated),
          body: body == null ? null : jsonEncode(body),
        ),
      'PATCH' => _client.patch(
          uri,
          headers: _headers(authenticated: authenticated),
          body: body == null ? null : jsonEncode(body),
        ),
      'DELETE' => _client.delete(
          uri,
          headers: _headers(authenticated: authenticated),
          body: body == null ? null : jsonEncode(body),
        ),
      _ => throw ArgumentError.value(method, 'method', 'Unsupported method'),
    };

    final parsed = BackendApiResponse.fromHttp(response);
    if (kDebugMode) {
      debugPrint('[API] <- ${response.statusCode} ${uri.path}');
      if (response.body.isNotEmpty) {
        final bodyText = response.body.length > 600
            ? '${response.body.substring(0, 600)}...'
            : response.body;
        debugPrint('[API] <- body: $bodyText');
      }
    }
    if (parsed.success) {
      return parsed;
    }

    throw BackendApiException(
      parsed.message.isNotEmpty
          ? parsed.message
          : _fallbackMessage(response.statusCode),
      statusCode: response.statusCode,
      errors: parsed.errors,
    );
  }

  String _fallbackMessage(int statusCode) {
    switch (statusCode) {
      case 401:
        return 'Sesi login tidak valid.';
      case 403:
        return 'Akses ditolak.';
      case 404:
        return 'Data tidak ditemukan.';
      case 422:
        return 'Data tidak valid.';
      default:
        return 'Terjadi kesalahan pada server.';
    }
  }
}

dynamic backendJson(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return value;
}

String backendString(Map<String, dynamic> json, List<String> keys, [String fallback = '']) {
  for (final key in keys) {
    final value = json[key];
    if (value != null) return value.toString();
  }
  return fallback;
}

String? backendNullableString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null) {
      final text = value.toString();
      if (text.isNotEmpty) return text;
    }
  }
  return null;
}

int backendInt(Map<String, dynamic> json, List<String> keys, [int fallback = 0]) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value != null) {
      final parsed = int.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
  }
  return fallback;
}

double backendDouble(
  Map<String, dynamic> json,
  List<String> keys, [
  double fallback = 0,
]) {
  for (final key in keys) {
    final value = json[key];
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value != null) {
      final parsed = double.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
  }
  return fallback;
}

DateTime? backendDateTime(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is DateTime) return value;
    if (value != null) {
      final parsed = DateTime.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
  }
  return null;
}

List<Map<String, dynamic>> backendListOfMaps(
  Map<String, dynamic> json,
  List<String> keys,
) {
  for (final key in keys) {
    final value = json[key];
    if (value is List) {
      return value
          .where((item) => item is Map)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }
  }
  return const [];
}
