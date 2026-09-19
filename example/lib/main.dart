import 'dart:math';
import 'package:flutter/material.dart';
import 'package:moneris_payment/moneris_payment.dart';

void main() {
  runApp(const MonerisExampleApp());
}

class MonerisExampleApp extends StatelessWidget {
  const MonerisExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moneris Payment Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF02569B)),
        useMaterial3: true,
      ),
      home: const CheckoutHomePage(),
    );
  }
}

class CheckoutHomePage extends StatefulWidget {
  const CheckoutHomePage({super.key});

  @override
  State<CheckoutHomePage> createState() => _CheckoutHomePageState();
}

class _CheckoutHomePageState extends State<CheckoutHomePage> {
  final double _amount = 49.99;
  final String _email = 'customer@example.com';
  Map<String, dynamic>? _lastTransaction;

  String _generateOrderId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = Random().nextInt(9999).toString().padLeft(4, '0');
    return 'ORD_${timestamp}_$randomSuffix';
  }

  void _startPayment() {
    final orderId = _generateOrderId();
    final customerId = 'CUST_${Random().nextInt(999999)}';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Moneris Checkout'),
          ),
          body: MonerisPaymentWidget(
            // Replace with your real backend endpoints in production:
            preloadUrl: 'https://your-backend.com/api/preload',
            receiptUrl: 'https://your-backend.com/api/receipt',
            txnTotal: _amount,
            orderNo: orderId,
            custId: customerId,
            email: _email,
            isTestMode: true,
            enableDebugLogs: true,
            cancelButtonText: 'Cancel Transaction',
            showCancelButtonOnLoading: true,
            showCancelButtonOnPayment: true,
            onSuccess: (details) {
              setState(() {
                _lastTransaction = details;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Payment Successful! Txn: ${details['transaction_no'] ?? 'Approved'}',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            onError: (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Payment Error: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            onCancel: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment was cancelled by the user'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moneris Payment Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Product:', style: TextStyle(fontSize: 15)),
                        const Text('Flutter Dev Pro License',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Customer Email:',
                            style: TextStyle(fontSize: 15)),
                        Text(_email,
                            style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount:',
                            style: TextStyle(fontSize: 15)),
                        Text(
                          '\$${_amount.toStringAsFixed(2)} CAD',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF02569B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _startPayment,
              icon: const Icon(Icons.payment),
              label: const Text('Proceed to Checkout',
                  style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF02569B),
                foregroundColor: Colors.white,
              ),
            ),
            if (_lastTransaction != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Last Transaction Details:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  _lastTransaction.toString(),
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
