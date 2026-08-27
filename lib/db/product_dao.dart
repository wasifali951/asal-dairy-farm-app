import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';

import 'db_helper.dart';

class Product {
  final String id;
  final String name;
  final double price;
  final int stock;
  final String unit;
  final String image;
  final String description;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.unit,
    required this.image,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'stock': stock,
      'unit': unit,
      'image': image,
      'description': description,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      price: _toDouble(map['price']),
      stock: _toInt(map['stock']),
      unit: map['unit'] as String? ?? '',
      image: map['image'] as String? ?? '',
      description: map['description'] as String? ?? '',
    );
  }
}

class ProductDao {
  ProductDao({DBHelper? dbHelper, FirebaseFirestore? firestore})
      : _dbHelper = dbHelper ?? DBHelper.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final DBHelper _dbHelper;
  final FirebaseFirestore _firestore;

  Future<List<Product>> getAllProducts() async {
    final db = await _dbHelper.database;
    final localProducts =
        await db.query('products', orderBy: 'name COLLATE NOCASE');

    if (localProducts.isNotEmpty) {
      return localProducts.map(Product.fromMap).toList();
    }

    return _refreshFromFirestore();
  }

  Future<List<Product>> _refreshFromFirestore() async {
    try {
      final snapshot = await _firestore.collection('products').get();
      final products = snapshot.docs.map((doc) {
        final data = doc.data();
        return Product(
          id: doc.id,
          name: data['name'] as String? ?? '',
          price: _toDouble(data['price']),
          stock: _toInt(data['stock']),
          unit: data['unit'] as String? ?? '',
          image: data['image'] as String? ?? '',
          description: data['description'] as String? ?? '',
        );
      }).toList();

      await replaceAll(products);
      return products;
    } catch (_) {
      final db = await _dbHelper.database;
      final localProducts =
          await db.query('products', orderBy: 'name COLLATE NOCASE');
      return localProducts.map(Product.fromMap).toList();
    }
  }

  Future<void> replaceAll(List<Product> products) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('products');
      for (final product in products) {
        await txn.insert(
          'products',
          product.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> decrementStock(String productId, int quantity) async {
    final db = await _dbHelper.database;
    await db.rawUpdate(
      '''
      UPDATE products
      SET stock = CASE
        WHEN stock >= ? THEN stock - ?
        ELSE 0
      END
      WHERE id = ?
      ''',
      [quantity, quantity, productId],
    );
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0.0;
}

int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
