import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tire_testai/Screens/home_screen.dart';
import 'package:tire_testai/Screens/report_history_screen.dart';
// ignore_for_file: use_build_context_synchronously
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/*
Image‑2 pixel style summary
- Soft, light map with custom blue concentric markers
- Top left back button + bold title
- "Sponsored vendors :" pill label
- Horizontal vendor cards with rounded image, rating badge, bookmark icon
- Floating pill bottom nav; center action is larger w/ gradient
- Custom tooltip card anchored to the selected marker

Drop this file into your project and use as a drop‑in replacement for
LocationVendorsMapScreen. Requires google_maps_flutter.
*/

class LocationVendorsMapScreen extends StatefulWidget {
  const LocationVendorsMapScreen({super.key, this.showFirstTooltipOnLoad = true});
  final bool showFirstTooltipOnLoad;

  @override
  State<LocationVendorsMapScreen> createState() => _LocationVendorsMapScreenState();
}

class _LocationVendorsMapScreenState extends State<LocationVendorsMapScreen> {
  GoogleMapController? _gm;

  // Camera
  static const _usaCenter = LatLng(39.8283, -98.5795);
  static const _initialZoom = 4.6;

  // Data
  final Map<MarkerId, VendorLite> _vendorByMarker = {};
  final Set<Marker> _markers = {};
  MarkerId? _selected;
  Offset? _selectedScreenPx; // map px for tooltip anchor

  // Marker art cache
  Uint8List? _markerIconSmall;

