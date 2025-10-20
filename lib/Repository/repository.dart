import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:tire_testai/Api_config/api_config.dart';
import 'package:tire_testai/Models/auth_models.dart';

// auth_repository.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart'; // for kDebugMode
import 'package:http/http.dart' as http;
// auth_repository.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart'; // kDebugMode, debugPrint
import 'package:http/http.dart' as http;


// =================== Result & Failure ===================
class Failure {
  final String code;        // network | timeout | server | parse | validation | unknown
  final String message;
  final int? statusCode;
  const Failure({required this.code, required this.message, this.statusCode});

  @override
  String toString() => 'Failure($code, $statusCode): $message';
}

class Result<T> {
  final T? data;
  final Failure? failure;
  const Result._(this.data, this.failure);
  bool get isSuccess => failure == null;

  factory Result.ok(T data) => Result._(data, null);
  factory Result.fail(Failure f) => Result._(null, f);
}

// =================== Contract ===================
abstract class AuthRepository {
  Future<Result<LoginResponse>> login(LoginRequest req);
  Future<Result<SignupResponse>> signup(SignupRequest req);
}

// =================== HTTP Impl with Verbose Logging ===================
class AuthRepositoryHttp implements AuthRepository {
  AuthRepositoryHttp({
    this.timeout = const Duration(seconds: 30),
    this.logHttp = true,
  });

  final Duration timeout;
  final bool logHttp;

  Map<String, String> _headers() => const {
        HttpHeaders.acceptHeader: 'application/json',
        HttpHeaders.contentTypeHeader: 'application/json',
      };

  Failure _serverFail(http.Response res, {String? fallback}) {
    String msg = fallback ?? 'Server error (${res.statusCode})';
    try {
      final parsed = jsonDecode(res.body);
      if (parsed is Map && parsed['message'] != null) {
        msg = parsed['message'].toString();
      }
    } catch (_) {}
    return Failure(code: 'server', message: msg, statusCode: res.statusCode);
  }

  // ---------------- Logging helpers ----------------
  static const _chunk = 900;
  void _dprint(String s) {
    if (!logHttp) return;
    if (!kDebugMode) return; // remove this line to log in release too
    if (s.length <= _chunk) {
      debugPrint(s);
      return;
    }
    final r = RegExp('.{1,$_chunk}', dotAll: true);
    for (final m in r.allMatches(s)) {
      debugPrint(m.group(0));
    }
  }

  String _prettyJson(Object? v) {
    try {
      return const JsonEncoder.withIndent('  ').convert(v);
    } catch (_) {
      return v.toString();
    }
  }

  String _maskedBody(Map<String, dynamic> body) {
    final copy = Map<String, dynamic>.from(body);
    for (final key in ['password', 'confirmPassword', 'token']) {
      if (copy[key] is String) {
        final s = (copy[key] as String);
        copy[key] = s.isEmpty ? '' : '••••••';
      }
    }
    return _prettyJson(copy);
  }

  void _logRequest({
    required String tag,
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  }) {
    _dprint('========== $tag REQUEST ==========');
    _dprint('>>> $method $uri');
    _dprint('>>> HEADERS: ${_prettyJson(headers)}');
    _dprint('>>> BODY: ${_maskedBody(body)}');
  }

  void _logResponse({
    required String tag,
    required http.Response res,
  }) {
    _dprint('---------- $tag RESPONSE ----------');
    _dprint('<<< STATUS: ${res.statusCode}');
    _dprint('<<< HEADERS: ${_prettyJson(res.headers)}');
    try {
      final parsed = jsonDecode(res.body);
      _dprint('<<< BODY(JSON): ${_prettyJson(parsed)}');
    } catch (_) {
      _dprint('<<< BODY(RAW): ${res.body}');
    }
    _dprint('===================================');
  }

  void _logParsed(String tag, Object parsed) {
    _dprint('[$tag] Parsed: ${_prettyJson(parsed)}');
  }

  void _logError(String tag, Object e, [StackTrace? st]) {
    _dprint('[$tag] ERROR: $e');
    if (st != null) _dprint(st.toString());
  }

  // ---------------- Unwrapping helpers ----------------
  /// Some backends wrap responses like:
  /// { "isSuccess": true, "message": "...", "result": { ...actual... } }
  /// This returns the inner map for login.
  Map<String, dynamic> _unwrapLogin(Object? json) {
    if (json is Map<String, dynamic>) {
      if (json['result'] is Map<String, dynamic>) {
        return (json['result'] as Map<String, dynamic>);
      }
      return json;
    }
    return <String, dynamic>{};
  }

