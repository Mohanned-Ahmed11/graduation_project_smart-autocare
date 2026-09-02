import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/config/env.dart';
import '../../models/help_request_model.dart';
import '../../providers/app_providers.dart';
import '../../providers/my_requests_provider.dart';
import '../../providers/open_requests_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/offer_price_format.dart';
import '../../widgets/glass_card.dart';
import 'request_review_offers_dialog.dart';

class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});

  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen> {
  LatLng? _userPos;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loc();
  }

  Future<void> _loc() async {
    await ref.read(locationServiceProvider).ensurePermission();
    final p = await ref.read(locationServiceProvider).currentPosition();
    if (!mounted || p == null) return;
    final next = LatLng(p.latitude, p.longitude);
    setState(() => _userPos = next);
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(next, 12),
    );
  }

  Future<void> _recenterOnMe() async {
    await _loc();
  }

  double? _distanceKm(HelpRequestModel r) {
    if (_userPos == null || r.latitude == null || r.longitude == null) {
      return null;
    }
    final m = Geolocator.distanceBetween(
      _userPos!.latitude,
      _userPos!.longitude,
      r.latitude!,
      r.longitude!,
    );
    return m / 1000;
  }

  Set<Marker> _markers(List<HelpRequestModel> list) {
    final set = <Marker>{};
    if (_userPos != null) {
      set.add(
        Marker(
          markerId: const MarkerId('me'),
          position: _userPos!,
          infoWindow: const InfoWindow(title: 'You'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }
    for (final r in list) {
      if (r.latitude == null || r.longitude == null) continue;
      set.add(
        Marker(
          markerId: MarkerId(r.id),
          position: LatLng(r.latitude!, r.longitude!),
          infoWindow: InfoWindow(title: r.title),
        ),
      );
    }
    return set;
  }

  Future<void> _submitInterest(HelpRequestModel r) async {
    final user = ref.read(authUserProvider).valueOrNull;
    if (user == null || user.id == r.userId) return;
    try {
      final repo = ref.read(requestsRepositoryProvider);
      await repo.submitInterestAsDriver(
        requestId: r.id,
        driverId: user.id,
      );
      final chatId = await repo.ensureChat(r.id);
      ref.invalidate(requestsFeedProvider);
      ref.invalidate(openRequestsProvider);
      ref.invalidate(myRequestsProvider);
      ref.invalidate(myRequestPendingCountsProvider);
      if (!mounted) return;
      context.push('/chat/$chatId?requestId=${r.id}');
    } catch (e) {
      if (!mounted) return;
      final msg = '$e';
      final duplicate = msg.contains('23505') || msg.toLowerCase().contains('duplicate');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            duplicate ? 'You already sent an offer for this request.' : msg,
          ),
        ),
      );
    }
  }

  Future<void> _reviewOffers(HelpRequestModel r) async {
    await openRequestReviewOffersDialog(context, ref, r);
  }

  Future<void> _openChat(HelpRequestModel r) async {
    final chatId =
        await ref.read(requestsRepositoryProvider).findChatIdForRequest(r.id);
    if (!mounted) return;
    if (chatId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No chat yet — accept the request first.')),
      );
      return;
    }
    context.push('/chat/$chatId?requestId=${r.id}');
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(requestsFeedProvider);
    final user = ref.watch(authUserProvider).valueOrNull;

    if (Env.googleMapsApiKey.isEmpty) {
      final pad = MediaQuery.paddingOf(context);
      return Scaffold(
        appBar: AppBar(
          title: const Text('Help requests'),
          backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
          actions: [
            IconButton(
              tooltip: 'My requests',
              icon: const Icon(Icons.list_alt_rounded),
              onPressed: () => context.push('/requests/mine'),
            ),
          ],
        ),
        body: async.when(
          data: (list) => ListView.builder(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + pad.bottom),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final r = list[i];
              final owner = user?.id == r.userId;
              return _RequestTile(
                r: r,
                distanceKm: _distanceKm(r),
                isOwner: owner,
                onInterest: (!owner && r.status == 'open' && !r.myPendingResponse)
                    ? () => _submitInterest(r)
                    : null,
                onReviewOffers: (owner && r.status == 'open') ? () => _reviewOffers(r) : null,
                onChat: () => _openChat(r),
              );
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
        ),
      );
    }

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: const Text('Help requests'),
        backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
        actions: [
          IconButton(
            tooltip: 'My requests',
            icon: const Icon(Icons.list_alt_rounded),
            onPressed: () => context.push('/requests/mine'),
          ),
        ],
      ),
      body: async.when(
        data: (list) {
          final initial = _userPos ?? const LatLng(30.0444, 31.2357);
          return LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(target: initial, zoom: 11),
                      onMapCreated: (c) {
                        _mapController = c;
                        if (_userPos != null) {
                          c.animateCamera(
                            CameraUpdate.newLatLngZoom(_userPos!, 12),
                          );
                        }
                      },
                      markers: _markers(list),
                      mapType: MapType.normal,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      compassEnabled: true,
                      liteModeEnabled: false,
                      padding: EdgeInsets.only(
                        top: 8,
                        bottom: constraints.maxHeight * 0.32 + bottomInset,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 12,
                    child: Material(
                      elevation: 2,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: _recenterOnMe,
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.my_location_rounded),
                        ),
                      ),
                    ),
                  ),
                  DraggableScrollableSheet(
                    initialChildSize: 0.30,
                    minChildSize: 0.22,
                    maxChildSize: 0.88,
                    snap: true,
                    snapSizes: const [0.30, 0.55, 0.88],
                    builder: (context, scrollController) {
                      return SafeArea(
                        top: false,
                        minimum: EdgeInsets.zero,
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: 10,
                            right: 10,
                            bottom: bottomInset > 0 ? bottomInset : 8,
                          ),
                          child: GlassCard(
                            borderRadius: 24,
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              children: [
                                Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                                  child: Text(
                                    'Open requests',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                                Expanded(
                                  child: ListView.builder(
                                    controller: scrollController,
                                    physics: const ClampingScrollPhysics(),
                                    padding: EdgeInsets.fromLTRB(
                                      12,
                                      0,
                                      12,
                                      12 + bottomInset,
                                    ),
                                    itemCount: list.length,
                                    itemBuilder: (context, i) {
                                      final r = list[i];
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: _RequestTile(
                                          r: r,
                                          distanceKm: _distanceKm(r),
                                          isOwner: user?.id == r.userId,
                                          onInterest: (user?.id != r.userId &&
                                                  r.status == 'open' &&
                                                  !r.myPendingResponse)
                                              ? () => _submitInterest(r)
                                              : null,
                                          onReviewOffers:
                                              (user?.id == r.userId && r.status == 'open')
                                                  ? () => _reviewOffers(r)
                                                  : null,
                                          onChat: () => _openChat(r),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('$e'))),
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({
    required this.r,
    required this.distanceKm,
    required this.isOwner,
    required this.onChat,
    this.onInterest,
    this.onReviewOffers,
  });

  final HelpRequestModel r;
  final double? distanceKm;
  final bool isOwner;
  final VoidCallback? onInterest;
  final VoidCallback? onReviewOffers;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    final priceLabel = formatOfferPriceLe(r.price);

    return Material(
      color: Colors.transparent,
      child: GlassCard(
        borderRadius: 20,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.16),
                        AppColors.secondary.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                  child: const Icon(Icons.handshake_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    r.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          height: 1.25,
                        ),
                  ),
                ),
                if (priceLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.primary.withValues(alpha: 0.12),
                    ),
                    child: Text(
                      priceLabel,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
              ],
            ),
            if (r.description != null && r.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  r.description!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (distanceKm != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${distanceKm!.toStringAsFixed(1)} km away',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.start,
              children: [
                if (onInterest != null)
                  FilledButton(
                    onPressed: onInterest,
                    style: FilledButton.styleFrom(backgroundColor: AppColors.secondary),
                    child: const Text("I'm interested"),
                  ),
                if (!isOwner && r.status == 'open' && r.myPendingResponse)
                  FilledButton.icon(
                    onPressed: onChat,
                    icon: const Icon(Icons.chat_bubble_rounded, size: 20),
                    label: const Text('Open chat'),
                  ),
                if (onReviewOffers != null)
                  OutlinedButton(
                    onPressed: onReviewOffers,
                    child: const Text('Review offers'),
                  ),
                if (r.status == 'accepted')
                  OutlinedButton(
                    onPressed: onChat,
                    child: const Text('Chat'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
