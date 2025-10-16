import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:tire_testai/Api_config/api_config.dart';
import 'package:tire_testai/Models/auth_models.dart';

abstract class AuthRepository {
  Future<Result<LoginResponse>> login(LoginRequest req);
  Future<Result<SignupResponse>> signup(SignupRequest req);
}

class AuthRepositoryHttp implements AuthRepository {
  AuthRepositoryHttp({this.timeout = const Duration(seconds: 30)});
  final Duration timeout;

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

  @override
  Future<Result<LoginResponse>> login(LoginRequest req) async {
    final uri = Uri.parse(ApiConfig.login);
    try {
      final res = await http
          .post(uri, headers: _headers(), body: jsonEncode(req.toJson()))
          .timeout(timeout);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final parsed = jsonDecode(res.body);
        if (parsed is! Map<String, dynamic>) {
          return Result.fail(
            const Failure(code: 'parse', message: 'Invalid response format'),
          );
        }
        final resp = LoginResponse.fromJson(parsed);
        if (!resp.isValid) {
          return Result.fail(Failure(
              code: 'validation',
              message: parsed['message']?.toString() ?? 'Login failed',
              statusCode: res.statusCode));
        }
        return Result.ok(resp);
      }
      return Result.fail(_serverFail(res));
    } on SocketException {
      return  Result.fail(
          Failure(code: 'network', message: 'No internet connection'));
    } on TimeoutException {
      return  Result.fail(
          Failure(code: 'timeout', message: 'Request timed out'));
    } catch (e) {
      return Result.fail(Failure(code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<Result<SignupResponse>> signup(SignupRequest req) async {
    final uri = Uri.parse(ApiConfig.signup);
    try {
      final res = await http
          .post(uri, headers: _headers(), body: jsonEncode(req.toJson()))
          .timeout(timeout);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final parsed = jsonDecode(res.body);
        if (parsed is! Map<String, dynamic>) {
          return Result.fail(
            const Failure(code: 'parse', message: 'Invalid response format'),
          );
        }
        final resp = SignupResponse.fromJson(parsed);
        if (!resp.isValid) {
          return Result.fail(Failure(
              code: 'validation',
              message: resp.message ?? 'Signup failed',
              statusCode: res.statusCode));
        }
        return Result.ok(resp);
      }
      return Result.fail(_serverFail(res));
    } on SocketException {
      return  Result.fail(
          Failure(code: 'network', message: 'No internet connection'));
    } on TimeoutException {
      return  Result.fail(
          Failure(code: 'timeout', message: 'Request timed out'));
    } catch (e) {
      return Result.fail(Failure(code: 'unknown', message: e.toString()));
    }
  }
}




class Failure {
  final String code;
  final String message;
  final int? statusCode;
  const Failure({required this.code, required this.message, this.statusCode});
}

class Result<T> {
  final T? data;
  final Failure? failure;
  const Result._(this.data, this.failure);
  bool get isSuccess => failure == null;

  factory Result.ok(T data) => Result._(data, null);
  factory Result.fail(Failure f) => Result._(null, f);
}