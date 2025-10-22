import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tire_testai/Screens/home_screen.dart';
import 'package:tire_testai/Screens/report_history_screen.dart';

/// Google Maps version with random USA markers + anchored tooltip.
/// Starts with the first marker selected (to match your "first tooltip" mock).
class LocationVendorsMapScreen extends StatefulWidget {
  const LocationVendorsMapScreen({super.key, this.showFirstTooltipOnLoad = true});
  final bool showFirstTooltipOnLoad;

  @override
  State<LocationVendorsMapScreen> createState() => _LocationVendorsMapScreenState();
}

class _LocationVendorsMapScreenState extends State<LocationVendorsMapScreen> {
  final GlobalKey _mapStackKey = GlobalKey();

  GoogleMapController? _gm;
  static const _usaCenter = LatLng(39.8283, -98.5795); // continental US centroid
  static const _initialZoom = 4.5;

  // app data
  final Map<MarkerId, VendorLite> _vendorByMarker = {};
  final Set<Marker> _markers = {};

  MarkerId? _selected;
  Offset? _selectedScreenPx; // anchor position in map widget coordinates

  @override
  void initState() {
    super.initState();
    _seedRandomMarkers(8); // generate a handful randomly
    if (widget.showFirstTooltipOnLoad && _markers.isNotEmpty) {
      // Select first marker after a short delay (map must be created to compute screen px)
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final first = _markers.first.markerId;
        setState(() => _selected = first);
        await _updateAnchor();
      });
    }
  }

  // ----- Random USA positions -------------------------------------------------
  // Rough bounding box of continental US (not excluding water – good enough for demo)
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
    final r = math.Random();
    for (var i = 0; i < count; i++) {
      final pos = _randomUsaLatLng(r);
      final id = MarkerId('m$i');
      final rating = (3.2 + r.nextDouble() * 1.6); // 3.2..4.8
      final v = VendorLite(
        i.isEven ? 'U.S. Auto Inspection' : 'National Tyres And Autocare',
        i.isEven ? 'Service • USA' : 'Broomall Road, Leyland PR25 3ZE',
        double.parse(rating.toStringAsFixed(1)),
        _sampleImages[i % _sampleImages.length],
      );
      _vendorByMarker[id] = v;

      _markers.add(
        Marker(
          markerId: id,
          position: pos,
          onTap: () async {
            setState(() => _selected = id);
            await _updateAnchor();
          },
        ),
      );
    }
  }

  // Convert the selected LatLng to screen (pixel) coordinates for our overlay
  Future<void> _updateAnchor() async {
    if (_gm == null || _selected == null) return;
    final latLng = _markers.firstWhere((m) => m.markerId == _selected).position;
    final sc = await _gm!.getScreenCoordinate(latLng);
    // getScreenCoordinate gives top-left of GoogleMap; fits our Stack child exactly.
    setState(() => _selectedScreenPx = Offset(sc.x.toDouble(), sc.y.toDouble()));
  }

  @override
  Widget build(BuildContext context) {
    final padB = MediaQuery.of(context).padding.bottom;
final s = MediaQuery.sizeOf(context).width / 390.0;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FA),
      body: SafeArea(
        child: Stack(
          key: _mapStackKey,
          children: [
            // ------------------ Column: header + map + list ------------------
            Positioned.fill(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                     SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(12 * s, 8 * s, 12 * s, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 32),
                  ),
                  Expanded(
                    child: Text('Tire inspection checkpoints',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'ClashGrotesk',
                          fontWeight: FontWeight.w800,
                          fontSize: 20 * s,
                          color: Colors.white,
                          shadows: const [Shadow(color: Colors.black54, blurRadius: 8)],
                        )),
                  ),
                  const SizedBox(width: 46), // balance back button space
                ],
              ),
            ),
          ),

                /*  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        _roundBtn(
                          onTap: () => Navigator.maybePop(context),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 18, color: Colors.black87),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Tire inspection checkpoints',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 20,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),*/
                  const SizedBox(height: 10),

                  // ------------------------ Google Map ------------------------
                  Expanded(
                    child: LayoutBuilder(
                      builder: (ctx, c) {
                        final mapW = c.maxWidth;
                        final mapH = c.maxHeight;

                        return Stack(
                          children: [
                            GoogleMap(
                              initialCameraPosition: const CameraPosition(
                                target: _usaCenter,
                                zoom: _initialZoom,
                              ),
                              onMapCreated: (ctrl) async {
                                _gm = ctrl;
                                // If a marker is preselected, place tooltip
                                await _updateAnchor();
                              },
                              onTap: (_) => setState(() {
                                _selected = null;
                                _selectedScreenPx = null;
                              }),
                              onCameraIdle: _updateAnchor,
                              onCameraMove: (_) {
                                // reset while panning; anchor will update on idle
                                if (_selected != null) {
                                  setState(() => _selectedScreenPx = null);
                                }
                              },
                              markers: _markers,
                              myLocationButtonEnabled: false,
                              myLocationEnabled: false,
                              zoomControlsEnabled: false,
                              compassEnabled: false,
                              mapToolbarEnabled: false,
                              buildingsEnabled: false,
                              trafficEnabled: false,
                              liteModeEnabled: false,
                            ),

                            // -------- custom tooltip anchored to selected marker
                            if (_selected != null && _selectedScreenPx != null)
                              _TooltipPositioner(
                                mapSize: Size(mapW, mapH),
                                anchor: _selectedScreenPx!,
                                child: _VendorTooltipCard(
                                  vendor: _vendorByMarker[_selected]!,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(children: const [ _BlueLabel(tabText: 'Sponsored vendors') ]),
                  ),
                  const SizedBox(height: 8),

                  SizedBox(
                    height: 190,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      scrollDirection: Axis.horizontal,
                      itemCount: _vendorByMarker.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) {
                        final v = _vendorByMarker.values.elementAt(i);
                        return _VendorCard(v: v);
                      },
                    ),
                  ),

                  SizedBox(height: 88 + padB),
                ],
              ),
            ),

             Align(
  alignment: Alignment.bottomCenter,
  child: SafeArea(
    top: false,
    child: Padding(
      padding: EdgeInsets.fromLTRB(16 * s, 0, 16 * s, 8 * s),
      child: _BottomBar(s: s, active: BottomTab.map),
    ),
  ),
),
   

            // --------------------- Bottom navigation (Location active)
            // Positioned(
            //   left: 16,
            //   right: 16,
            //   bottom: 2 + padB,
            //   child: _BottomBar(s: s, active: BottomTab.map),
            // ),
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
            BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: const Color(0xFFE9ECF2)),
        ),
        child: Center(child: child),
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
        Navigator.push(ctx, MaterialPageRoute(builder: (ctx)=> LocationVendorsMapScreen()));
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
/* -------------------- Tooltip positioner (keeps card on screen) -------------------- */
class _TooltipPositioner extends StatelessWidget {
  const _TooltipPositioner({
    required this.mapSize,
    required this.anchor,
    required this.child,
  });

