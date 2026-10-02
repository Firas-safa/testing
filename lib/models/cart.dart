import 'package:flutter/foundation.dart';

import 'product.dart';

/// One product variant (color + size) in the cart.
class CartItem {
  const CartItem({
    required this.product,
    required this.color,
    required this.size,
    required this.quantity,
  });

  final Product product;
  final ProductColor color;
  final String size;
  final int quantity;

  double get total => product.price * quantity;

  CartItem withQuantity(int quantity) =>
      CartItem(product: product, color: color, size: size, quantity: quantity);
}

/// In-memory cart. Listen to it to rebuild when items change.
class Cart extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  /// Total number of units, e.g. 2 × shoes + 1 × socks = 3.
  int get count => _items.fold(0, (sum, item) => sum + item.quantity);

  double get total => _items.fold(0.0, (sum, item) => sum + item.total);

  /// Adds [quantity] units, merging with an existing line for the same
  /// product, color and size.
  void add(
    Product product,
    ProductColor color,
    String size, {
    int quantity = 1,
  }) {
    final i = _indexOf(product, color, size);
    if (i == -1) {
      _items.add(CartItem(
        product: product,
        color: color,
        size: size,
        quantity: quantity,
      ));
    } else {
      _items[i] = _items[i].withQuantity(_items[i].quantity + quantity);
    }
    notifyListeners();
  }

  /// Sets the quantity of [item]'s line; 0 or less removes it.
  void setQuantity(CartItem item, int quantity) {
    final i = _indexOf(item.product, item.color, item.size);
    if (i == -1) return;
    if (quantity <= 0) {
      _items.removeAt(i);
    } else {
      _items[i] = _items[i].withQuantity(quantity);
    }
    notifyListeners();
  }

  void remove(CartItem item) => setQuantity(item, 0);

  int _indexOf(Product product, ProductColor color, String size) =>
      _items.indexWhere((item) =>
          item.product == product &&
          item.color.name == color.name &&
          item.size == size);
}
