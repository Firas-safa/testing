import 'package:flutter/material.dart';

import 'models/cart.dart';
import 'models/product.dart';
import 'pages/product_show_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // One cart for the whole app.
  final _cart = Cart();

  @override
  void dispose() {
    _cart.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: const Color(0xFF4F46E5)),
      ),
      home: ProductShowPage(product: sampleProduct, cart: _cart),
    );
  }
}
