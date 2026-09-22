class CartItem {
  final int itemId;
  final String itemType; // 'PRODUCT' or 'SERVICE'
  final String name;
  final double price;
  final int qty;
  final String? imageUrl;

  CartItem({
    required this.itemId,
    required this.itemType,
    required this.name,
    required this.price,
    this.qty = 1,
    this.imageUrl,
  });

  double get subtotal => price * qty;

  CartItem copyWith({
    int? itemId,
    String? itemType,
    String? name,
    double? price,
    int? qty,
    String? imageUrl,
  }) {
    return CartItem(
      itemId: itemId ?? this.itemId,
      itemType: itemType ?? this.itemType,
      name: name ?? this.name,
      price: price ?? this.price,
      qty: qty ?? this.qty,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
