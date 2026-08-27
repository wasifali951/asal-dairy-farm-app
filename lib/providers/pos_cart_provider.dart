import 'package:flutter/material.dart';
import '../models/cart_item.dart';

class PosCartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  double get total => _items.fold(0, (sum, item) => sum + item.subtotal);

  void addProduct(String productId, String name, double price) {
    final existingIndex = _items.indexWhere((i) => i.productId == productId);
    if (existingIndex >= 0) {
      _items[existingIndex].qty++;
    } else {
      _items.add(CartItem(productId: productId, name: name, price: price));
    }
    notifyListeners();
  }

  void incrementQty(String productId) {
    final item = _items.firstWhere((i) => i.productId == productId);
    item.qty++;
    notifyListeners();
  }

  void decrementQty(String productId) {
    final index = _items.indexWhere((i) => i.productId == productId);
    if (index < 0) return;
    if (_items[index].qty > 1) {
      _items[index].qty--;
    } else {
      _items.removeAt(index);
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.removeWhere((i) => i.productId == productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
