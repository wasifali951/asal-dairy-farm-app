import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/order_provider.dart';
import '../providers/auth_provider.dart';
import '../models/order_model.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    _refreshOrders();
  }

  Future<void> _refreshOrders() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isAdmin()) {
      await orderProvider.fetchOrders();
    } else {
      await orderProvider.fetchOrders(customerId: authProvider.currentUser?.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        if (orderProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (orderProvider.orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 100,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'No orders yet',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  authProvider.isAdmin()
                      ? 'Orders will appear here'
                      : 'Start shopping to place your first order',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshOrders,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orderProvider.orders.length,
            itemBuilder: (context, index) {
              final order = orderProvider.orders[index];
              return _OrderCard(
                order: order,
                isAdmin: authProvider.isAdmin(),
                onSendInvoice: () => _sendInvoice(order),
                onUpdateStatus: (status) => _updateStatus(order.id, status),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _sendInvoice(OrderModel order) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    await orderProvider.sendInvoice(order);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📲 Invoice sent to ${order.customerName}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _updateStatus(String orderId, String status) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    await orderProvider.updateOrderStatus(orderId, status);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated to $status'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final bool isAdmin;
  final VoidCallback onSendInvoice;
  final Function(String) onUpdateStatus;

  const _OrderCard({
    required this.order,
    required this.isAdmin,
    required this.onSendInvoice,
    required this.onUpdateStatus,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.id.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.customerName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '📞 ${order.customerPhone}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '📅 ${DateFormat('dd MMM yyyy, hh:mm a').format(order.date)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(order.status),
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Delivery Address
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.deliveryAddress,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.payments, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _paymentMethodLabel(order.paymentMethod),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _paymentStatusLabel(order.paymentStatus),
                        style: TextStyle(
                          fontSize: 12,
                          color: _paymentStatusColor(order.paymentStatus),
                        ),
                      ),
                      if (order.paymentAccount != null)
                        Text(
                          order.paymentAccount!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      if (order.paymentReference != null)
                        Text(
                          'Reference: ${order.paymentReference}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Order Items
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.name} x ${item.quantity}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        'Rs. ${(item.price * item.quantity).toInt()}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )),

            const Divider(height: 24),

            // Total Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Rs. ${order.total.toInt()}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            // Admin Actions
            if (isAdmin) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  // Status Dropdown
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: order.status,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: ['pending', 'processing', 'delivered', 'cancelled']
                          .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(status.toUpperCase()),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          onUpdateStatus(value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Send Invoice Button
                  ElevatedButton.icon(
                    onPressed: onSendInvoice,
                    icon: const Icon(Icons.send, size: 18),
                    label: const Text('Invoice'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _paymentMethodLabel(String paymentMethod) {
    switch (paymentMethod) {
      case 'easypaisa':
        return 'Payment: Easypaisa';
      case 'jazzcash':
        return 'Payment: JazzCash';
      case 'meezan_bank':
        return 'Payment: Meezan Bank';
      default:
        return 'Payment: Cash on Delivery';
    }
  }

  String _paymentStatusLabel(String paymentStatus) {
    return paymentStatus == 'pending_verification'
        ? 'Pending payment verification'
        : 'Pay when order is delivered';
  }

  Color _paymentStatusColor(String paymentStatus) {
    return paymentStatus == 'pending_verification'
        ? Colors.orange
        : Colors.green;
  }
}
