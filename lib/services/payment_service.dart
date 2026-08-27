import 'package:flutter/foundation.dart';

enum PaymentGateway { jazzCash, easyPaisa }

class PaymentResult {
  final bool success;
  final String message;
  final String? transactionId;

  PaymentResult(
      {required this.success, required this.message, this.transactionId});
}

abstract class PaymentService {
  Future<void> initialize();
  Future<PaymentResult> charge(
      {required double amount, required String orderId});
}

/// Mock implementation for local development and testing.
class MockPaymentService implements PaymentService {
  final PaymentGateway provider;

  MockPaymentService({required this.provider});

  @override
  Future<void> initialize() async {
    await Future.delayed(const Duration(milliseconds: 200));
    debugPrint('Initialized mock payment gateway: $provider');
  }

  @override
  Future<PaymentResult> charge(
      {required double amount, required String orderId}) async {
    await Future.delayed(const Duration(seconds: 1));
    return PaymentResult(
      success: true,
      message: 'Mock payment succeeded for $provider',
      transactionId: 'MOCK-${DateTime.now().millisecondsSinceEpoch}',
    );
  }
}

// TODO: Add real platform-specific implementations using official SDKs or server-side integrations.
