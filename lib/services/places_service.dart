import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/env.dart';

class PlaceResult {
  PlaceResult({
    required this.id,
    required this.name,
    this.address,
    this.rating,
    this.userRatingsTotal,
    required this.lat,
    required this.lng,
    this.openNow,
  });

  final String id;
  final String name;
  final String? address;
  final double? rating;
  final int? userRatingsTotal;
  final double lat;
  final double lng;
  final bool? openNow;
}

class PlacesService {
  String get _key => Env.effectivePlacesKey;

  Future<List<PlaceResult>> nearbyCarRepair({
    required double lat,
    required double lng,
    int radiusMeters = 8000,
  }) async {
    if (_key.isEmpty) return [];
    final url = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/nearbysearch/json',
      {
        'location': '$lat,$lng',
        'radius': '$radiusMeters',
        'type': 'car_repair',
        'key': _key,
      },
    );
    final res = await http.get(url);
    if (res.statusCode != 200) return [];
    final body = json.decode(res.body) as Map<String, dynamic>;
    if (body['status'] != 'OK' && body['status'] != 'ZERO_RESULTS') {
      return [];
    }
    final results = body['results'] as List<dynamic>? ?? [];
    return results.map((e) {
      final m = e as Map<String, dynamic>;
      final loc = m['geometry']?['location'] as Map<String, dynamic>?;
      return PlaceResult(
        id: m['place_id'] as String? ?? '',
        name: m['name'] as String? ?? 'Unknown',
        address: m['vicinity'] as String? ?? m['formatted_address'] as String?,
        rating: (m['rating'] as num?)?.toDouble(),
        userRatingsTotal: m['user_ratings_total'] as int?,
        lat: (loc?['lat'] as num?)?.toDouble() ?? lat,
        lng: (loc?['lng'] as num?)?.toDouble() ?? lng,
        openNow: m['opening_hours']?['open_now'] as bool?,
      );
    }).toList();
  }
}
