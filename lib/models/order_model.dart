import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final List<OrderItem> items;
  final double total;
  final String deliveryAddress;
  final String status;
  final DateTime date;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final String? deliveryInstructions;
  final String paymentMethod;
  final String paymentStatus;
  final String? paymentAccount;
  final String? paymentReference;

  OrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.total,
    required this.deliveryAddress,
    required this.status,
    required this.date,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.deliveryInstructions,
    this.paymentMethod = 'cash_on_delivery',
    this.paymentStatus = 'pay_on_delivery',
    this.paymentAccount,
    this.paymentReference,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'items': items.map((x) => x.toMap()).toList(),
      'total': total,
      'deliveryAddress': deliveryAddress,
      'status': status,
      'date': date.millisecondsSinceEpoch,
      'deliveryLatitude': deliveryLatitude,
      'deliveryLongitude': deliveryLongitude,
      'deliveryInstructions': deliveryInstructions,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'paymentAccount': paymentAccount,
      'paymentReference': paymentReference,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'];
    final parsedItems = <OrderItem>[];

    if (rawItems is Iterable) {
      for (final rawItem in rawItems) {
        if (rawItem is Map) {
          parsedItems
              .add(OrderItem.fromMap(Map<String, dynamic>.from(rawItem)));
        }
      }
    }

    return OrderModel(
      id: map['id'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      items: parsedItems,
      total: (map['total'] ?? 0).toDouble(),
      deliveryAddress: map['deliveryAddress'] ?? '',
      status: map['status'] ?? 'pending',
      date: _parseDate(map['date']),
      deliveryLatitude: map['deliveryLatitude']?.toDouble(),
      deliveryLongitude: map['deliveryLongitude']?.toDouble(),
      deliveryInstructions: map['deliveryInstructions'],
      paymentMethod: map['paymentMethod'] ?? 'cash_on_delivery',
      paymentStatus: map['paymentStatus'] ?? 'pay_on_delivery',
      paymentAccount: map['paymentAccount'],
      paymentReference: map['paymentReference'],
    );
  }
}

DateTime _parseDate(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

class OrderItem {
  final String productId;
  final String name;
  final int quantity;
  final double price;

  OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'quantity': quantity,
      'price': price,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? 0,
      price: (map['price'] ?? 0).toDouble(),
    );
  }
}
