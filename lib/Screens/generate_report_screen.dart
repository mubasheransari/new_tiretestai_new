import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tire_testai/Bloc/auth_bloc.dart';
import 'package:tire_testai/Bloc/auth_event.dart';
import 'package:tire_testai/Bloc/auth_state.dart';
import 'package:tire_testai/Screens/inspection_result_screen.dart';


class GenerateReportScreen extends StatefulWidget {
  const GenerateReportScreen({
    super.key,
    required this.frontPath,
    required this.backPath,
    required this.userId,
    required this.vehicleId,
    required this.token,
  });

  final String frontPath;
  final String backPath;
  final String userId;
  final String vehicleId;
  final String token;

  @override
  State<GenerateReportScreen> createState() => _GenerateReportScreenState();
}

class _GenerateReportScreenState extends State<GenerateReportScreen> {
  int _counter = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdownAndUpload();
  }

  void _startCountdownAndUpload() {
    // Kick the upload immediately (don’t wait for countdown)
    context.read<AuthBloc>().add(UploadTwoWheelerRequested(
          userId: widget.userId,
          vehicleId: widget.vehicleId,
          token: widget.token,
          frontPath: widget.frontPath,
          backPath: widget.backPath,
          vehicleType: 'bike', // change to 'car' if needed by backend
        ));

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _counter--);
      if (_counter <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / 390.0;
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (p, c) => p.twoWheelerStatus != c.twoWheelerStatus,
        listener: (context, state) {
          if (state.twoWheelerStatus == TwoWheelerStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error ?? 'Upload failed')),
            );
          }
          if (state.twoWheelerStatus == TwoWheelerStatus.success) {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (_) => InspectionResultScreen(
                frontPath: widget.frontPath,
                backPath: widget.backPath,
                response: state.twoWheelerResponse,
              ),
            ));
          }
        },
        builder: (context, state) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // pretty background image – use your own
              Image.asset(
                'assets/sample/garage_bg.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.black),
              ),
              Container(color: Colors.black.withOpacity(.45)),
              SafeArea(
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 32),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const Spacer(),
                    Text('Generating Report in',
                        style: TextStyle(
                          fontFamily: 'ClashGrotesk',
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 20 * s,
                        )),
                    SizedBox(height: 10 * s),
                    _concentricCircle(s, text: '${_counter.clamp(0, 9)}'),
                    const Spacer(),
                    // thin gradient bar like mock
                    Container(
                      height: 8 * s,
                      margin: EdgeInsets.fromLTRB(20 * s, 0, 20 * s, 26 * s),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8 * s),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F7BFF), Color(0xFFA270FF)],
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _concentricCircle(double s, {required String text}) {
    final List<double> radii = [120, 92, 64];
    return SizedBox(
      width: radii.first * s,
      height: radii.first * s,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final r in radii)
            Container(
              width: r * s,
              height: r * s,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(.10),
                border: Border.all(color: Colors.white.withOpacity(.30), width: 2),
              ),
            ),
          Text(text,
              style: TextStyle(
                fontFamily: 'ClashGrotesk',
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontSize: 56 * s,
              )),
        ],
      ),
    );
  }
}
