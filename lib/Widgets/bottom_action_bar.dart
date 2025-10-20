import 'package:flutter/material.dart';

class BottomActionBar extends StatelessWidget {
  const BottomActionBar({
    super.key,
    required this.onPickGallery,
    required this.onCapture,
    required this.onPickDocs,
    required this.enabled,
  });

  final VoidCallback onPickGallery;
  final VoidCallback onCapture;
  final VoidCallback onPickDocs;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / 390.0; // simple scale
    return Container(
      height: 100,
      padding: EdgeInsets.fromLTRB(12 * s, 6 * s, 12 * s, 26 ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18 * s),
        boxShadow: const [BoxShadow(color: Color(0x1A0E1631), blurRadius: 16, offset: Offset(0, -6))],
      ),
      child: Row(
        children: [
          _chip(context, s, icon: Icons.image_rounded, label: 'Images', onTap: onPickGallery),
          SizedBox(width: 12 * s),
          Expanded(
            child: _centerCapture(context, s, onTap: enabled ? onCapture : null),
          ),
          SizedBox(width: 12 * s),
          _chip(context, s, icon: Icons.description_rounded, label: 'Documents', onTap: onPickDocs),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, double s,
      {required IconData icon, required String label, VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16 * s),
        child: Container(
          height: 64 * s,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F6FF),
            borderRadius: BorderRadius.circular(16 * s),
          ),
          padding: EdgeInsets.symmetric(horizontal: 12 * s),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF1F2937)),
              SizedBox(width: 8 * s),
              Text(label,
                  style: TextStyle(
                      fontFamily: 'ClashGrotesk',
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _centerCapture(BuildContext context, double s, {VoidCallback? onTap}) {
    final base = Colors.blue;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 72 * s,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [base, base.withOpacity(.6)]),
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Color(0x1A0E1631), blurRadius: 16, offset: Offset(0, 10))],
        ),
        padding: EdgeInsets.all(8 * s),
        child: Container(
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          padding: EdgeInsets.all(10 * s),
          child: Icon(Icons.tire_repair_rounded, color: base, size: 28 * s),
        ),
      ),
    );
  }
}
