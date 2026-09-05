class Product {
  final int? id;
  final String name;
  final String category;
  final double price;
  final double costPrice;
  final int stock;
  final String? barcode;
  final String? imageUrl;
  final String createdAt;

  Product({
    this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.costPrice,
    required this.stock,
    this.barcode,
    this.imageUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'category': category,
      'price': price,
      'costPrice': costPrice,
      'stock': stock,
      'barcode': barcode,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String,
      price: (map['price'] as num).toDouble(),
      costPrice: (map['costPrice'] as num).toDouble(),
      stock: map['stock'] as int,
      barcode: map['barcode'] as String?,
      imageUrl: map['imageUrl'] as String?,
      createdAt: map['createdAt'] as String,
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? category,
    double? price,
    double? costPrice,
    int? stock,
    String? barcode,
    String? imageUrl,
    String? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      stock: stock ?? this.stock,
      barcode: barcode ?? this.barcode,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
