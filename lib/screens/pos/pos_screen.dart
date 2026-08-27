import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/pos_cart_provider.dart';
import '../../db/product_dao.dart';
import '../../db/sale_dao.dart';
import '../../services/printer_service.dart';
import '../../services/sync_service.dart';
import 'printer_pairing_screen.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final ProductDao _productDao = ProductDao();
  final SaleDao _saleDao = SaleDao();
  List<Product> _products = [];
  bool _loading = true;
  bool _checkingOut = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await _productDao.getAllProducts();
    setState(() {
      _products = products;
      _loading = false;
    });
  }

  Future<void> _checkout() async {
    final cart = Provider.of<PosCartProvider>(context, listen: false);
    if (cart.items.isEmpty) return;

    setState(() => _checkingOut = true);

    try {
      final printerService = Provider.of<PrinterService>(context, listen: false);
      final syncService = Provider.of<SyncService>(context, listen: false);

      // 1. Save locally first — always succeeds regardless of connectivity
      await _saleDao.saveSale(cart.items, cart.total);

      // 2. Print receipt
      await printerService.printReceipt(cart.items, cart.total);

      // 3. Try syncing now (no-op if offline, will retry via listener)
      syncService.syncUnsyncedSales();

      // 4. Refresh local product list to reflect decremented stock
      await _loadProducts();

      cart.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sale completed and receipt printed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checkout failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _checkingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<PosCartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Point of Sale'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Pair Printer',
            onPressed: () {
              final printerService = Provider.of<PrinterService>(context, listen: false);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PrinterPairingScreen(printerService: printerService),
                ),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Product grid
                Expanded(
                  flex: 2,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.1,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      return Card(
                        child: InkWell(
                          onTap: product.stock > 0
                              ? () => cart.addProduct(product.id, product.name, product.price)
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(product.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('Rs ${product.price.toStringAsFixed(2)}'),
                                Text(
                                  'Stock: ${product.stock}',
                                  style: TextStyle(
                                    color: product.stock > 0 ? Colors.grey : Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const VerticalDivider(width: 1),
                // Cart panel
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: cart.items.length,
                          itemBuilder: (context, index) {
                            final item = cart.items[index];
                            return ListTile(
                              title: Text(item.name),
                              subtitle: Text('Rs ${item.price.toStringAsFixed(2)} x ${item.qty}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: () => cart.decrementQty(item.productId),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () => cart.incrementQty(item.productId),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text('Rs ${cart.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _checkingOut ? null : _checkout,
                                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                                child: _checkingOut
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text('Checkout & Print'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}