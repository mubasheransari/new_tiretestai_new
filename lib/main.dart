import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tire_testai/Bloc/auth_bloc.dart';
import 'package:tire_testai/Bloc/auth_event.dart';
import 'package:tire_testai/Bloc/auth_state.dart';
import 'package:tire_testai/Repository/repository.dart';
import 'package:tire_testai/Screens/auth_screen.dart';
import 'package:tire_testai/Screens/home_screen.dart';
import 'package:tire_testai/Screens/splash_screen.dart';



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
   final hasToken = (GetStorage().read<String>('auth_token') ?? '').trim().isNotEmpty;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => prev.loginStatus != curr.loginStatus,
      listener: (context, state) {
        if (state.loginStatus == AuthStatus.success && state.profileStatus == ProfileStatus.success) {
          // On login success, go to Home
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const InspectionHomePixelPerfect()),
            (route) => false,
          );
        }
      },
      child: hasToken  ? const SplashScreen() : const AuthScreen(),
    );
  }
}
