import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tire_testai/Bloc/auth_event.dart';
import 'package:tire_testai/Bloc/auth_state.dart';
import 'package:tire_testai/Models/tyre_upload_models.dart';
import 'package:tire_testai/Repository/repository.dart';
import '../Models/auth_models.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repo;

  AuthBloc(this.repo) : super(const AuthState()) {
    on<AppStarted>(_onAppStarted);

    on<LoginRequested>(_onLogin);
    on<SignupRequested>(_onSignup);

    on<UploadTwoWheelerRequested>(_onTwoWheelerUpload);

    on<FetchProfileRequested>(_onFetchProfile);

    on<ClearAuthError>((e, emit) => emit(state.copyWith(error: null)));
  }

  // Called once when app launches
  Future<void> _onAppStarted(AppStarted e, Emitter<AuthState> emit) async {
    final tok = await repo.getSavedToken();
    if (tok != null && tok.isNotEmpty) {
      // auto-fetch profile for logged-in users
      add(const FetchProfileRequested());
    }
  }

  Future<void> _onLogin(LoginRequested e, Emitter<AuthState> emit) async {
    emit(state.copyWith(loginStatus: AuthStatus.loading, error: null));
    final r = await repo.login(LoginRequest(email: e.email, password: e.password));

    if (r.isSuccess) {
      // token is saved inside repo.login() (best-effort)
      emit(state.copyWith(
        loginStatus: AuthStatus.success,
        loginResponse: r.data,
        error: null,
      ));
      // Immediately fetch profile
      add(const FetchProfileRequested());
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

  Future<void> _onTwoWheelerUpload(
    UploadTwoWheelerRequested e,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(twoWheelerStatus: TwoWheelerStatus.uploading, error: null));

    final req = TyreUploadRequest(
      userId: e.userId,
      vehicleType: e.vehicleType,
      vehicleId: e.vehicleId,
      frontPath: e.frontPath,
      backPath: e.backPath,
      token: e.token,
      vin: e.vin,
    );

    final r = await repo.uploadTwoWheeler(req);

    if (r.isSuccess) {
      emit(state.copyWith(
        twoWheelerStatus: TwoWheelerStatus.success,
        twoWheelerResponse: r.data,
        error: null,
      ));
    } else {
      emit(state.copyWith(
        twoWheelerStatus: TwoWheelerStatus.failure,
        error: r.failure?.message ?? 'Upload failed',
      ));
    }
  }

  // NEW: Fetch profile
  Future<void> _onFetchProfile(
    FetchProfileRequested e,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(profileStatus: ProfileStatus.loading, error: null));

    final r = await repo.fetchProfile(token: e.token);

    if (r.isSuccess) {
      emit(state.copyWith(
        profileStatus: ProfileStatus.success,
        profile: r.data,
        error: null,
      ));
    } else {
      emit(state.copyWith(
        profileStatus: ProfileStatus.failure,
        error: r.failure?.message ?? 'Failed to fetch profile',
      ));
    }
  }
}


/*
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repo;

  AuthBloc(this.repo) : super(const AuthState()) {
    on<LoginRequested>(_onLogin);
    on<SignupRequested>(_onSignup);
    on<UploadTwoWheelerRequested>(_onTwoWheelerUpload);
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

  // ========== NEW: Two-wheeler upload flow with its own status enum ==========
  Future<void> _onTwoWheelerUpload(
    UploadTwoWheelerRequested e,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(twoWheelerStatus: TwoWheelerStatus.uploading, error: null));

    final req = TyreUploadRequest(
      userId: e.userId,
      vehicleType: e.vehicleType, // usually "bike"
      vehicleId: e.vehicleId,
      frontPath: e.frontPath,
      backPath: e.backPath,
      token: e.token,
      vin: e.vin,
    );

    final r = await repo.uploadTwoWheeler(req);

    if (r.isSuccess) {
      emit(state.copyWith(
        twoWheelerStatus: TwoWheelerStatus.success,
        twoWheelerResponse: r.data,
        error: null,
      ));
    } else {
      emit(state.copyWith(
        twoWheelerStatus: TwoWheelerStatus.failure,
        error: r.failure?.message ?? 'Upload failed',
      ));
    }
  }
}
*/

// class AuthBloc extends Bloc<AuthEvent, AuthState> {
//   final AuthRepository repo;

//   AuthBloc(this.repo) : super( AuthState()) {
//     on<LoginRequested>(_onLogin);
//     on<SignupRequested>(_onSignup);
//     on<ClearAuthError>((e, emit) => emit(state.copyWith(error: null)));
//   }

//   Future<void> _onLogin(LoginRequested e, Emitter<AuthState> emit) async {
//     emit(state.copyWith(loginStatus: AuthStatus.loading, error: null));
//     final r = await repo.login(LoginRequest(email: e.email, password: e.password));

//     if (r.isSuccess) {
//       emit(state.copyWith(
//         loginStatus: AuthStatus.success,
//         loginResponse: r.data,
//         error: null,
//       ));
//     } else {
//       emit(state.copyWith(
//         loginStatus: AuthStatus.failure,
//         error: r.failure?.message ?? 'Login failed',
//       ));
//     }
//   }

//   Future<void> _onSignup(SignupRequested e, Emitter<AuthState> emit) async {
//     emit(state.copyWith(signupStatus: AuthStatus.loading, error: null));
//     final r = await repo.signup(SignupRequest(
//       firstName: e.firstName,
//       lastName: e.lastName,
//       email: e.email,
//       password: e.password,
//     ));

//     if (r.isSuccess) {
//       emit(state.copyWith(
//         signupStatus: AuthStatus.success,
//         signupResponse: r.data,
//         error: null,
//       ));
//     } else {
//       emit(state.copyWith(
//         signupStatus: AuthStatus.failure,
//         error: r.failure?.message ?? 'Signup failed',
//       ));
//     }
//   }
// }