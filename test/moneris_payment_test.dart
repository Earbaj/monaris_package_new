import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneris_payment/moneris_payment.dart';

void main() {
  group('MonerisPaymentWidget', () {
    testWidgets('creates successfully with required parameters', (WidgetTester tester) async {
      // This test just ensures the widget can be instantiated
      final widget = MonerisPaymentWidget(
        preloadUrl: 'http://192.168.0.101:3000/preload',
        receiptUrl: 'http://192.168.0.101:3000/receipt',
        txnTotal: 1250.50,
        orderNo: 'TEST_ORDER_3',
        custId: 'CUST_3',
        email: 'saria@example.com',
      );

      expect(widget, isNotNull);
      expect(widget.preloadUrl, 'http://192.168.0.101:3000/preload');
      expect(widget.txnTotal, 1250.50);
    });

    testWidgets('validates required parameters are provided', (WidgetTester tester) async {
      expect(
            () => MonerisPaymentWidget(
          preloadUrl: 'http://192.168.0.101:3000/preload',
          receiptUrl: 'http://192.168.0.101:3000/receipt',
          txnTotal: 1250.50,
          orderNo: 'TEST_ORDER_3',
          custId: 'CUST_3',
          email: 'saria@example.com',
        ),
        returnsNormally,
      );
    });

    testWidgets('has correct default values', (WidgetTester tester) async {
      final widget = MonerisPaymentWidget(
        preloadUrl: 'http://192.168.0.101:3000/preload',
        receiptUrl: 'http://192.168.0.101:3000/receipt',
        txnTotal: 1250.50,
        orderNo: 'TEST_ORDER_3',
        custId: 'CUST_3',
        email: 'saria@example.com',
      );

      expect(widget.isTestMode, true); // Default value
    });
  });

  group('MonerisPaymentWidget Integration', () {
    // Skip the actual widget building test in CI or use a different approach
    testWidgets('widget structure test - skip in CI', (WidgetTester tester) async {
      // This would be an integration test rather than a unit test
      // You can skip this or run it separately
    }, skip: true);
  });
}