  @override
  void initState() {
    super.initState();
    _seedRandomMarkers(8);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Prepare marker art after we know device pixel ratio
      _markerIconSmall ??= await _buildMarkerArt(diameter: 54);
      _refreshMarkersIcon();

      if (widget.showFirstTooltipOnLoad && _markers.isNotEmpty) {
        setState(() => _selected = _markers.first.markerId);
        await _updateAnchor();
      }
    });
  }

  // ------------------------ Map style ------------------------
  static const _mapStyleJson = '''
  [
    {"elementType":"geometry","stylers":[{"color":"#f5f5f5"}]},
    {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
    {"elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},
    {"elementType":"labels.text.stroke","stylers":[{"color":"#f5f5f5"}]},
    {"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},
    {"featureType":"poi","stylers":[{"visibility":"off"}]},
    {"featureType":"road","elementType":"geometry","stylers":[{"color":"#ffffff"}]},
    {"featureType":"road","elementType":"labels.icon","stylers":[{"visibility":"off"}]},
    {"featureType":"road.arterial","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
    {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#dadada"}]},
    {"featureType":"transit","stylers":[{"visibility":"off"}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#e9f2ff"}]}
  ]
  ''';

  // ------------------------ Seed data ------------------------
  static const _minLat = 24.7433195;
  static const _maxLat = 49.3457868;
  static const _minLng = -124.7844079;
  static const _maxLng = -66.9513812;

  LatLng _randomUsaLatLng(math.Random r) {
    final lat = _minLat + r.nextDouble() * (_maxLat - _minLat);
    final lng = _minLng + r.nextDouble() * (_maxLng - _minLng);
    return LatLng(lat, lng);
  }

  void _seedRandomMarkers(int count) {
    final r = math.Random(42);
    for (var i = 0; i < count; i++) {
      final pos = _randomUsaLatLng(r);
      final id = MarkerId('m$i');
      final rating = (3.2 + r.nextDouble() * 1.6); // 3.2..4.8
      final v = VendorLite(
        i.isEven ? 'National Tyres And Autocare' : 'U.S. Auto Inspection',
        i.isEven
            ? 'Braconash Road, Leyland PR25 3ZE'
            : 'Service \u2022 USA',
        double.parse(rating.toStringAsFixed(1)),
        _sampleImages[i % _sampleImages.length],
      );
      _vendorByMarker[id] = v;
      _markers.add(Marker(
        markerId: id,
        position: pos,
        icon: _markerIconSmall != null
            ? BitmapDescriptor.fromBytes(_markerIconSmall!)
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        onTap: () async {
          setState(() => _selected = id);
          await _updateAnchor();
        },
        anchor: const Offset(.5, .5), // center since our art is circular
      ));
    }
  }

  void _refreshMarkersIcon() {
    if (_markerIconSmall == null) return;
    final updated = <Marker>{};
    for (final m in _markers) {
      updated.add(m.copyWith(iconParam: BitmapDescriptor.fromBytes(_markerIconSmall!)));
    }
    setState(() => _markers
      ..clear()
      ..addAll(updated));
  }

  Future<void> _updateAnchor() async {
    if (_gm == null || _selected == null) return;
    final latLng = _markers.firstWhere((m) => m.markerId == _selected).position;
    final sc = await _gm!.getScreenCoordinate(latLng);
    setState(() => _selectedScreenPx = Offset(sc.x.toDouble(), sc.y.toDouble()));
  }

  // Paint concentric, glowing blue marker with a white wheel glyph replacement
  Future<Uint8List> _buildMarkerArt({required double diameter}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(diameter, diameter);

    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2;
    final midR = outerR * .74;
    final innerR = outerR * .56;

    // soft glow
    final glowPaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        outerR,
        [const Color(0x3300B2FF), const Color(0x0000B2FF)],
      );
    canvas.drawCircle(center, outerR, glowPaint);

    // outer ring
    final outerPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0), Offset(size.width, size.height),
        [const Color(0xFF9BE7FF), const Color(0xFF7CC5FF)],
      );
    canvas.drawCircle(center, midR + 6, outerPaint);

    // middle ring
    final midPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0), Offset(size.width, size.height),
        [const Color(0xFF5CC7FF), const Color(0xFF35A9FF)],
      );
    canvas.drawCircle(center, midR, midPaint);

    // inner circle
    final innerPaint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawCircle(center, innerR, innerPaint);

    // wheel-like glyph substitute (4 small arcs)
    final stroke = Paint()
      ..color = const Color(0xFF2E84FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    for (var i = 0; i < 4; i++) {
      final start = i * math.pi / 2 + .35;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: innerR - 6),
        start,
        math.pi / 3,
        false,
        stroke,
      );
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / 390.0; // scale ref = 390
    final pad = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FA),
      body: SafeArea(
        top: true,
        bottom: false,
        child: Stack(
          children: [
            // --------------- MAP ---------------
            Positioned.fill(
              child: Listener(
                onPointerDown: (_) => FocusScope.of(context).unfocus(),
                child: LayoutBuilder(
                  builder: (ctx, c) {
                    final mapW = c.maxWidth;
                    final mapH = c.maxHeight;
                    return Stack(children: [
                      GoogleMap(
                        initialCameraPosition: const CameraPosition(target: _usaCenter, zoom: _initialZoom),
                        onMapCreated: (ctrl) async {
                          _gm = ctrl;
                          await _gm?.setMapStyle(_mapStyleJson);
                          await _updateAnchor();
                        },
                        onCameraIdle: _updateAnchor,
                        onTap: (_) => setState(() {
                          _selected = null;
                          _selectedScreenPx = null;
                        }),
                        markers: _markers,
                        zoomControlsEnabled: false,
                        compassEnabled: false,
                        myLocationEnabled: false,
                        myLocationButtonEnabled: false,
                        mapToolbarEnabled: false,
                        buildingsEnabled: false,
                        trafficEnabled: false,
                      ),

                      // Tooltip anchored to current selection
                      if (_selected != null && _selectedScreenPx != null)
                        _TooltipPositioner(
                          mapSize: Size(mapW, mapH),
                          anchor: _selectedScreenPx!,
                          child: _VendorTooltipCard(vendor: _vendorByMarker[_selected]!),
                        ),
                    ]);
                  },
                ),
              ),
            ),

            // --------------- HEADER ---------------
            Positioned(
              top: pad.top + 6 * s,
              left: 12 * s,
              right: 12 * s,
              child: Row(
                children: [
                  _roundBtn(
                    onTap: () => Navigator.maybePop(context),
                    child: const Icon(Icons.chevron_left_rounded, size: 26, color: Colors.black87),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 10 * s, horizontal: 14 * s),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.9),
                        borderRadius: BorderRadius.circular(16 * s),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 14 * s, offset: Offset(0, 8 * s)),
                        ],
                      ),
                      child: Text(
                        'Tire inspection checkpoints',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18 * s, letterSpacing: .1),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --------------- SPONSORED LABEL + CARDS ---------------
            Positioned(
              left: 14,
              right: 0,
              bottom: 102 + pad.bottom,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _BlueLabel(tabText: 'Sponsored vendors :'),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 206,
                    child: ListView.separated(
                      padding: const EdgeInsets.only(left: 14),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (_, i) {
                        final v = _vendorByMarker.values.elementAt(i);
                        return GestureDetector(
                          onTap: () async {
                            // camera -> vendor
                            final entry = _vendorByMarker.entries.elementAt(i);
                            final pos = _markers.firstWhere((m) => m.markerId == entry.key).position;
                            await _gm?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: pos, zoom: 10.8)));
                            setState(() => _selected = entry.key);
                            await _updateAnchor();
                          },
                          child: _VendorCard(v: v),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemCount: _vendorByMarker.length,
                    ),
                  ),
                ],
              ),
            ),

          
          ],
        ),
      ),
    );
  }

  Widget _roundBtn({required Widget child, VoidCallback? onTap}) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 12, offset: const Offset(0, 8)),
          ],
          border: Border.all(color: const Color(0xFFE9ECF2)),
        ),
        child: Center(child: child),
      ),
    );
  }
}



