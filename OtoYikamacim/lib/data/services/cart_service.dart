import 'package:flutter/material.dart';

import '../../models/product.dart';

class CartService extends ChangeNotifier {
  final Map<String, int> _items = {};
  final Map<String, Product> _products = {};

  List<Product> get items {
    return _items.entries.map((entry) {
      final product = _products[entry.key]!;
      return product;
    }).toList();
  }

  int getItemCount(Product product) {
    return _items[product.id] ?? 0;
  }

  void addItem(Product product) {
    if (_items.containsKey(product.id)) {
      _items[product.id] = _items[product.id]! + 1;
    } else {
      _items[product.id] = 1;
      _products[product.id] = product;
    }
    notifyListeners();
  }

  void removeItem(Product product) {
    if (_items.containsKey(product.id)) {
      if (_items[product.id]! > 1) {
        _items[product.id] = _items[product.id]! - 1;
      } else {
        _items.remove(product.id);
        _products.remove(product.id);
      }
      notifyListeners();
    }
  }

  void removeAllItems(Product product) {
    _items.remove(product.id);
    _products.remove(product.id);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _products.clear();
    notifyListeners();
  }

  double getTotalPrice() {
    return _items.entries.fold(0, (sum, entry) {
      final product = _products[entry.key]!;
      return sum + (product.price * entry.value);
    });
  }

  int get totalItemCount {
    return _items.values.fold(0, (sum, count) => sum + count);
  }
} 