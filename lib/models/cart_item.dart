class CartItem {
  final String productId;
  final String name;
  final double price;
  int qty;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    this.qty = 1,
  });

  double get subtotal => price * qty;

  // Handy if you're saving cart items to sqflite for offline queuing
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'qty': qty,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      qty: map['qty'] as int,
    );
  }
}
