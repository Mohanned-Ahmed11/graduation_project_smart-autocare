class RequestResponseItem {
  const RequestResponseItem({
    required this.id,
    required this.driverId,
    required this.status,
    this.createdAt,
    this.driverName,
    this.driverLatitude,
    this.driverLongitude,
    this.distanceKmFromRequest,
  });

  final String id;
  final String driverId;
  final String status;
  final DateTime? createdAt;
  final String? driverName;
  final double? driverLatitude;
  final double? driverLongitude;

  /// Haversine distance from the help request pin to the driver's last known profile location.
  final double? distanceKmFromRequest;

  factory RequestResponseItem.fromMap(Map<String, dynamic> map) {
    String? name;
    final p = map['profiles'];
    if (p is Map) {
      name = p['name'] as String?;
    }
    return RequestResponseItem(
      id: map['id'] as String,
      driverId: map['driver_id'] as String,
      status: map['status'] as String? ?? 'pending',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      driverName: name,
      driverLatitude: (map['driver_latitude'] as num?)?.toDouble(),
      driverLongitude: (map['driver_longitude'] as num?)?.toDouble(),
      distanceKmFromRequest: (map['distance_km_from_request'] as num?)?.toDouble(),
    );
  }
}
