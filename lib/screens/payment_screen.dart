import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/payment_provider.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({Key? key}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentProvider? _provider;
  double _amount = 100.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider ??= Provider.of<PaymentProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              initialValue: _amount.toStringAsFixed(2),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
              onChanged: (v) => _amount = double.tryParse(v) ?? _amount,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final provider =
                    Provider.of<PaymentProvider>(context, listen: false);
                await provider.pay(
                    amount: _amount,
                    orderId: 'ORDER-${DateTime.now().millisecondsSinceEpoch}');
                if (provider.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${provider.error}')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          'Payment success: ${provider.lastTransactionId}')));
                }
              },
              child: const Text('Pay (Mock)'),
            ),
          ],
        ),
      ),
    );
  }
}
