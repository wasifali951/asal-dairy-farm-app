import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/cart_item.dart';
import 'db_helper.dart';

class SaleDao {
  SaleDao({DBHelper? dbHelper}) : _dbHelper = dbHelper ?? DBHelper.instance;

  final DBHelper _dbHelper;
  final Uuid _uuid = const Uuid();

  Future<String> saveSale(List<CartItem> items, double totalAmount) async {
    final db = await _dbHelper.database;
    final saleId = _uuid.v4();
    final createdAt = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      await txn.insert(
        'sales',
        {
          'id': saleId,
          'totalAmount': totalAmount,
          'createdAt': createdAt,
          'synced': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      for (final item in items) {
        await txn.insert('sale_items', {
          'saleId': saleId,
          'productId': item.productId,
          'name': item.name,
          'price': item.price,
          'qty': item.qty,
        });

        await txn.rawUpdate(
          '''
          UPDATE products
          SET stock = CASE
            WHEN stock >= ? THEN stock - ?
            ELSE 0
          END
          WHERE id = ?
          ''',
          [item.qty, item.qty, item.productId],
        );
      }
    });

    return saleId;
  }

  Future<List<Map<String, dynamic>>> getUnsyncedSales() async {
    final db = await _dbHelper.database;
    return db.query(
      'sales',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'createdAt ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getSaleItems(String saleId) async {
    final db = await _dbHelper.database;
    return db.query('sale_items', where: 'saleId = ?', whereArgs: [saleId]);
  }

  Future<void> markSynced(String saleId) async {
    final db = await _dbHelper.database;
    await db.update(
      'sales',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [saleId],
    );
  }
}
