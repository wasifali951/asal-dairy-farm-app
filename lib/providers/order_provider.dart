import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/order_model.dart';
import '../services/notification_service.dart';

class OrderProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<OrderModel> _orders = [];
  bool _isLoading = false;
  StreamSubscription<QuerySnapshot>? _ordersSubscription;

  List<OrderModel> get orders => [..._orders];
  bool get isLoading => _isLoading;

  Future<void> initializeFCM() async {
    try {
      await NotificationService.initialize();
    } catch (e) {
      print('Initialize FCM error: $e');
    }
  }

  Future<bool> placeOrder({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required List<OrderItem> items,
    required double total,
    required String deliveryAddress,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String? deliveryInstructions,
    String paymentMethod = 'cash_on_delivery',
    String paymentStatus = 'pay_on_delivery',
    String? paymentAccount,
    String? paymentReference,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      String orderId = _firestore.collection('orders').doc().id;

      OrderModel newOrder = OrderModel(
        id: orderId,
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        items: items,
        total: total,
        deliveryAddress: deliveryAddress,
        deliveryLatitude: deliveryLatitude,
        deliveryLongitude: deliveryLongitude,
        deliveryInstructions: deliveryInstructions,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
        paymentAccount: paymentAccount,
        paymentReference: paymentReference,
        status: 'pending',
        date: DateTime.now(),
      );

      await _firestore.collection('orders').doc(orderId).set(newOrder.toMap());

      _orders.insert(0, newOrder);
      _isLoading = false;
      notifyListeners();

      await NotificationService.sendToUser(
        userId: customerId,
        title: '🎉 Order Confirmed!',
        body:
            'Your order #${orderId.substring(0, 8)} has been placed successfully. Total: Rs. ${total.toInt()}',
        data: {'orderId': orderId, 'type': 'order_confirmation'},
      );

      await _notifyAdmins(newOrder);

      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Place order error: $e');
      return false;
    }
  }

  Future<void> _notifyAdmins(OrderModel order) async {
    try {
      QuerySnapshot admins = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      for (var admin in admins.docs) {
        await NotificationService.sendToUser(
          userId: admin.id,
          title: '🔔 New Order Received!',
          body: 'Order from ${order.customerName} - Rs. ${order.total.toInt()}',
          data: {'orderId': order.id, 'type': 'new_order_admin'},
        );
      }
    } catch (e) {
      print('Error notifying admins: $e');
    }
  }

  Future<void> fetchOrders({String? customerId}) async {
    try {
      _isLoading = true;
      notifyListeners();

      Query query = _buildOrdersQuery(customerId);

      QuerySnapshot snapshot = await query.get();

      _orders = _parseOrders(snapshot);
      _sortOrders();
    } catch (e) {
      print('Fetch orders error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void listenToOrders({String? customerId}) {
    _ordersSubscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _ordersSubscription = _buildOrdersQuery(customerId).snapshots().listen(
      (snapshot) {
        try {
          _orders = _parseOrders(snapshot);
          _sortOrders();
        } catch (e) {
          print('Listen orders parse error: $e');
        } finally {
          _isLoading = false;
          notifyListeners();
        }
      },
      onError: (Object error) {
        _isLoading = false;
        notifyListeners();
        print('Listen orders error: $error');
      },
    );
  }

  Future<void> stopListeningToOrders() async {
    await _ordersSubscription?.cancel();
    _ordersSubscription = null;
  }

  Query _buildOrdersQuery(String? customerId) {
    Query query = _firestore.collection('orders');
    if (customerId != null) {
      query = query.where('customerId', isEqualTo: customerId);
    }
    return query;
  }

  List<OrderModel> _parseOrders(QuerySnapshot snapshot) {
    final parsedOrders = <OrderModel>[];

    for (final doc in snapshot.docs) {
      try {
        final data = doc.data();
        if (data is Map<String, dynamic>) {
          parsedOrders.add(OrderModel.fromMap(data));
        }
      } catch (e) {
        print('Parse order error for ${doc.id}: $e');
      }
    }

    return parsedOrders;
  }

  void _sortOrders() {
    _orders.sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> sendInvoice(OrderModel order) async {
    try {
      await NotificationService.sendToUser(
        userId: order.customerId,
        title: '📄 Invoice Ready',
        body:
            'Invoice for order #${order.id.substring(0, 8)} - Amount: Rs. ${order.total.toInt()}',
        data: {'orderId': order.id, 'type': 'invoice'},
      );
    } catch (e) {
      print('Send invoice error: $e');
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore
          .collection('orders')
          .doc(orderId)
          .update({'status': status});

      int index = _orders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        OrderModel order = _orders[index];

        String statusMessage = _getStatusMessage(status);
        await NotificationService.sendToUser(
          userId: order.customerId,
          title: statusMessage,
          body: 'Order #${orderId.substring(0, 8)} is now $status',
          data: {'orderId': orderId, 'type': 'status_update'},
        );

        _orders[index] = OrderModel(
          id: order.id,
          customerId: order.customerId,
          customerName: order.customerName,
          customerPhone: order.customerPhone,
          items: order.items,
          total: order.total,
          deliveryAddress: order.deliveryAddress,
          deliveryLatitude: order.deliveryLatitude,
          deliveryLongitude: order.deliveryLongitude,
          deliveryInstructions: order.deliveryInstructions,
          paymentMethod: order.paymentMethod,
          paymentStatus: order.paymentStatus,
          paymentAccount: order.paymentAccount,
          paymentReference: order.paymentReference,
          status: status,
          date: order.date,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Update order status error: $e');
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'processing':
        return '👨‍🍳 Order is Being Prepared';
      case 'out_for_delivery':
        return '🚚 Out for Delivery';
      case 'delivered':
        return '✅ Order Delivered!';
      case 'cancelled':
        return '❌ Order Cancelled';
      default:
        return '📦 Order Status Updated';
    }
  }
}
