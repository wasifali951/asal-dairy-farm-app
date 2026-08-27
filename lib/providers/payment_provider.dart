import 'package:flutter/material.dart';
import '../services/payment_service.dart';

class PaymentProvider with ChangeNotifier {
  final PaymentService service;

  bool _isProcessing = false;
  String? _lastTransactionId;
  String? _error;

  PaymentProvider({required this.service});

  bool get isProcessing => _isProcessing;
  String? get lastTransactionId => _lastTransactionId;
  String? get error => _error;

  Future<void> init() async {
    try {
      await service.initialize();
    } catch (e) {
      _error = 'Initialization failed: $e';
      notifyListeners();
    }
  }

  Future<bool> pay({required double amount, required String orderId}) async {
    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      final result = await service.charge(amount: amount, orderId: orderId);
      _isProcessing = false;
      if (result.success) {
        _lastTransactionId = result.transactionId;
        notifyListeners();
        return true;
      } else {
        _error = result.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isProcessing = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
