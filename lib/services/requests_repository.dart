import 'dart:math' as math;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/help_request_model.dart';
import '../models/request_response_item.dart';

double? _haversineKm(double? lat1, double? lon1, double? lat2, double? lon2) {
  if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) return null;
  const r = 6371.0;
  double rad(double d) => d * math.pi / 180.0;
  final dLat = rad(lat2 - lat1);
  final dLon = rad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2);
  return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

class RequestsRepository {
  RequestsRepository(this._client);

  final SupabaseClient _client;

  Future<List<HelpRequestModel>> listOpen() async {
    final rows = await _client
        .from('requests')
        .select()
        .eq('status', 'open')
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => HelpRequestModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<HelpRequestModel>> listForUser(String userId) async {
    final rows = await _client
        .from('requests')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => HelpRequestModel.fromMap(
            Map<String, dynamic>.from(e as Map)..remove('profiles')))
        .toList();
  }

  /// Open + requester's non-open + requests this user accepted as driver + requests with pending interest.
  Future<List<HelpRequestModel>> listOpenAndMine(String userId) async {
    final open = await listOpen();
    final mine = await listForUser(userId);
    final rr = await _client
        .from('request_responses')
        .select('request_id')
        .eq('driver_id', userId)
        .eq('status', 'accepted');
    final acceptedIds = (rr as List)
        .map((e) => (e as Map<String, dynamic>)['request_id'] as String)
        .toList();
    var driverAccepted = <HelpRequestModel>[];
    if (acceptedIds.isNotEmpty) {
      final rows =
          await _client.from('requests').select().inFilter('id', acceptedIds);
      driverAccepted = (rows as List)
          .map((e) =>
              HelpRequestModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    final rrPen = await _client
        .from('request_responses')
        .select('request_id')
        .eq('driver_id', userId)
        .eq('status', 'pending');
    final pendingIds = (rrPen as List)
        .map((e) => (e as Map<String, dynamic>)['request_id'] as String)
        .toList();
    var driverPending = <HelpRequestModel>[];
    if (pendingIds.isNotEmpty) {
      final rows =
          await _client.from('requests').select().inFilter('id', pendingIds);
      driverPending = (rows as List)
          .map((e) =>
              HelpRequestModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    final tracked = {for (final r in open) r.id: r};
    for (final r in mine) {
      if (r.status != 'open') tracked[r.id] = r;
    }
    for (final r in driverAccepted) {
      tracked[r.id] = r;
    }
    for (final r in driverPending) {
      tracked[r.id] = r;
    }
    final pendingSet = pendingIds.toSet();
    final list = tracked.values.toList()
      ..sort((a, b) => (b.createdAt ?? DateTime(1970))
          .compareTo(a.createdAt ?? DateTime(1970)));
    return list
        .map((r) => r.copyWith(myPendingResponse: pendingSet.contains(r.id)))
        .toList();
  }

  Future<HelpRequestModel> create({
    required String userId,
    required String title,
    String? description,
    String? imageUrl,
    double? price,
    double? lat,
    double? lng,
  }) async {
    final row = await _client
        .from('requests')
        .insert({
          'user_id': userId,
          'title': title,
          'description': description,
          'image_url': imageUrl,
          'price': price,
          'latitude': lat,
          'longitude': lng,
          'status': 'open',
        })
        .select()
        .single();
    return HelpRequestModel.fromMap(Map<String, dynamic>.from(row));
  }

  Future<void> updateStatus(String requestId, String status) async {
    await _client.from('requests').update({'status': status}).eq('id', requestId);
  }

  /// Deletes the request if RLS allows (owner only). Cascades responses and chat.
  Future<void> deleteRequest(String requestId) async {
    await _client.from('requests').delete().eq('id', requestId);
  }

  Future<String?> findChatIdForRequest(String requestId) async {
    final row = await _client
        .from('chats')
        .select('id')
        .eq('request_id', requestId)
        .maybeSingle();
    return row?['id'] as String?;
  }

  Future<String> ensureChat(String requestId) async {
    final existing = await findChatIdForRequest(requestId);
    if (existing != null) return existing;
    final row = await _client
        .from('chats')
        .insert({'request_id': requestId})
        .select('id')
        .single();
    return row['id'] as String;
  }

  /// Driver offers help; row stays **pending** until the requester accepts.
  Future<void> submitInterestAsDriver({
    required String requestId,
    required String driverId,
  }) async {
    await _client.from('request_responses').insert({
      'request_id': requestId,
      'driver_id': driverId,
      'status': 'pending',
    });
  }

  /// Counts pending `request_responses` per request id (for requester badges).
  Future<Map<String, int>> pendingOfferCountsForRequests(List<String> requestIds) async {
    if (requestIds.isEmpty) return {};
    final rows = await _client
        .from('request_responses')
        .select('request_id')
        .inFilter('request_id', requestIds)
        .eq('status', 'pending');
    final map = <String, int>{};
    for (final row in rows as List) {
      final id = (row as Map<String, dynamic>)['request_id'] as String;
      map[id] = (map[id] ?? 0) + 1;
    }
    return map;
  }

  /// Pending responses for a request (requester only; RLS restricts reads).
  Future<List<RequestResponseItem>> listPendingResponses(String requestId) async {
    final req = await _client
        .from('requests')
        .select('latitude, longitude')
        .eq('id', requestId)
        .maybeSingle();
    final reqLat = (req?['latitude'] as num?)?.toDouble();
    final reqLng = (req?['longitude'] as num?)?.toDouble();

    final rows = await _client
        .from('request_responses')
        .select('id, driver_id, status, created_at')
        .eq('request_id', requestId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    final list = (rows as List)
        .map((e) => RequestResponseItem.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    final ids = list.map((e) => e.driverId).toSet().toList();
    if (ids.isEmpty) return list;
    final prof = await _client
        .from('profiles')
        .select('id, name, latitude, longitude')
        .inFilter('id', ids);
    final profileById = <String, Map<String, dynamic>>{};
    for (final row in prof as List) {
      final m = Map<String, dynamic>.from(row as Map);
      profileById[m['id'] as String] = m;
    }
    return list.map((e) {
      final profRow = profileById[e.driverId];
      final dLat = (profRow?['latitude'] as num?)?.toDouble();
      final dLng = (profRow?['longitude'] as num?)?.toDouble();
      return RequestResponseItem(
        id: e.id,
        driverId: e.driverId,
        status: e.status,
        createdAt: e.createdAt,
        driverName: profRow?['name'] as String? ?? e.driverName,
        driverLatitude: dLat,
        driverLongitude: dLng,
        distanceKmFromRequest: _haversineKm(reqLat, reqLng, dLat, dLng),
      );
    }).toList();
  }

  /// Requester picks one driver; other pending rows are removed; chat is created.
  Future<void> acceptResponseAsRequester({
    required String responseId,
    required String requesterUserId,
  }) async {
    final rr = await _client
        .from('request_responses')
        .select('request_id, status')
        .eq('id', responseId)
        .single();
    final rid = rr['request_id'] as String;
    if (rr['status'] != 'pending') {
      throw Exception('This offer is no longer pending.');
    }
    final req = await _client.from('requests').select('user_id').eq('id', rid).single();
    if (req['user_id'] != requesterUserId) {
      throw Exception('Only the request owner can accept an offer.');
    }

    await _client
        .from('request_responses')
        .delete()
        .eq('request_id', rid)
        .eq('status', 'pending')
        .neq('id', responseId);

    await _client
        .from('request_responses')
        .update({'status': 'accepted'})
        .eq('id', responseId);

    await updateStatus(rid, 'accepted');
    await ensureChat(rid);
  }

  /// @deprecated Use [submitInterestAsDriver] + [acceptResponseAsRequester].
  Future<void> acceptAsDriver({
    required String requestId,
    required String driverId,
  }) async {
    await submitInterestAsDriver(requestId: requestId, driverId: driverId);
  }
}
