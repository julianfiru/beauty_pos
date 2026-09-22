class ServiceItem {
  final int? id;
  final String name;
  final String category;
  final double price;
  final int durationMinutes;
  final String? description;
  final String? imageUrl;
  final String createdAt;

  ServiceItem({
    this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.durationMinutes,
    this.description,
    this.imageUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'category': category,
      'price': price,
      'durationMinutes': durationMinutes,
      'description': description,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
    };
  }

  factory ServiceItem.fromMap(Map<String, dynamic> map) {
    return ServiceItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String,
      price: (map['price'] as num).toDouble(),
      durationMinutes: map['durationMinutes'] as int,
      description: map['description'] as String?,
      imageUrl: map['imageUrl'] as String?,
      createdAt: map['createdAt'] as String,
    );
  }

  ServiceItem copyWith({
    int? id,
    String? name,
    String? category,
    double? price,
    int? durationMinutes,
    String? description,
    String? imageUrl,
    String? createdAt,
  }) {
    return ServiceItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
