import 'package:equatable/equatable.dart';
import 'package:tire_testai/Models/auth_models.dart';

enum AuthStatus { initial, loading, success, failure }

class AuthState extends Equatable {
  final AuthStatus loginStatus;
  final AuthStatus signupStatus;
  final LoginResponse? loginResponse;
  final SignupResponse? signupResponse;
  final String? error;

  const AuthState({
    this.loginStatus = AuthStatus.initial,
    this.signupStatus = AuthStatus.initial,
    this.loginResponse,
    this.signupResponse,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? loginStatus,
    AuthStatus? signupStatus,
    LoginResponse? loginResponse,
    SignupResponse? signupResponse,
    String? error, // pass null to clear
  }) {
    return AuthState(
      loginStatus: loginStatus ?? this.loginStatus,
      signupStatus: signupStatus ?? this.signupStatus,
      loginResponse: loginResponse ?? this.loginResponse,
      signupResponse: signupResponse ?? this.signupResponse,
      error: error,
    );
  }

  @override
  List<Object?> get props =>
      [loginStatus, signupStatus, loginResponse, signupResponse, error];
}

