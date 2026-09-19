import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:moneris_payment/moneris_html_templates.dart';
import 'package:moneris_payment/moneris_payment.dart';

void main() {
  group('MonerisPaymentWidget', () {
    testWidgets('creates successfully with required parameters', (WidgetTester tester) async {
      const widget = MonerisPaymentWidget(
        preloadUrl: 'https://example.com/preload',
        receiptUrl: 'https://example.com/receipt',
        txnTotal: 125.50,
        orderNo: 'TEST_ORDER_123',
        custId: 'CUST_123',
        email: 'customer@example.com',
      );

      expect(widget, isNotNull);
      expect(widget.preloadUrl, 'https://example.com/preload');
      expect(widget.receiptUrl, 'https://example.com/receipt');
      expect(widget.txnTotal, 125.50);
      expect(widget.orderNo, 'TEST_ORDER_123');
      expect(widget.custId, 'CUST_123');
      expect(widget.email, 'customer@example.com');
      expect(widget.isTestMode, isTrue);
      expect(widget.enableDebugLogs, isFalse);
      expect(widget.cancelButtonText, isNull);
      expect(widget.showCancelButtonOnLoading, isFalse);
      expect(widget.showCancelButtonOnPayment, isFalse);
    });

    test('validates parameter configuration and custom options', () {
      bool cancelled = false;
      bool successCalled = false;
      bool errorCalled = false;

      final widget = MonerisPaymentWidget(
        preloadUrl: 'https://example.com/preload',
        receiptUrl: 'https://example.com/receipt',
        txnTotal: 99.99,
        orderNo: 'ORD_999',
        custId: 'CUST_999',
        email: 'user@example.com',
        isTestMode: false,
        enableDebugLogs: true,
        cancelButtonText: 'Abort Payment',
        showCancelButtonOnLoading: true,
        showCancelButtonOnPayment: true,
        onCancel: () => cancelled = true,
        onSuccess: (_) => successCalled = true,
        onError: (_) => errorCalled = true,
      );

      expect(widget.isTestMode, isFalse);
      expect(widget.enableDebugLogs, isTrue);
      expect(widget.cancelButtonText, 'Abort Payment');
      expect(widget.showCancelButtonOnLoading, isTrue);
      expect(widget.showCancelButtonOnPayment, isTrue);

      widget.onCancel?.call();
      expect(cancelled, isTrue);

      widget.onSuccess?.call({'status': 'ok'});
      expect(successCalled, isTrue);

      widget.onError?.call('error');
      expect(errorCalled, isTrue);
    });

    testWidgets('widget structure test - skip in headless CI without WebViewPlatform',
        (WidgetTester tester) async {
      // WebViewPlatform requires native platform channels (Android/iOS)
    }, skip: true);
  });

  group('MonerisErrorHandler', () {
    test('handleError with ClientException returns network error', () {
      final clientException = http.ClientException('Connection refused');
      final result = MonerisErrorHandler.handleError(clientException);
      expect(result, contains('Network error: Connection refused'));
    });

    test('handleError with TimeoutException returns timeout message', () {
      final timeoutException = TimeoutException('Timeout');
      final result = MonerisErrorHandler.handleError(timeoutException);
      expect(result, contains('timed out'));
    });

    test('handleError with FormatException returns format error', () {
      const formatException = FormatException('Bad JSON');
      final result = MonerisErrorHandler.handleError(formatException);
      expect(result, contains('Invalid response format'));
    });

    test('handleError with String returns identical string', () {
      final result = MonerisErrorHandler.handleError('Custom error message');
      expect(result, 'Custom error message');
    });

    test('handleError with unknown exception returns generic error', () {
      final result = MonerisErrorHandler.handleError(Exception('Unknown'));
      expect(result, contains('An unexpected error occurred'));
    });

    test('validatePreloadResponse returns null for valid ticket', () {
      final response = {'ticket': 'valid_ticket_12345'};
      expect(MonerisErrorHandler.validatePreloadResponse(response), isNull);
    });

    test('validatePreloadResponse returns error when ticket is missing', () {
      final response = <String, dynamic>{};
      expect(MonerisErrorHandler.validatePreloadResponse(response),
          'No ticket received from payment server');
    });

    test('validatePreloadResponse returns error when ticket is empty', () {
      final response = {'ticket': ''};
      expect(MonerisErrorHandler.validatePreloadResponse(response),
          'Empty ticket received from payment server');
    });

    test('validateReceiptResponse returns null for valid transactionDetails', () {
      final response = {
        'transactionDetails': {
          'transaction_no': 'TXN_123',
          'response_code': '001',
          'result': 'a',
        }
      };
      expect(MonerisErrorHandler.validateReceiptResponse(response), isNull);
    });

    test('validateReceiptResponse returns error when transactionDetails is missing', () {
      final response = <String, dynamic>{};
      expect(MonerisErrorHandler.validateReceiptResponse(response),
          'No transaction details received from server');
    });

    test('validateReceiptResponse returns error when transactionDetails is empty', () {
      final response = {'transactionDetails': <String, dynamic>{}};
      expect(MonerisErrorHandler.validateReceiptResponse(response),
          'Empty transaction details received');
    });
  });

  group('PaymentStatus and Extensions', () {
    test('PaymentStatus names match expected identifiers', () {
      expect(PaymentStatus.initializing.name, 'initializing');
      expect(PaymentStatus.preloadInProgress.name, 'preloadInProgress');
      expect(PaymentStatus.preloadFailed.name, 'preloadFailed');
      expect(PaymentStatus.webviewLoading.name, 'webviewLoading');
      expect(PaymentStatus.webviewReady.name, 'webviewReady');
      expect(PaymentStatus.paymentInProgress.name, 'paymentInProgress');
      expect(PaymentStatus.paymentCompleted.name, 'paymentCompleted');
      expect(PaymentStatus.paymentFailed.name, 'paymentFailed');
      expect(PaymentStatus.paymentCancelled.name, 'paymentCancelled');
      expect(PaymentStatus.receiptFetching.name, 'receiptFetching');
      expect(PaymentStatus.receiptFailed.name, 'receiptFailed');
    });

    test('PaymentStatus isError identifies error states accurately', () {
      expect(PaymentStatus.preloadFailed.isError, isTrue);
      expect(PaymentStatus.paymentFailed.isError, isTrue);
      expect(PaymentStatus.receiptFailed.isError, isTrue);
      expect(PaymentStatus.paymentCompleted.isError, isFalse);
      expect(PaymentStatus.initializing.isError, isFalse);
    });

    test('PaymentStatus isSuccess identifies successful state', () {
      expect(PaymentStatus.paymentCompleted.isSuccess, isTrue);
      expect(PaymentStatus.paymentFailed.isSuccess, isFalse);
      expect(PaymentStatus.initializing.isSuccess, isFalse);
    });

    test('PaymentStatus isLoading identifies loading states accurately', () {
      expect(PaymentStatus.initializing.isLoading, isTrue);
      expect(PaymentStatus.preloadInProgress.isLoading, isTrue);
      expect(PaymentStatus.webviewLoading.isLoading, isTrue);
      expect(PaymentStatus.receiptFetching.isLoading, isTrue);
      expect(PaymentStatus.webviewReady.isLoading, isFalse);
      expect(PaymentStatus.paymentCompleted.isLoading, isFalse);
    });
  });

  group('MonerisHtmlTemplates', () {
    test('buildCheckoutPage generates QA mode and test JS in test mode', () {
      final html = MonerisHtmlTemplates.buildCheckoutPage(
        isTestMode: true,
        ticket: 'TEST_TICKET_123',
      );

      expect(html, contains('https://gatewayt.moneris.com/chkt/js/chkt_v1.00.js'));
      expect(html, contains('mode: "qa"'));
      expect(html, contains('ticket: "TEST_TICKET_123"'));
      expect(html, contains('Content-Security-Policy'));
      expect(html, contains('monerisFlutterChannel'));
    });

    test('buildCheckoutPage generates prod mode and live JS in production mode', () {
      final html = MonerisHtmlTemplates.buildCheckoutPage(
        isTestMode: false,
        ticket: 'PROD_TICKET_456',
      );

      expect(html, contains('https://gateway.moneris.com/chkt/js/chkt_v1.00.js'));
      expect(html, contains('mode: "prod"'));
      expect(html, contains('ticket: "PROD_TICKET_456"'));
    });

    test('buildIframeCheckoutPage generates fallback iframe', () {
      final html = MonerisHtmlTemplates.buildIframeCheckoutPage(
        isTestMode: true,
        ticket: 'IFRAME_TICKET_789',
      );

      expect(html, contains('<iframe'));
      expect(html, contains('IFRAME_TICKET_789'));
      expect(html, contains('gatewayt.moneris.com'));
    });

    test('buildErrorPage formats given error message', () {
      final html = MonerisHtmlTemplates.buildErrorPage('Payment token expired');
      expect(html, contains('Payment token expired'));
      expect(html, contains('Try Again'));
    });
  });
}