class _TooltipPositioner extends StatelessWidget {
  const _TooltipPositioner({required this.mapSize, required this.anchor, required this.child});
  final Size mapSize;
  final Offset anchor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const cardW = 250.0;
    const cardH = 140.0;

    final left = (anchor.dx - cardW * .65).clamp(12.0, mapSize.width - cardW - 12.0);
    final top = (anchor.dy - cardH - 22).clamp(80.0, mapSize.height - cardH - 12.0);

    return Positioned(left: left, top: top, child: child);
  }
}

// -------------------- Vendor models & UI --------------------

class VendorLite {
  final String title;
  final String address;
  final double rating;
  final String imageUrl;
  const VendorLite(this.title, this.address, this.rating, this.imageUrl);
}

const _sampleImages = [
  'https://images.unsplash.com/photo-1597764699514-0b46b6a68a07?q=80&w=800&auto=format&fit=crop',
  'https://images.unsplash.com/photo-1603072386510-39ed9e02a9da?q=80&w=1400&auto=format&fit=crop',
  'https://images.unsplash.com/photo-1517048676732-d65bc937f952?q=80&w=1400&auto=format&fit=crop',
  'https://images.unsplash.com/photo-1525609004556-c46c7d6cf023?q=80&w=1400&auto=format&fit=crop',
];

class _VendorTooltipCard extends StatelessWidget {
  const _VendorTooltipCard({required this.vendor});
  final VendorLite vendor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 250,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE9ECF2)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // image
            SizedBox(
              width: 96,
              height: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _netImg(vendor.imageUrl),
                  Positioned(
                    left: 6,
                    top: 6,
                    child: _ratingPill(vendor.rating),
                  )
                ],
              ),
            ),
            // details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vendor.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                    const SizedBox(height: 4),
                    Row(children: const [
                      Icon(Icons.build_circle_rounded, size: 14, color: Color(0xFF6C7A91)),
                      SizedBox(width: 4),
                      Expanded(child: Text('Vehicle inspection service', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.2, color: Color(0xFF6C7A91))))
                    ]),
                    const SizedBox(height: 2),
                    Row(children: const [
                      Icon(Icons.access_time_rounded, size: 14, color: Colors.redAccent),
                      SizedBox(width: 4),
                      Expanded(child: Text('Closed • Opens 9:00', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.2, color: Color(0xFF6C7A91))))
                    ]),
                    const Spacer(),
                    Row(children: [
                      _circleIcon(Icons.call_rounded),
                      const SizedBox(width: 6),
                      _circleIcon(Icons.chat_bubble_rounded),
                      const SizedBox(width: 6),
                      _circleIcon(Icons.navigation_rounded),
                      const Spacer(),
                      const Icon(Icons.more_horiz_rounded, size: 22, color: Color(0xFF9AA1AE)),
                    ])
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  static Widget _circleIcon(IconData icon) => Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(color: Color(0xFFF0F3F9), shape: BoxShape.circle),
        child: Icon(icon, size: 16, color: Color(0xFF5F6C86)),
      );
}

class _VendorCard extends StatelessWidget {
  const _VendorCard({required this.v});
  final VendorLite v;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9ECF2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 122,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)), child: _netImg(v.imageUrl)),
                Positioned(left: 10, top: 10, child: _ratingPill(v.rating)),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.bookmark_border_rounded, size: 18, color: Color(0xFF6C7A91)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(v.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 6),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.place_rounded, size: 16, color: Color(0xFF6C7A91)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(v.address, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Color(0xFF6C7A91))))
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _netImg(String url) {
  return Image.network(
    url,
    fit: BoxFit.cover,
    loadingBuilder: (c, w, p) => p == null
        ? w
        : Container(color: const Color(0xFFF2F4F7), child: const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))),
    errorBuilder: (c, e, s) => Container(
      color: const Color(0xFFF2F4F7),
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported_outlined, color: Color(0xFF9AA1AE)),
    ),
  );
}

Widget _ratingPill(double rating) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
    child: Row(children: [
      const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFB300)),
      const SizedBox(width: 2),
      Text('$rating', style: const TextStyle(fontWeight: FontWeight.w800)),
    ]),
  );
}

// ----------------------------- Blue label ------------------------------
class _BlueLabel extends StatelessWidget {
  const _BlueLabel({required this.tabText});
  final String tabText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F0FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD4E3FF)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: const [
        _Dot(),
        SizedBox(width: 8),
        Text('Sponsored vendors :', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w800, letterSpacing: .2)),
      ]),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) => Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle));
}

