import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String role;
  final bool isRegistered;
  final double? latitude;
  final double? longitude;
  final String? fullAddress;
  final DateTime? locationUpdatedAt;
  final String? profileImageUrl;
  final NotificationPreferences? notificationPrefs;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.role,
    this.isRegistered = true,
    this.latitude,
    this.longitude,
    this.fullAddress,
    this.locationUpdatedAt,
    this.profileImageUrl,
    this.notificationPrefs,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'role': role,
      'isRegistered': isRegistered,
      'latitude': latitude,
      'longitude': longitude,
      'fullAddress': fullAddress,
      'locationUpdatedAt': locationUpdatedAt?.millisecondsSinceEpoch,
      'profileImageUrl': profileImageUrl,
      'notificationPrefs': notificationPrefs?.toMap(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      role: map['role'] ?? 'customer',
      isRegistered: map['isRegistered'] ?? true,
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      fullAddress: map['fullAddress'],
      locationUpdatedAt: map['locationUpdatedAt'] != null
          ? _parseDate(map['locationUpdatedAt'])
          : null,
      profileImageUrl: map['profileImageUrl'],
      notificationPrefs: map['notificationPrefs'] != null
          ? NotificationPreferences.fromMap(map['notificationPrefs'])
          : NotificationPreferences(),
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? role,
    bool? isRegistered,
    double? latitude,
    double? longitude,
    String? fullAddress,
    DateTime? locationUpdatedAt,
    String? profileImageUrl,
    NotificationPreferences? notificationPrefs,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      role: role ?? this.role,
      isRegistered: isRegistered ?? this.isRegistered,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      fullAddress: fullAddress ?? this.fullAddress,
      locationUpdatedAt: locationUpdatedAt ?? this.locationUpdatedAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      notificationPrefs: notificationPrefs ?? this.notificationPrefs,
    );
  }
}

class NotificationPreferences {
  final bool orderUpdates;
  final bool promotionalOffers;
  final bool newProducts;
  final bool weeklyDeals;
  final bool reorderReminders;
  final String quietHoursStart;
  final String quietHoursEnd;

  NotificationPreferences({
    this.orderUpdates = true,
    this.promotionalOffers = true,
    this.newProducts = true,
    this.weeklyDeals = true,
    this.reorderReminders = true,
    this.quietHoursStart = "22:00",
    this.quietHoursEnd = "07:00",
  });

  Map<String, dynamic> toMap() {
    return {
      'orderUpdates': orderUpdates,
      'promotionalOffers': promotionalOffers,
      'newProducts': newProducts,
      'weeklyDeals': weeklyDeals,
      'reorderReminders': reorderReminders,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
    };
  }

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      orderUpdates: map['orderUpdates'] ?? true,
      promotionalOffers: map['promotionalOffers'] ?? true,
      newProducts: map['newProducts'] ?? true,
      weeklyDeals: map['weeklyDeals'] ?? true,
      reorderReminders: map['reorderReminders'] ?? true,
      quietHoursStart: map['quietHoursStart'] ?? "22:00",
      quietHoursEnd: map['quietHoursEnd'] ?? "07:00",
    );
  }

  NotificationPreferences copyWith({
    bool? orderUpdates,
    bool? promotionalOffers,
    bool? newProducts,
    bool? weeklyDeals,
    bool? reorderReminders,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) {
    return NotificationPreferences(
      orderUpdates: orderUpdates ?? this.orderUpdates,
      promotionalOffers: promotionalOffers ?? this.promotionalOffers,
      newProducts: newProducts ?? this.newProducts,
      weeklyDeals: weeklyDeals ?? this.weeklyDeals,
      reorderReminders: reorderReminders ?? this.reorderReminders,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
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
  return DateTime.fromMillisecondsSinceEpoch(value as int);
}
