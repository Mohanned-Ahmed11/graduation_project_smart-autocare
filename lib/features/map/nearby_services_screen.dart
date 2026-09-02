import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/env.dart';
import '../../providers/app_providers.dart';
import '../../services/places_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/shimmer_box.dart';

class NearbyServicesScreen extends ConsumerStatefulWidget {
  const NearbyServicesScreen({super.key});

  @override
  ConsumerState<NearbyServicesScreen> createState() => _NearbyServicesScreenState();
}

class _NearbyServicesScreenState extends ConsumerState<NearbyServicesScreen> {
  List<PlaceResult> _places = [];
  bool _loading = true;
  LatLng? _center;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await ref.read(locationServiceProvider).ensurePermission();
    final pos = await ref.read(locationServiceProvider).currentPosition();
    if (!mounted) return;
    if (pos == null) {
      setState(() {
        _loading = false;
        _center = const LatLng(30.0444, 31.2357);
        _places = [];
      });
      return;
    }
    final lat = pos.latitude;
    final lng = pos.longitude;
    final next = LatLng(lat, lng);
    setState(() => _center = next);
    await _mapController?.animateCamera(CameraUpdate.newLatLngZoom(next, 13));

    if (Env.effectivePlacesKey.isEmpty) {
      setState(() {
        _places = [];
        _loading = false;
      });
      return;
    }

    final places = await ref.read(placesServiceProvider).nearbyCarRepair(
          lat: lat,
          lng: lng,
        );
    if (!mounted) return;
    setState(() {
      _places = places;
      _loading = false;
    });
  }

  Set<Marker> get _markers {
    if (_center == null) return {};
    final set = <Marker>{
      Marker(
        markerId: const MarkerId('me'),
        position: _center!,
        infoWindow: const InfoWindow(title: 'You'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    };
    for (final p in _places) {
      set.add(
        Marker(
          markerId: MarkerId(p.id),
          position: LatLng(p.lat, p.lng),
          infoWindow: InfoWindow(title: p.name),
        ),
      );
    }
    return set;
  }

  Future<void> _openNav(PlaceResult p) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${p.lat},${p.lng}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _recenter() async {
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final scheme = Theme.of(context).colorScheme;

    if (Env.googleMapsApiKey.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Nearby services'),
          backgroundColor: scheme.surface.withValues(alpha: 0.92),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GlassCard(
              borderRadius: 24,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 52, color: AppColors.primary.withValues(alpha: 0.65)),
                  const SizedBox(height: 20),
                  Text(
                    'Maps key required',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Add GOOGLE_MAPS_API_KEY to your .env and rebuild the app so Android can load map tiles.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.6),
                          height: 1.4,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby services'),
        backgroundColor: scheme.surface.withValues(alpha: 0.92),
        actions: [
          IconButton.filledTonal(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final mapHeight = (constraints.maxHeight * 0.36).clamp(200.0, 320.0);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: mapHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_center != null)
                      Positioned.fill(
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(target: _center!, zoom: 13),
                          onMapCreated: (c) {
                            _mapController = c;
                            c.animateCamera(CameraUpdate.newLatLngZoom(_center!, 13));
                          },
                          markers: _markers,
                          mapType: MapType.normal,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                          compassEnabled: true,
                          liteModeEnabled: false,
                          padding: const EdgeInsets.only(top: 8, right: 8, bottom: 12),
                        ),
                      )
                    else
                      const ColoredBox(
                        color: Color(0xFFE8E4DC),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Material(
                        elevation: 2,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: _recenter,
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(Icons.my_location_rounded),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? ListView(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
                        children: const [
                          ShimmerBox(height: 96, borderRadius: 22),
                          SizedBox(height: 12),
                          ShimmerBox(height: 96, borderRadius: 22),
                          SizedBox(height: 12),
                          ShimmerBox(height: 96, borderRadius: 22),
                        ],
                      )
                    : RefreshIndicator(
                        edgeOffset: 8,
                        onRefresh: _load,
                        child: _places.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.fromLTRB(20, 24, 20, 24 + bottom),
                                children: [
                                  GlassCard(
                                    borderRadius: 24,
                                    padding: const EdgeInsets.all(28),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Env.effectivePlacesKey.isEmpty
                                              ? Icons.key_off_rounded
                                              : Icons.search_off_rounded,
                                          size: 48,
                                          color: AppColors.primary.withValues(alpha: 0.55),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          Env.effectivePlacesKey.isEmpty
                                              ? 'Places API key missing'
                                              : 'No repair shops found nearby',
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          Env.effectivePlacesKey.isEmpty
                                              ? 'Set PLACES_API_KEY (or reuse your Maps key with Places API enabled) in .env.'
                                              : 'Try refreshing or zooming out on the map.',
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: scheme.onSurface.withValues(alpha: 0.58),
                                                height: 1.4,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.fromLTRB(16, 14, 16, 20 + bottom),
                                itemCount: _places.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemBuilder: (context, i) {
                                  final p = _places[i];
                                  return _NearbyPlaceCard(
                                    place: p,
                                    onDirections: () => _openNav(p),
                                  );
                                },
                              ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NearbyPlaceCard extends StatelessWidget {
  const _NearbyPlaceCard({
    required this.place,
    required this.onDirections,
  });

  final PlaceResult place;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rating = place.rating;

    return GlassCard(
      borderRadius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.2),
                      AppColors.secondary.withValues(alpha: 0.12),
                    ],
                  ),
                ),
                child: const Icon(Icons.car_repair_rounded, color: AppColors.primary, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            height: 1.25,
                          ),
                    ),
                    if (place.address != null && place.address!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        place.address!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.58),
                              height: 1.35,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (rating != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.secondary.withValues(alpha: 0.14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 18, color: AppColors.secondary.darken()),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: onDirections,
              icon: const Icon(Icons.directions_outlined),
              label: const Text('Directions'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension on Color {
  Color darken([double amount = .08]) {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness(math.max(0, hsl.lightness - amount)).toColor();
  }
}
