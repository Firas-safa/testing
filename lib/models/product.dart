import 'package:flutter/material.dart';

class ProductColor {
  const ProductColor(this.name, this.color);

  final String name;
  final Color color;
}

class Product {
  const Product({
    required this.name,
    required this.brand,
    required this.category,
    required this.description,
    required this.price,
    this.oldPrice,
    required this.rating,
    required this.reviewCount,
    required this.colors,
    required this.sizes,
    required this.highlights,
  });

  final String name;
  final String brand;
  final String category;
  final String description;
  final double price;
  final double? oldPrice;
  final double rating;
  final int reviewCount;
  final List<ProductColor> colors;
  final List<String> sizes;
  final Map<String, String> highlights;

  int? get discountPercent =>
      oldPrice == null ? null : (100 - price / oldPrice! * 100).round();
}

const sampleProduct = Product(
  name: 'Air Runner Pro',
  brand: 'Stride',
  category: 'Running Shoes',
  description:
      'Built for everyday miles, the Air Runner Pro pairs a responsive foam '
      'midsole with a breathable engineered-mesh upper. A reinforced heel '
      'counter keeps every stride stable, while the rubber outsole grips wet '
      'and dry roads alike. Lightweight enough for race day, cushioned enough '
      'for your long Sunday run.',
  price: 89.99,
  oldPrice: 129.99,
  rating: 4.6,
  reviewCount: 1284,
  colors: [
    ProductColor('Coral', Color(0xFFFF6B5B)),
    ProductColor('Ocean', Color(0xFF2F80ED)),
    ProductColor('Forest', Color(0xFF27AE60)),
    ProductColor('Midnight', Color(0xFF2D3142)),
  ],
  sizes: ['39', '40', '41', '42', '43', '44'],
  highlights: {
    'Weight': '240 g',
    'Drop': '8 mm',
    'Upper': 'Mesh',
    'Use': 'Road',
  },
);