  /// For signup we want a SignupResponse(message, data)
  /// Backend may return either:
  /// A) { "message": "...", "data": { userId, email, ... } }
  /// B) { "isSuccess": true, "message": "...", "result": { userId, email, ... } }
  SignupResponse _buildSignupResponse(Map<String, dynamic> raw) {
    final message = raw['message']?.toString();

    Map<String, dynamic>? dataMap;
    if (raw['data'] is Map<String, dynamic>) {
      dataMap = raw['data'] as Map<String, dynamic>;
    } else if (raw['result'] is Map<String, dynamic>) {
      dataMap = raw['result'] as Map<String, dynamic>;
    }

    return SignupResponse(
      message: message,
      data: (dataMap != null) ? SignupData.fromJson(dataMap) : null,
    );
  }

  // =================== API CALLS ===================
  @override
  Future<Result<LoginResponse>> login(LoginRequest req) async {
    const tag = 'LOGIN';
    final uri = Uri.parse(ApiConfig.login);

    try {
      _logRequest(
        tag: tag,
        method: 'POST',
        uri: uri,
        headers: _headers(),
        body: req.toJson(),
      );

      final res = await http
          .post(uri, headers: _headers(), body: jsonEncode(req.toJson()))
          .timeout(timeout);

      _logResponse(tag: tag, res: res);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final raw = jsonDecode(res.body);
        if (raw is! Map<String, dynamic>) {
          _logError(tag, 'Invalid response format (expected JSON object)');
          return Result.fail(
            const Failure(code: 'parse', message: 'Invalid response format'),
          );
        }

        // unwrap if needed and parse to your LoginResponse model
        final core = _unwrapLogin(raw);
        final resp = LoginResponse.fromJson(core);

        // If top-level carried message, prefer it
        final topMsg = raw['message']?.toString();
        final merged = LoginResponse(
          token: resp.token,
          purpose: resp.purpose,
          message: topMsg ?? resp.message,
        );

        _logParsed(tag, {
          'token': merged.token.isNotEmpty ? '<non-empty>' : '',
          'purpose': merged.purpose,
          'message': merged.message,
          'isValid': merged.isValid,
        });

        if (!merged.isValid) {
          final msg = merged.message ?? 'Login failed';
          _logError(tag, 'Validation failed: $msg');
          return Result.fail(
            Failure(code: 'validation', message: msg, statusCode: res.statusCode),
          );
        }

        return Result.ok(merged);
      }

      final f = _serverFail(res);
      _logError(tag, f);
      return Result.fail(f);
    } on SocketException catch (_, st) {
      _logError(tag, 'No internet connection', st);
      return Result.fail(const Failure(code: 'network', message: 'No internet connection'));
    } on TimeoutException catch (_, st) {
      _logError(tag, 'Request timed out', st);
      return Result.fail(const Failure(code: 'timeout', message: 'Request timed out'));
    } catch (e, st) {
      _logError(tag, e, st);
      return Result.fail(Failure(code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<Result<SignupResponse>> signup(SignupRequest req) async {
    const tag = 'SIGNUP';
    final uri = Uri.parse(ApiConfig.signup);

    try {
      _logRequest(
        tag: tag,
        method: 'POST',
        uri: uri,
        headers: _headers(),
        body: req.toJson(),
      );

      final res = await http
          .post(uri, headers: _headers(), body: jsonEncode(req.toJson()))
          .timeout(timeout);

      _logResponse(tag: tag, res: res);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final raw = jsonDecode(res.body);
        if (raw is! Map<String, dynamic>) {
          _logError(tag, 'Invalid response format (expected JSON object)');
          return Result.fail(
            const Failure(code: 'parse', message: 'Invalid response format'),
          );
        }

        final resp = _buildSignupResponse(raw);
        _logParsed(tag, {
          'message': resp.message,
          'data': resp.data == null
              ? null
              : {
                  'userId': resp.data!.userId,
                  'email': resp.data!.email,
                  'purpose': resp.data!.purpose,
                },
          'isValid': resp.isValid,
        });

        if (!resp.isValid) {
          final msg = resp.message ?? 'Signup failed';
          _logError(tag, 'Validation failed: $msg');
          return Result.fail(
            Failure(code: 'validation', message: msg, statusCode: res.statusCode),
          );
        }

        return Result.ok(resp);
      }

      final f = _serverFail(res);
      _logError(tag, f);
      return Result.fail(f);
    } on SocketException catch (_, st) {
      _logError(tag, 'No internet connection', st);
      return Result.fail(const Failure(code: 'network', message: 'No internet connection'));
    } on TimeoutException catch (_, st) {
      _logError(tag, 'Request timed out', st);
      return Result.fail(const Failure(code: 'timeout', message: 'Request timed out'));
    } catch (e, st) {
      _logError(tag, e, st);
      return Result.fail(Failure(code: 'unknown', message: e.toString()));
    }
  }
}



// abstract class AuthRepository {
//   Future<Result<LoginResponse>> login(LoginRequest req);
//   Future<Result<SignupResponse>> signup(SignupRequest req);
// }

// class AuthRepositoryHttp implements AuthRepository {
//   AuthRepositoryHttp({this.timeout = const Duration(seconds: 30)});
//   final Duration timeout;

//   Map<String, String> _headers() => const {
//         HttpHeaders.acceptHeader: 'application/json',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       };

//   Failure _serverFail(http.Response res, {String? fallback}) {
//     String msg = fallback ?? 'Server error (${res.statusCode})';
//     try {
//       final parsed = jsonDecode(res.body);
//       if (parsed is Map && parsed['message'] != null) {
//         msg = parsed['message'].toString();
//       }
//     } catch (_) {}
//     return Failure(code: 'server', message: msg, statusCode: res.statusCode);
//   }

//   @override
//   Future<Result<LoginResponse>> login(LoginRequest req) async {
//     final uri = Uri.parse(ApiConfig.login);
//     try {
//       final res = await http
//           .post(uri, headers: _headers(), body: jsonEncode(req.toJson()))
//           .timeout(timeout);

//       if (res.statusCode >= 200 && res.statusCode < 300) {
//         final parsed = jsonDecode(res.body);
//         if (parsed is! Map<String, dynamic>) {
//           return Result.fail(
//             const Failure(code: 'parse', message: 'Invalid response format'),
//           );
//         }
//         final resp = LoginResponse.fromJson(parsed);
//         if (!resp.isValid) {
//           return Result.fail(Failure(
//               code: 'validation',
//               message: parsed['message']?.toString() ?? 'Login failed',
//               statusCode: res.statusCode));
//         }
//         return Result.ok(resp);
//       }
//       return Result.fail(_serverFail(res));
//     } on SocketException {
//       return  Result.fail(
//           Failure(code: 'network', message: 'No internet connection'));
//     } on TimeoutException {
//       return  Result.fail(
//           Failure(code: 'timeout', message: 'Request timed out'));
//     } catch (e) {
//       return Result.fail(Failure(code: 'unknown', message: e.toString()));
//     }
//   }

//   @override
//   Future<Result<SignupResponse>> signup(SignupRequest req) async {
//     final uri = Uri.parse(ApiConfig.signup);
//     try {
//       final res = await http
//           .post(uri, headers: _headers(), body: jsonEncode(req.toJson()))
//           .timeout(timeout);

//       if (res.statusCode >= 200 && res.statusCode < 300) {
//         final parsed = jsonDecode(res.body);
//         if (parsed is! Map<String, dynamic>) {
//           return Result.fail(
//             const Failure(code: 'parse', message: 'Invalid response format'),
//           );
//         }
//         final resp = SignupResponse.fromJson(parsed);
//         if (!resp.isValid) {
//           return Result.fail(Failure(
//               code: 'validation',
//               message: resp.message ?? 'Signup failed',
//               statusCode: res.statusCode));
//         }
//         return Result.ok(resp);
//       }
//       return Result.fail(_serverFail(res));
//     } on SocketException {
//       return  Result.fail(
//           Failure(code: 'network', message: 'No internet connection'));
//     } on TimeoutException {
//       return  Result.fail(
//           Failure(code: 'timeout', message: 'Request timed out'));
//     } catch (e) {
//       return Result.fail(Failure(code: 'unknown', message: e.toString()));
//     }
//   }
// }




// class Failure {
//   final String code;
//   final String message;
//   final int? statusCode;
//   const Failure({required this.code, required this.message, this.statusCode});
// }

// class Result<T> {
//   final T? data;
//   final Failure? failure;
//   const Result._(this.data, this.failure);
//   bool get isSuccess => failure == null;

//   factory Result.ok(T data) => Result._(data, null);
//   factory Result.fail(Failure f) => Result._(null, f);
// }