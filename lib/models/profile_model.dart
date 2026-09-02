class ProfileModel {
  const ProfileModel({
    required this.id,
    this.name,
    this.phone,
    this.carModel,
    this.profileImage,
    this.latitude,
    this.longitude,
    this.createdAt,
  });

  final String id;
  final String? name;
  final String? phone;
  final String? carModel;
  final String? profileImage;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'] as String,
      name: map['name'] as String?,
      phone: map['phone'] as String?,
      carModel: map['car_model'] as String?,
      profileImage: map['profile_image'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toUpdateMap() => {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (carModel != null) 'car_model': carModel,
        if (profileImage != null) 'profile_image': profileImage,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };
}
