// lib/models/profile_model.dart

class AddressModel {
  final String id;
  final String addressType; // Home, Office, Other
  final String houseNo;
  final String street;
  final String landmark;
  final String city;
  final String district;
  final String state;
  final String pincode;
  final bool isDefault;
  final double lat;
  final double lng;

  AddressModel({
    required this.id, required this.addressType, required this.houseNo, required this.street,
    required this.landmark, required this.city, required this.district, required this.state,
    required this.pincode, required this.isDefault, required this.lat, required this.lng,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    // Backend bhejta hai: { type: "Point", coordinates: [lng, lat] }
    double lng = 0.0;
    double lat = 0.0;
    if (json['location'] != null && json['location']['coordinates'] != null) {
      lng = (json['location']['coordinates'][0] as num).toDouble();
      lat = (json['location']['coordinates'][1] as num).toDouble();
    }

    return AddressModel(
      id: json['_id'] ?? '',
      addressType: json['addressType'] ?? 'Home',
      houseNo: json['houseNo'] ?? '',
      street: json['street'] ?? '',
      landmark: json['landmark'] ?? '',
      city: json['city'] ?? '',
      district: json['district'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      isDefault: json['isDefault'] ?? false,
      lat: lat,
      lng: lng,
    );
  }
}

class ProfileModel {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String avatar;
  final bool isVerified;
  final List<AddressModel> addresses;

  ProfileModel({
    required this.id, required this.fullName, required this.email,
    required this.phoneNumber, required this.avatar, required this.isVerified,
    required this.addresses,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    var addressList = json['addresses'] as List? ?? [];
    List<AddressModel> parsedAddresses = addressList.map((i) => AddressModel.fromJson(i)).toList();

    return ProfileModel(
      id: json['_id'] ?? '',
      fullName: json['fullName'] ?? 'Devotee',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      avatar: json['avatar'] ?? 'https://res.cloudinary.com/demo/image/upload/v1625647731/avatar_placeholder.png',
      isVerified: json['isVerified'] ?? false,
      addresses: parsedAddresses,
    );
  }
}