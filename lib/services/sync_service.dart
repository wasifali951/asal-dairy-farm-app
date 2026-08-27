import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../db/sale_dao.dart';

class SyncService {
  final SaleDao saleDao = SaleDao();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool _isSyncing = false;

  /// Call this once (e.g. in main.dart or a top-level provider) to auto-sync
  /// whenever connectivity is restored.
  void startAutoSync() {
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        syncUnsyncedSales();
      }
    });
  }

  Future<void> syncUnsyncedSales() async {
    if (_isSyncing) return; // avoid overlapping sync runs
    _isSyncing = true;

    try {
      final unsyncedSales = await saleDao.getUnsyncedSales();

      for (final sale in unsyncedSales) {
        final saleId = sale['id'] as String;
        final items = await saleDao.getSaleItems(saleId);

        try {
          await _syncSingleSale(saleId, sale, items);
          await saleDao.markSynced(saleId);
        } catch (e) {
          // Leave this sale unsynced — it'll retry next time.
          // Log it so you can see failures during testing.
          print('Sync failed for sale $saleId: $e');
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncSingleSale(
    String saleId,
    Map<String, dynamic> sale,
    List<Map<String, dynamic>> items,
  ) async {
    final saleRef = firestore.collection('sales').doc(saleId);

    await firestore.runTransaction((transaction) async {
      // 1. Write the sale document (safe to overwrite on retry — same ID)
      transaction.set(saleRef, {
        'totalAmount': sale['totalAmount'],
        'createdAt': sale['createdAt'],
        'source': 'pos', // distinguishes from online orders in reports
        'items': items
            .map((i) => {
                  'productId': i['productId'],
                  'name': i['name'],
                  'price': i['price'],
                  'qty': i['qty'],
                })
            .toList(),
      });

      // 2. Decrement stock atomically for each item
      for (final item in items) {
        final productRef =
            firestore.collection('products').doc(item['productId'] as String);
        final snapshot = await transaction.get(productRef);

        if (snapshot.exists) {
          final currentStock = (snapshot['stock'] as num).toInt();
          final qty = item['qty'] as int;
          transaction.update(productRef, {
            'stock': currentStock - qty,
          });
        }
      }
    });
  }
}
