import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tire_testai/Bloc/auth_event.dart';
import 'package:tire_testai/Bloc/auth_state.dart';
import 'package:tire_testai/Repository/repository.dart';
import '../Models/auth_models.dart';



class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repo;

  AuthBloc(this.repo) : super( AuthState()) {
    on<LoginRequested>(_onLogin);
    on<SignupRequested>(_onSignup);
    on<ClearAuthError>((e, emit) => emit(state.copyWith(error: null)));
  }

  Future<void> _onLogin(LoginRequested e, Emitter<AuthState> emit) async {
    emit(state.copyWith(loginStatus: AuthStatus.loading, error: null));
    final r = await repo.login(LoginRequest(email: e.email, password: e.password));

    if (r.isSuccess) {
      emit(state.copyWith(
        loginStatus: AuthStatus.success,
        loginResponse: r.data,
        error: null,
      ));
    } else {
      emit(state.copyWith(
        loginStatus: AuthStatus.failure,
        error: r.failure?.message ?? 'Login failed',
      ));
    }
  }

  Future<void> _onSignup(SignupRequested e, Emitter<AuthState> emit) async {
    emit(state.copyWith(signupStatus: AuthStatus.loading, error: null));
    final r = await repo.signup(SignupRequest(
      firstName: e.firstName,
      lastName: e.lastName,
      email: e.email,
      password: e.password,
    ));

    if (r.isSuccess) {
      emit(state.copyWith(
        signupStatus: AuthStatus.success,
        signupResponse: r.data,
        error: null,
      ));
    } else {
      emit(state.copyWith(
        signupStatus: AuthStatus.failure,
        error: r.failure?.message ?? 'Signup failed',
      ));
    }
  }
}