import 'package:flutter/material.dart';

enum BottomTab { home, reports, map, about, profile }

class BottomBar extends StatelessWidget {
  const BottomBar({
    super.key,
    required this.active,
    required this.onChanged,
    this.scale,
  });

  final BottomTab active;
  final ValueChanged<BottomTab> onChanged;
  final double? scale;

  void _go(BottomTab tab) {
    if (tab == active) return;
    onChanged(tab);
  }

  @override
  Widget build(BuildContext context) {
    final s = scale ?? (MediaQuery.of(context).size.width / 390.0);

    Widget _circle(
      IconData i, {
      bool big = false,
      required VoidCallback onTap,
      required bool isActive,
    }) {
      final base = Container(
        width: (big ? 64 : 54) * s,
        height: (big ? 64 : 54) * s,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.20),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.08),
              blurRadius: 18 * s,
              offset: Offset(0, 10 * s),
            ),
          ],
          border: Border.all(color: const Color(0xFFE9ECF2)),
          gradient: big
              ? const LinearGradient(
                  colors: [Color(0xFF7FD1FF), Color(0xFF7F53FD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Icon(
          i,
          size: (big ? 28 : 24) * s,
          color: big
              ? Colors.white
              : (isActive ? const Color(0xFF3A49A1) : const Color(0xFF58627A)),
        ),
      );
      return InkWell(borderRadius: BorderRadius.circular(999), onTap: onTap, child: base);
    }

    return SafeArea(
      minimum: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 10 * s),
      child: Container(
        height: 78 * s,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(44 * s),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.08),
              blurRadius: 20 * s,
              offset: Offset(0, 10 * s),
            )
          ],
          border: Border.all(color: const Color(0xFFE9ECF2)),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16 * s),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _circle(Icons.home_filled,
                onTap: () => _go(BottomTab.home),
                isActive: active == BottomTab.home),
            _circle(Icons.insert_drive_file_rounded,
                onTap: () => _go(BottomTab.reports),
                isActive: active == BottomTab.reports),
            _circle(Icons.add_location_alt_rounded,
                big: true,
                onTap: () => _go(BottomTab.map),
                isActive: active == BottomTab.map),
            _circle(Icons.sports_motorsports_rounded,
                onTap: () => _go(BottomTab.about),
                isActive: active == BottomTab.about),
            _circle(Icons.person_rounded,
                onTap: () => _go(BottomTab.profile),
                isActive: active == BottomTab.profile),
          ],
        ),
      ),
    );
  }
}
