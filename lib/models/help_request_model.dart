class HelpRequestModel {
  const HelpRequestModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.imageUrl,
    this.price,
    this.latitude,
    this.longitude,
    required this.status,
    this.createdAt,
    this.requesterName,
    this.myPendingResponse = false,
  });

  final String id;
  final String userId;
  final String title;
  final String? description;
  final String? imageUrl;
  final double? price;
  final double? latitude;
  final double? longitude;
  final String status;
  final DateTime? createdAt;
  final String? requesterName;

  /// True when the current user (driver) already has a pending offer on this request.
  final bool myPendingResponse;

  factory HelpRequestModel.fromMap(Map<String, dynamic> map) {
    return HelpRequestModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String? ?? '',
      description: map['description'] as String?,
      imageUrl: map['image_url'] as String?,
      price: (map['price'] as num?)?.toDouble(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      status: map['status'] as String? ?? 'open',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      requesterName: map['requester_name'] as String?,
      myPendingResponse: map['_my_pending'] == true,
    );
  }

  HelpRequestModel copyWith({
    bool? myPendingResponse,
  }) {
    return HelpRequestModel(
      id: id,
      userId: userId,
      title: title,
      description: description,
      imageUrl: imageUrl,
      price: price,
      latitude: latitude,
      longitude: longitude,
      status: status,
      createdAt: createdAt,
      requesterName: requesterName,
      myPendingResponse: myPendingResponse ?? this.myPendingResponse,
    );
  }
}
