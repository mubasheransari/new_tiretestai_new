import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tire_testai/Bloc/auth_bloc.dart';
import 'package:tire_testai/Bloc/auth_event.dart';
import 'package:tire_testai/Bloc/auth_state.dart';
import 'package:tire_testai/Data/app_routes.dart';
import 'package:tire_testai/Repository/repository.dart';
import 'package:tire_testai/Screens/auth_screen.dart';
import 'package:tire_testai/Screens/home_screen.dart';
import 'package:tire_testai/Screens/splash_screen.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();                     // default box
  final authRepo = AuthRepositoryHttp();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(authRepo)..add(AppStarted()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taskoon App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      // Named routes used by the bottom bar:
      onGenerateRoute: AppRoutes.onGenerateRoute,
      // AuthGate decides which first screen to render:
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // If no token, show Auth immediately
    final box   = GetStorage();
    final token = (box.read<String>('auth_token') ?? '').trim();
    if (token.isEmpty) return const AuthScreen();

    // With token: wait for profile to load; success -> Home, failure -> Auth
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (p, c) => p.profileStatus != c.profileStatus,
      builder: (context, state) {
        switch (state.profileStatus) {
          case ProfileStatus.success:
            return const InspectionHomePixelPerfect(); // this screen has the bottom bar
          case ProfileStatus.failure:
            // Optional: box.remove('auth_token');
            return const AuthScreen();
          case ProfileStatus.initial:
          case ProfileStatus.loading:
          default:
            return const SplashScreen();
        }
      },
    );
  }
}


/*

void main() async{
  final authRepo = AuthRepositoryHttp();
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init(); // default box, no name needed
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(authRepo)..add(AppStarted()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taskoon App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const AuthGate(), 
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // IMPORTANT: match your TokenStore. If you used a named box, use GetStorage('auth_box')
    final box   = GetStorage();                    // or: GetStorage('auth_box')
    final token = (box.read<String>('auth_token') ?? '').trim();

    // No token → always Auth
    if (token.isEmpty) return const SplashScreen();

    // Token present → show Splash until profileStatus == success → then Home; failure → Auth
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (p, c) => p.profileStatus != c.profileStatus,
      builder: (context, state) {
        switch (state.profileStatus) {
          case ProfileStatus.success:
            return const InspectionHomePixelPerfect();
          case ProfileStatus.failure:
            // (optional) box.remove('auth_token'); // clear bad/expired token
            return const AuthScreen();
          case ProfileStatus.initial:
          case ProfileStatus.loading:
            return const SplashScreen();           // 👈 show your exact splash
        }
      },
    );
  }
}

*/

// class AuthGate extends StatelessWidget {
//   const AuthGate({super.key});

//   @override
//   Widget build(BuildContext context) {
//    final hasToken = (GetStorage().read<String>('auth_token') ?? '').trim().isNotEmpty;

//     return BlocListener<AuthBloc, AuthState>(
//       listenWhen: (prev, curr) => prev.loginStatus != curr.loginStatus,
//       listener: (context, state) {
//         if (state.loginStatus == AuthStatus.success && state.profileStatus == ProfileStatus.success) {
//           // On login success, go to Home
//           Navigator.of(context).pushAndRemoveUntil(
//             MaterialPageRoute(builder: (_) => const InspectionHomePixelPerfect()),
//             (route) => false,
//           );
//         }
//       },
//       child: hasToken  ? const SplashScreen() : const AuthScreen(),
//     );
//   }
// }
