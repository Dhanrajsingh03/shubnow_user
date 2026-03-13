// ==========================================
// 💰 PUJA PRICE MODEL
// ==========================================
// Ye class backend se aane wale nested 'price' object ko handle karegi.
class PujaPrice {
  final double basePrice;
  final double itemsPrice;
  final double platformFee;
  final double withoutSamagriTotal;
  final double withSamagriTotal;

  PujaPrice({
    required this.basePrice,
    required this.itemsPrice,
    required this.platformFee,
    required this.withoutSamagriTotal,
    required this.withSamagriTotal,
  });

  // 🛠️ Safe JSON Parsing: num use karke double me convert kiya hai
  // taaki agar backend se '0' (int) aaye toh app crash na ho.
  factory PujaPrice.fromJson(Map<String, dynamic> json) {
    return PujaPrice(
      basePrice: (json['basePrice'] ?? 0).toDouble(),
      itemsPrice: (json['itemsPrice'] ?? 0).toDouble(),
      platformFee: (json['platformFee'] ?? 0).toDouble(),
      withoutSamagriTotal: (json['withoutSamagriTotal'] ?? 0).toDouble(),
      withSamagriTotal: (json['withSamagriTotal'] ?? 0).toDouble(),
    );
  }

  // 📤 To JSON (Agar future me local storage/cache me save karna ho)
  Map<String, dynamic> toJson() {
    return {
      'basePrice': basePrice,
      'itemsPrice': itemsPrice,
      'platformFee': platformFee,
      'withoutSamagriTotal': withoutSamagriTotal,
      'withSamagriTotal': withSamagriTotal,
    };
  }
}

// ==========================================
// 🪔 MAIN PUJA MODEL
// ==========================================
// Ye class exact tere backend ke getPujaById aur getAllPujas ke
// aggregated response ko map karti hai.
class PujaModel {
  final String id;
  final String name;
  final String title;
  final String description;
  final String image;
  final String duration;
  final String pujaType;

  // 🚦 Availability Flags (Smartly calculated by backend)
  final bool isWithSamagriAvailable;
  final bool isWithoutSamagriAvailable;

  // 💰 Nested Price Object
  final PujaPrice price;

  PujaModel({
    required this.id,
    required this.name,
    required this.title,
    required this.description,
    required this.image,
    required this.duration,
    required this.pujaType,
    required this.isWithSamagriAvailable,
    required this.isWithoutSamagriAvailable,
    required this.price,
  });

  // 🛠️ Factory constructor for building object from API response
  factory PujaModel.fromJson(Map<String, dynamic> json) {
    return PujaModel(
      // MongoDB '_id' ko Flutter ke 'id' me map kar rahe hain
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Puja',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? 'No description available.',
      image: json['image']?.toString() ?? '',
      duration: json['duration']?.toString() ?? 'Duration not specified',
      pujaType: json['pujaType']?.toString() ?? 'regular',

      // Flags parsing
      isWithSamagriAvailable: json['isWithSamagriAvailable'] ?? false,
      isWithoutSamagriAvailable: json['isWithoutSamagriAvailable'] ?? false,

      // Nested Price Object mapping
      price: json['price'] != null
          ? PujaPrice.fromJson(json['price'])
          : PujaPrice( // Default fallback object incase of null
          basePrice: 0,
          itemsPrice: 0,
          platformFee: 0,
          withoutSamagriTotal: 0,
          withSamagriTotal: 0
      ),
    );
  }

  // 📤 To JSON (For SharedPreferences or Local DB caching)
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'title': title,
      'description': description,
      'image': image,
      'duration': duration,
      'pujaType': pujaType,
      'isWithSamagriAvailable': isWithSamagriAvailable,
      'isWithoutSamagriAvailable': isWithoutSamagriAvailable,
      'price': price.toJson(),
    };
  }
}