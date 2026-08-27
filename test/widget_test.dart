import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asal_dairy/models/order_model.dart';
import 'package:asal_dairy/models/user_model.dart';

void main() {
  test('order survives serialization for reload tracking', () {
    final placedAt = DateTime(2026, 5, 31, 12, 30);
    final order = OrderModel(
      id: 'order-123',
      customerId: 'customer-123',
      customerName: 'Test Customer',
      customerPhone: '03001234567',
      items: [
        OrderItem(
          productId: 'milk-1',
          name: 'Fresh Milk',
          quantity: 2,
          price: 250,
        ),
      ],
      total: 500,
      deliveryAddress: 'Faisalabad',
      status: 'pending',
      date: placedAt,
      paymentMethod: 'easypaisa',
      paymentStatus: 'pending_verification',
      paymentReference: 'TXN-123',
    );

    final restored = OrderModel.fromMap(order.toMap());

    expect(restored.id, order.id);
    expect(restored.status, 'pending');
    expect(restored.items.single.quantity, 2);
    expect(restored.date, placedAt);
    expect(restored.paymentMethod, 'easypaisa');
    expect(restored.paymentStatus, 'pending_verification');
    expect(restored.paymentReference, 'TXN-123');
  });

  test('profile accepts Firestore timestamps after location update', () {
    final updatedAt = DateTime(2026, 5, 31, 13, 0);
    final user = UserModel.fromMap({
      'id': 'customer-123',
      'name': 'Test Customer',
      'email': 'customer@example.com',
      'phone': '03001234567',
      'address': 'Faisalabad',
      'role': 'customer',
      'locationUpdatedAt': Timestamp.fromDate(updatedAt),
    });

    expect(user.locationUpdatedAt, updatedAt);
  });
}
