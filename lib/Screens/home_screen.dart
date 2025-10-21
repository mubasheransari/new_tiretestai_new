// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tire_testai/Bloc/auth_bloc.dart';
import 'package:tire_testai/Bloc/auth_event.dart';
import 'package:tire_testai/Screens/report_history_screen.dart';
import 'package:tire_testai/Screens/scanner_screen.dart';

const kBg = Color(0xFFF6F7FA);
const kTxtDim = Color(0xFF6A6F7B);
const kTxtDark = Color(0xFF1F2937);
const kSearchBg = Color(0xFFF0F2F5);
const kIconMuted = Color(0xFF9CA3AF);
const kBikeText = Color(0xFF444B59);

const kGradBluePurple = LinearGradient(
  colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

const kCardCarGrad = LinearGradient(
  colors: [Color(0xFF1CC8FF), Color(0xFF6B63FF)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// Pixel-perfect screen; base width 393 for scaling.
/// Replace avatar/wheel images with your assets for a 1:1 look.
class InspectionHomePixelPerfect extends StatelessWidget {
  const InspectionHomePixelPerfect({super.key});

  static const _bg = Color(0xFFF6F7FA);
  static const _txtDim = Color(0xFF6A6F7B);
  static const _txtDark = Color(0xFF1F2937);
  static const _searchBg = Color(0xFFF0F2F5);
  static const _iconMuted = Color(0xFF9CA3AF);
  static const _bikeText = Color(0xFF444B59);

  static const _gradBluePurple = LinearGradient(
    colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  void _toast(BuildContext ctx, String msg) =>
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));

Future<void> _openTwoWheelerScanner(BuildContext context) async {
  // Navigate to your camera/reticle screen to capture FRONT + BACK
  final result = await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const ScannerFrontTireScreen()),
  );

  // User backed out
  if (result == null) return;

  // Grab anything you need from auth state (token, userId, selected vehicleId)
  final authState = context.read<AuthBloc>().state;
   final box   = GetStorage();  
      final token = (box.read<String>('auth_token') ?? '').trim();//final token     = authState.loginResponse?.token ?? '';      // adjust field names
  // final userId    = '';
  // final vehicleId = 'YOUR_SELECTED_BIKE_ID';                   // supply from your UI/selection

  if (token.isEmpty ) {
    _toast(context, 'Please login again.');
    return;
  }

  // Fire the upload event (this triggers the “generating” flow)
  context.read<AuthBloc>().add(UploadTwoWheelerRequested(
        userId:    context.read<AuthBloc>().state.profile!.userId.toString(),
        vehicleId: '993163bd-01a1-4c3b-9f18-4df2370ed954',
        token:     token,
        frontPath: result.frontPath,
        backPath:  result.backPath,
        vehicleType: 'bike',
        vin: result.vin, // optional
  ));

  // Optionally show a “Generating Report” screen while Bloc uploads/parses
  // Navigator.push(context,
  //   MaterialPageRoute(builder: (_) => const GeneratingReportScreen()),
  // );
}


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const baseW = 393.0; // iPhone 14/15 base
    final s = size.width / baseW;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16 * s, 14 * s, 16 * s, 100 * s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    SizedBox(height: 6 * s),
                  _Header(s: s),
                  SizedBox(height: 16 * s),
                  _SearchBar(s: s),
                  SizedBox(height: 25 * s),
                  _CarCard(s: s),
                  SizedBox(height: 30 * s),
                  InkWell(
                    onTap: (){
                     _openTwoWheelerScanner(context);
                    },
                    child: _BikeCard(s: s)),
                ],
              ),
            ),
              Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16 * s, 0, 16 * s, 8 * s),
        child: _BottomBar(s: s, active: BottomTab.home),
        ),
      ),
    ),
            // Positioned(
            //  // top: 16,
            //   left: 16 * s,
            //   right: 16 * s,
            //   bottom: 1 * s,
            //   child: _BottomBar(s: s),
            // ),
          ],
        ),
      ),
    );
  }
}

/* ------------------------ Header ------------------------ */
class _Header extends StatelessWidget {
  const _Header({required this.s});
  final double s;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontFamily: 'ClashGrotesk',
                fontSize: 14 * s,
                color: Color(0xFF6A6F7B),
                height: 1.2,
              ),
              children: [
                 TextSpan(text: 'Good morning,\n',   style: TextStyle(
                      fontFamily: 'ClashGrotesk',
                      fontSize: 18 * s,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      letterSpacing: 0.1 * s,
                    ),),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: _GradientText(
                  "${context.read<AuthBloc>().state.profile!.firstName.toString() + context.read<AuthBloc>().state.profile!.userId.toString()}", // 'William David',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    style: TextStyle(
                      fontFamily: 'ClashGrotesk',
                      fontSize: 25 * s,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                      letterSpacing: 0.1 * s,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 10 * s),
        Container(
          padding: EdgeInsets.all(2 * s),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8 * s,
                offset: Offset(0, 4 * s),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 30 * s,
            backgroundImage: const AssetImage('assets/avatar.png'),
          ),
        ),
      ],
    );
  }
}

