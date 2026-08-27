import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../providers/auth_provider.dart';
import '../models/order_model.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _paymentReferenceController =
      TextEditingController();
  String _paymentType = 'cash_on_delivery';
  String _onlinePaymentMethod = 'easypaisa';

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _addressController.text = authProvider.currentUser?.address ?? '';
  }

  @override
  void dispose() {
    _addressController.dispose();
    _paymentReferenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        if (cart.itemCount == 0) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 100,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Your cart is empty',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add products to get started',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Cart Items List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: cart.items.length,
                itemBuilder: (context, index) {
                  final item = cart.items.values.toList()[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // Product Image
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                item.product.image,
                                style: const TextStyle(fontSize: 32),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Product Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Rs. ${item.product.price.toInt()} per ${item.product.unit}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Quantity Controls
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  cart.updateQuantity(
                                    item.product.id,
                                    item.quantity - 1,
                                  );
                                },
                                icon: const Icon(Icons.remove_circle_outline),
                                color: Colors.red,
                              ),
                              Text(
                                '${item.quantity}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  cart.updateQuantity(
                                    item.product.id,
                                    item.quantity + 1,
                                  );
                                },
                                icon: const Icon(Icons.add_circle_outline),
                                color: Colors.green,
                              ),
                            ],
                          ),

                          // Item Total
                          SizedBox(
                            width: 70,
                            child: Text(
                              'Rs. ${item.totalPrice.toInt()}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Checkout Section
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.62,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Delivery Address
                    TextField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Delivery Address',
                        hintText: 'Enter your delivery address',
                        prefixIcon: const Icon(Icons.location_on),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: _paymentType,
                      decoration: InputDecoration(
                        labelText: 'Payment Method',
                        prefixIcon: const Icon(Icons.payments),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'cash_on_delivery',
                          child: Text('Cash on Delivery'),
                        ),
                        DropdownMenuItem(
                          value: 'online_transfer',
                          child: Text('Online Payment'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _paymentType = value);
                        }
                      },
                    ),
                    if (_paymentType == 'online_transfer') ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _onlinePaymentMethod,
                        decoration: InputDecoration(
                          labelText: 'Online Payment Option',
                          prefixIcon: const Icon(Icons.account_balance_wallet),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'easypaisa',
                            child: Text('Easypaisa'),
                          ),
                          DropdownMenuItem(
                            value: 'jazzcash',
                            child: Text('JazzCash'),
                          ),
                          DropdownMenuItem(
                            value: 'meezan_bank',
                            child: Text('Meezan Bank'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _onlinePaymentMethod = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildOnlinePaymentDetails(),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _paymentReferenceController,
                        decoration: InputDecoration(
                          labelText: 'Transfer Reference (Optional)',
                          hintText: 'Enter transaction ID after payment',
                          prefixIcon: const Icon(Icons.receipt_long),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Total Amount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Rs. ${cart.totalAmount.toInt()}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Place Order Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => _placeOrder(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Place Order',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _placeOrder(BuildContext context) async {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter delivery address')),
      );
      return;
    }

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final items = cartProvider.items.values
        .map((item) => OrderItem(
              productId: item.product.id,
              name: item.product.name,
              quantity: item.quantity,
              price: item.product.price,
            ))
        .toList();

    bool success = await orderProvider.placeOrder(
      customerId: authProvider.currentUser!.id,
      customerName: authProvider.currentUser!.name,
      customerPhone: authProvider.currentUser!.phone,
      items: items,
      total: cartProvider.totalAmount,
      deliveryAddress: _addressController.text.trim(),
      deliveryLatitude: authProvider.currentUser!.latitude,
      deliveryLongitude: authProvider.currentUser!.longitude,
      paymentMethod: _selectedPaymentMethod,
      paymentStatus: _paymentType == 'cash_on_delivery'
          ? 'pay_on_delivery'
          : 'pending_verification',
      paymentAccount:
          _paymentType == 'online_transfer' ? _selectedPaymentAccount : null,
      paymentReference: _paymentReferenceController.text.trim().isEmpty
          ? null
          : _paymentReferenceController.text.trim(),
    );

    if (success && mounted) {
      cartProvider.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed successfully! Admin notified in-app.'),
          duration: Duration(seconds: 3),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to place order. Please try again.')),
      );
    }
  }

  String get _selectedPaymentMethod {
    return _paymentType == 'cash_on_delivery'
        ? 'cash_on_delivery'
        : _onlinePaymentMethod;
  }

  String get _selectedPaymentAccount {
    switch (_onlinePaymentMethod) {
      case 'meezan_bank':
        return 'Meezan Bank: 04310112406298 (Muhammad Ashfaq)';
      case 'jazzcash':
        return 'JazzCash: 03008409358 (Muhammad Ashfaq)';
      default:
        return 'Easypaisa: 03008409358 (Muhammad Ashfaq)';
    }
  }

  Widget _buildOnlinePaymentDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transfer payment to:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          SelectableText(_selectedPaymentAccount),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: _selectedPaymentAccount),
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account details copied.')),
              );
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy account details'),
          ),
          const Text(
            'Your payment will remain pending until the admin verifies it.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
