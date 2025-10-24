import 'package:flutter/material.dart';
import 'package:tire_testai/Screens/home_screen.dart';
import 'package:tire_testai/Screens/location_google_maos.dart';
import 'package:tire_testai/Screens/profile_screen.dart' show ProfilePage;
import 'package:tire_testai/Screens/report_history_screen.dart';
import 'package:tire_testai/Screens/sponser_vendors_screen.dart';
import '../Widgets/bottom_bar.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  BottomTab _tab = BottomTab.home;

  final _keys = {
    BottomTab.home: GlobalKey<NavigatorState>(),
    BottomTab.reports: GlobalKey<NavigatorState>(),
    BottomTab.map: GlobalKey<NavigatorState>(),
    BottomTab.about: GlobalKey<NavigatorState>(),
    BottomTab.profile: GlobalKey<NavigatorState>(),
  };

  Future<bool> _onWillPop() async {
    final nav = _keys[_tab]!.currentState!;
    if (nav.canPop()) {
      nav.pop();
      return false;
    }
    if (_tab != BottomTab.home) {
      setState(() => _tab = BottomTab.home);
      return false;
    }
    return true;
  }

  void _setTab(BottomTab t) => setState(() => _tab = t);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: IndexedStack(
          index: _tab.index,
          children: [
            _TabNavigator(key: _keys[BottomTab.home], initial: const InspectionHomePixelPerfect()),
            _TabNavigator(key: _keys[BottomTab.reports], initial: const ReportHistoryScreen()),
            _TabNavigator(key: _keys[BottomTab.map], initial: const LocationVendorsMapScreen()),
            _TabNavigator(key: _keys[BottomTab.about], initial: const SponsoredVendorsScreen()),
            _TabNavigator(key: _keys[BottomTab.profile], initial: const ProfilePage()),
          ],
        ),
        bottomNavigationBar: BottomBar(
          active: _tab,
          onChanged: _setTab,
        ),
      ),
    );
  }
}

class _TabNavigator extends StatelessWidget {
  const _TabNavigator({super.key, required this.initial});
  final Widget initial;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => initial,
          settings: settings,
        );
      },
    );
  }
}

// ===== Replace these with your real pages =====
class _HomeRoot extends StatelessWidget {
  const _HomeRoot();

  @override
  Widget build(BuildContext context) => _DemoPage(
        title: 'Home',
        pushLabel: 'Open details',
      );
}

class _ReportsRoot extends StatelessWidget {
  const _ReportsRoot();
  @override
  Widget build(BuildContext context) => const _DemoPage(title: 'Reports');
}

class _MapRoot extends StatelessWidget {
  const _MapRoot();
  @override
  Widget build(BuildContext context) => const _DemoPage(title: 'Map');
}

class _AboutRoot extends StatelessWidget {
  const _AboutRoot();
  @override
  Widget build(BuildContext context) => const _DemoPage(title: 'About');
}

class _ProfileRoot extends StatelessWidget {
  const _ProfileRoot();
  @override
  Widget build(BuildContext context) => const _DemoPage(title: 'Profile');
}

// Demo page: shows pushing within a tab
class _DemoPage extends StatelessWidget {
  const _DemoPage({required this.title, this.pushLabel});
  final String title;
  final String? pushLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: pushLabel == null
            ? Text('This is $title tab')
            : ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('Details')),
                      body: Center(child: Text('Details inside $title tab')),
                    ),
                  ),
                ),
                child: Text(pushLabel!),
              ),
      ),
    );
  }
}