/* ------------------------ Search ------------------------ */
class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.s});
  final double s;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44 * s,
      decoration: BoxDecoration(
        color: Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(14 * s),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12 * s),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 22 * s, color: Color(0xFF9CA3AF)),
          SizedBox(width: 8 * s),
          Expanded(
            child: Text(
              'Search the latest inspection',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'ClashGrotesk',
                fontSize: 14 * s,
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ------------------------ Car Card ------------------------ */
class _CarCard extends StatelessWidget {
  const _CarCard({required this.s});
  final double s;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 219 * s,
      width: MediaQuery.of(context).size.width*0.90,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1CC8FF), Color(0xFF6B63FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(9 * s),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B63FF).withOpacity(0.25),
            blurRadius: 20 * s,
            offset: Offset(0, 10 * s),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -25 * s,
            top: -10 * s,
            child: SizedBox(
              width: 225 * s,
              height: 230 * s,
              child: Image.asset(
                'assets/car_tyres.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16 * s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Car Wheel\nInspection',
                  style: TextStyle(
                    fontFamily: 'ClashGrotesk',
                    color: Colors.white,
                    fontSize: 29 * s,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                SizedBox(height: 6 * s),
                Text(
                  'Scan your car wheels\nto detect wear & damage',
                  style: TextStyle(
                    fontFamily: 'ClashGrotesk',
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 16.5 * s,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: 34,),
                _ChipButtonWhite(
                  s: s,
                  icon: 'assets/scan_icon.png',
                  label: 'Scan Car Tries', // matches the mock text
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ------------------------ Bike Card ------------------------ */
class _BikeCard extends StatelessWidget {
  const _BikeCard({required this.s});
  final double s;

  @override
  Widget build(BuildContext context) {
    return Container(
           height: 245 * s,
      width: MediaQuery.of(context).size.width*0.90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9 * s),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18 * s,
            offset: Offset(0, 10 * s),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
          right: 18 * s,
            top: -10 * s,
            child: SizedBox(
              width: 225 * s,
              height: 240 * s,
              child: Image.asset(
                'assets/bike_wheel.png',
                fit: BoxFit.contain,
      
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16 * s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GradientText(
                  'Bike Wheel\nInspection',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  style: TextStyle(
                    fontFamily: 'ClashGrotesk',
                          fontSize: 29 * s,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    
                  ),
                ),
                SizedBox(height: 6 * s),
                Text(
                  'Analyze your motorcycle\ntires and get a report',
                  style: TextStyle(
                    fontFamily: 'ClashGrotesk',
                    color: Color(0xFF444B59),
                         fontSize: 16.5 * s,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                const Spacer(),
                _ChipButtonGradient(
                  s: s,
                  icon: Icons.document_scanner_outlined,
                  label: 'Scan Bike Tries', // matches the mock text
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ------------------------ Chip Buttons ------------------------ */
class _ChipButtonWhite extends StatelessWidget {
  const _ChipButtonWhite({required this.s, required this.icon, required this.label});
  final double s;
  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40 * s,
      padding: EdgeInsets.symmetric(horizontal: 12 * s),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5 * s),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 12 * s,
            offset: Offset(0, 6 * s),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
        Image.asset(icon,height: 22 * s,width: 22 * s,color: Colors.black,), // Icon(icon, color: Color(0xFF1F2937), size: 18 * s),
          SizedBox(width: 8 * s),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'ClashGrotesk',
              color: Color(0xFF1F2937),
              fontSize: 16 * s,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipButtonGradient extends StatelessWidget {
  const _ChipButtonGradient({required this.s, required this.icon, required this.label});
  final double s;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
     height: 40 * s,
      padding: EdgeInsets.symmetric(horizontal: 12 * s),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
        ),
        borderRadius: BorderRadius.circular(5 * s),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7F53FD).withOpacity(0.25),
            blurRadius: 12 * s,
            offset: Offset(0, 6 * s),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
                  Image.asset('assets/scan_icon.png',height: 22 * s,width: 22 * s,color: Colors.white,),
        //  Icon(icon, color: Colors.white, size: 18 * s),
          SizedBox(width: 8 * s),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'ClashGrotesk',
            color: Colors.white,
              fontSize: 16 * s,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// Put this somewhere near the bottom of your file (or in its own file).

enum BottomTab { home, reports, map, about, profile }

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.active,
    required this.icon,
    required this.onTap,
    this.s = 1,
  });

  final bool active;
  final IconData icon;
  final VoidCallback onTap;
  final double s;

  @override
  Widget build(BuildContext context) {
    // Make the whole icon tappable in both states.
    if (!active) {
      return InkWell(
        borderRadius: BorderRadius.circular(22 * s),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(8 * s),
          child: Icon(icon, size: 24 * s, color: const Color(0xFF9AA1AE)),
        ),
      );
    }

    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 40 * s,
        height: 40 * s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7F53FD).withOpacity(0.35),
              blurRadius: 14 * s,
              offset: Offset(0, 6 * s),
            ),
          ],
        ),
        child: Icon(icon, size: 22 * s, color: Colors.white),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.s,
    this.active = BottomTab.home,
  });

  final double s;
  final BottomTab active;

  void _go(BuildContext ctx, BottomTab tab) {
    if (tab == active) return; // already here
    switch (tab) {
      case BottomTab.home:
       Navigator.push(ctx, MaterialPageRoute(builder: (ctx)=> InspectionHomePixelPerfect()));
        break;
      case BottomTab.reports:
          Navigator.push(ctx, MaterialPageRoute(builder: (ctx)=> ReportHistoryScreen()));
        break;
      case BottomTab.map:
        Navigator.of(ctx).pushReplacementNamed('/map');
        break;
      case BottomTab.about:
        Navigator.of(ctx).pushReplacementNamed('/about');
        break;
      case BottomTab.profile:
        Navigator.of(ctx).pushReplacementNamed('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64 * s,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32 * s),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18 * s,
            offset: Offset(0, 10 * s),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 16 * s),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavIcon(
            active: active == BottomTab.home,
            icon: Icons.home_filled,
            s: s,
            onTap: () => _go(context, BottomTab.home),
          ),
          _NavIcon(
            active: active == BottomTab.reports,
            icon: Icons.insert_drive_file,
            s: s,
            onTap: () => _go(context, BottomTab.reports),
          ),
          _NavIcon(
            active: active == BottomTab.map,
            icon: Icons.location_on_rounded,
            s: s,
            onTap: () => _go(context, BottomTab.map),
          ),
          _NavIcon(
            active: active == BottomTab.about,
            icon: Icons.info_outline_rounded,
            s: s,
            onTap: () => _go(context, BottomTab.about),
          ),
          _NavIcon(
            active: active == BottomTab.profile,
            icon: Icons.person_rounded,
            s: s,
            onTap: () => _go(context, BottomTab.profile),
          ),
        ],
      ),
    );
  }
}


/* ------------------------ Bottom Bar ------------------------ */
// class _BottomBar extends StatelessWidget {
//   const _BottomBar({required this.s});
//   final double s;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 64 * s,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(32 * s),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.08),
//             blurRadius: 18 * s,
//             offset: Offset(0, 10 * s),
//           ),
//         ],
//       ),
//       padding: EdgeInsets.symmetric(horizontal: 16 * s),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: const [
//           _NavIcon(active: true,  icon: Icons.home_filled),
//           _NavIcon(active: false, icon: Icons.insert_drive_file),
//           _NavIcon(active: false, icon: Icons.location_on_rounded),
//           _NavIcon(active: false, icon: Icons.info_outline_rounded),
//           _NavIcon(active: false, icon: Icons.person_rounded),
//         ],
//       ),
//     );
//   }
// }

// class _NavIcon extends StatelessWidget {
//   const _NavIcon({required this.active, required this.icon, this.s = 1});
//   final bool active;
//   final IconData icon;
//   final double s;

//   @override
//   Widget build(BuildContext context) {
//     if (!active) {
//       return Icon(icon, size: 24 * s, color: const Color(0xFF9AA1AE));
//     }
//     return Container(
//       width: 40 * s,
//       height: 40 * s,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         gradient: const LinearGradient(
//           colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: const Color(0xFF7F53FD).withOpacity(0.35),
//             blurRadius: 14 * s,
//             offset: Offset(0, 6 * s),
//           ),
//         ],
//       ),
//       child: Icon(icon, size: 22 * s, color: Colors.white),
//     );
//   }
// }

/* ------------------------ Gradient Text ------------------------ */
class _GradientText extends StatelessWidget {
  const _GradientText(this.text, {required this.gradient, required this.style, super.key});
  final String text;
  final Gradient gradient;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => gradient.createShader(rect),
      blendMode: BlendMode.srcIn,
      child: Text(text, style: style.copyWith(fontFamily: 'ClashGrotesk')),
    );
  }
}