  final Size mapSize;
  final Offset anchor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const cardW = 250.0;
    const cardH = 140.0;

    // place above-left of the anchor
    final left = (anchor.dx - cardW * .65)
        .clamp(12.0, mapSize.width - cardW - 12.0);
    final top = (anchor.dy - cardH - 22)
        .clamp(80.0, mapSize.height - cardH - 12.0);

    return Positioned(left: left, top: top, child: child);
  }
}

/* ----------------------------- Vendor models & UI ------------------------------ */

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
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE9ECF2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // image
            SizedBox(
              width: 90,
              height: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(vendor.imageUrl, fit: BoxFit.cover),
                  Positioned(
                    left: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB300)),
                          const SizedBox(width: 2),
                          Text('${vendor.rating}',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            // details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vendor.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                        )),
                    const SizedBox(height: 2),
                    Row(
                      children: const [
                        Icon(Icons.build_circle_rounded, size: 14, color: Color(0xFF6C7A91)),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text('Vehicle inspection service',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12.2, color: Color(0xFF6C7A91))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: const [
                        Icon(Icons.access_time_rounded, size: 14, color: Colors.redAccent),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text('Closed • Opens 9:00',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12.2, color: Color(0xFF6C7A91))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '“… best inspection service and excellent customer service.”',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.2, color: Color(0xFF6C7A91)),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        _circleIcon(Icons.call_rounded),
                        const SizedBox(width: 6),
                        _circleIcon(Icons.chat_bubble_rounded),
                        const SizedBox(width: 6),
                        _circleIcon(Icons.navigation_rounded),
                        const Spacer(),
                        const Icon(Icons.more_horiz_rounded, size: 22, color: Color(0xFF9AA1AE)),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _circleIcon(IconData icon) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(color: Color(0xFFF0F3F9), shape: BoxShape.circle),
      child: Icon(icon, size: 16, color: Color(0xFF5F6C86)),
    );
  }
}

class _VendorCard extends StatelessWidget {
  const _VendorCard({required this.v});
  final VendorLite v;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9ECF2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 106,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(v.imageUrl, fit: BoxFit.cover),
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFB300)),
                        const SizedBox(width: 2),
                        Text('${v.rating}', style: const TextStyle(fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 26, height: 26,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.bookmark_border_rounded, size: 18, color: Color(0xFF6C7A91)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(v.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                const SizedBox(height: 4),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.place_rounded, size: 16, color: Color(0xFF6C7A91)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(v.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF6C7A91))),
                  ),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/* ----------------------------- Blue label ------------------------------ */
class _BlueLabel extends StatelessWidget {
  const _BlueLabel({required this.tabText});
  final String tabText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F0FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD4E3FF)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: const [
        _Dot(),
        SizedBox(width: 8),
        Text('Sponsored vendors :',
            style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w800, letterSpacing: .2)),
      ]),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) =>
      Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle));
}


