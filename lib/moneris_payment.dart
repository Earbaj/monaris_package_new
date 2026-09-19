import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';

// Import and export supporting files
export 'moneris_payment_status.dart';
export 'moneris_error_handler.dart';

import 'moneris_payment_status.dart';
import 'moneris_error_handler.dart';
import 'moneris_html_templates.dart';

/// Moneris Payment Widget for Flutter
///
/// A comprehensive payment integration widget that handles the complete
/// Moneris Checkout flow including preload, WebView display, and receipt processing.
class MonerisPaymentWidget extends StatefulWidget {
  /// URL for the preload endpoint that generates Moneris checkout ticket
  final String preloadUrl;

  /// URL for the receipt endpoint that fetches transaction details
  final String receiptUrl;

  /// Total transaction amount
  final double txnTotal;

  /// Unique order identifier
  final String orderNo;

  /// Customer identifier
  final String custId;

  /// Customer email address
  final String email;

  /// Callback triggered on successful payment completion
  final Function(Map<String, dynamic> details)? onSuccess;

  /// Callback triggered on payment error
  final Function(String error)? onError;

  /// Callback triggered when user cancels the payment process
  final VoidCallback? onCancel;

  /// Operation mode - true for test environment, false for production
  final bool isTestMode;

  /// Enable debug logging for development and troubleshooting
  final bool enableDebugLogs;

  /// Optional text for the cancel button (defaults to 'Cancel Payment')
  final String? cancelButtonText;

  /// Whether to display a cancel button during the loading state
  final bool showCancelButtonOnLoading;

  /// Whether to display a cancel button overlay while the payment page is loaded
  final bool showCancelButtonOnPayment;

  const MonerisPaymentWidget({
    super.key,
    required this.preloadUrl,
    required this.receiptUrl,
    required this.txnTotal,
    required this.orderNo,
    required this.custId,
    required this.email,
    this.onSuccess,
    this.onError,
    this.onCancel,
    this.isTestMode = true,
    this.enableDebugLogs = false,
    this.cancelButtonText,
    this.showCancelButtonOnLoading = false,
    this.showCancelButtonOnPayment = false,
  });

  @override
  MonerisPaymentWidgetState createState() => MonerisPaymentWidgetState();
}

class MonerisPaymentWidgetState extends State<MonerisPaymentWidget> {
  late WebViewController _webViewController;
  String? _checkoutTicket;
  bool _isLoading = true;
  PaymentStatus _paymentStatus = PaymentStatus.initializing;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _initializePaymentFlow();
  }

  /// Initializes the WebView controller
  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) => _log('WebView loading: $progress%'),
          onPageStarted: (String url) {
            _log('Page started loading: $url');
            _updatePaymentStatus(PaymentStatus.webviewLoading);
          },
          onPageFinished: (String url) {
            _log('Page finished loading: $url');
            _updatePaymentStatus(PaymentStatus.webviewReady);
          },
          onWebResourceError: (WebResourceError error) {
            final errorMsg = 'WebView error: ${error.description} (Error code: ${error.errorCode})';
            _logError(errorMsg);
            _handlePaymentError(errorMsg);
          },
          onNavigationRequest: (NavigationRequest request) {
            _log('Navigation request: ${request.url}');
            if (request.url.contains('moneris.com')) {
              return NavigationDecision.navigate;
            }
            _log('Blocked navigation to: ${request.url}');
            return NavigationDecision.prevent;
          },
        ),
      )
      ..addJavaScriptChannel(
        'monerisFlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          _handleMonerisCallback(message.message);
        },
      );

    _log('WebView controller initialized successfully');
  }

  /// Starts the payment flow
  void _initializePaymentFlow() {
    _updatePaymentStatus(PaymentStatus.preloadInProgress);
    _fetchCheckoutTicket();
  }

  /// Fetches the checkout ticket from preload endpoint
  Future<void> _fetchCheckoutTicket() async {
    try {
      _log('Fetching checkout ticket from: ${widget.preloadUrl}');

      final response = await http.post(
        Uri.parse(widget.preloadUrl),
        headers: _buildRequestHeaders(),
        body: jsonEncode(_buildPreloadPayload()),
      ).timeout(const Duration(seconds: 30));

      _log('Preload response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        await _handlePreloadSuccess(responseData);
      } else {
        await _handlePreloadFailure(response);
      }
    } on http.ClientException catch (e) {
      final errorMsg = MonerisErrorHandler.handleError(e, null);
      _logError(errorMsg);
      _handlePaymentError(errorMsg);
    } on TimeoutException catch (e) {
      final errorMsg = MonerisErrorHandler.handleError(e, null);
      _logError(errorMsg);
      _handlePaymentError(errorMsg);
    } catch (e, stackTrace) {
      final errorMsg = MonerisErrorHandler.handleError(e, stackTrace);
      _logError('$errorMsg\nStack trace: $stackTrace');
      _handlePaymentError(errorMsg);
    }
  }

  /// Builds headers for HTTP requests
  Map<String, String> _buildRequestHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'MonerisFlutterSDK/1.0',
    };
  }

  /// Builds the payload for preload request
  Map<String, dynamic> _buildPreloadPayload() {
    return {
      'txn_total': widget.txnTotal,
      'order_no': widget.orderNo,
      'cust_id': widget.custId,
      'contact_details': {
        'email': widget.email,
      },
      'sdk_info': {
        'sdk_type': 'flutter',
        'sdk_version': '1.0.0',
        'test_mode': widget.isTestMode,
      },
    };
  }

  /// Handles successful preload response
  Future<void> _handlePreloadSuccess(Map<String, dynamic> responseData) async {
    try {
      // Validate response
      final validationError = MonerisErrorHandler.validatePreloadResponse(responseData);
      if (validationError != null) {
        throw FormatException(validationError);
      }

      final ticket = responseData['ticket'] as String;

      setState(() {
        _checkoutTicket = ticket;
        _isLoading = false;
      });

      _log('Checkout ticket received successfully');
      await _loadMonerisCheckoutInWebView();

    } on FormatException catch (e) {
      final errorMsg = MonerisErrorHandler.handleError(e, null);
      _logError(errorMsg);
      _handlePaymentError(errorMsg);
    } catch (e, stackTrace) {
      final errorMsg = MonerisErrorHandler.handleError(e, stackTrace);
      _logError('$errorMsg\nStack trace: $stackTrace');
      _handlePaymentError(errorMsg);
    }
  }

  /// Handles preload failure
  Future<void> _handlePreloadFailure(http.Response response) async {
    try {
      final errorResponse = jsonDecode(response.body);
      final errorMessage = errorResponse['error']?.toString() ?? 'Unknown server error';
      final errorMsg = 'Preload failed (${response.statusCode}): $errorMessage';

      _logError(errorMsg);
      _handlePaymentError(errorMsg);
    } catch (e) {
      final errorMsg = 'Preload failed (${response.statusCode}): ${response.body}';
      _logError(errorMsg);
      _handlePaymentError(errorMsg);
    }
  }

  /// Loads Moneris checkout interface in WebView with fallback options
  Future<void> _loadMonerisCheckoutInWebView() async {
    if (_checkoutTicket == null) {
      _logError('Cannot load checkout - ticket is null');
      _handlePaymentError('Payment initialization failed');
      return;
    }

    try {
      _log('Loading Moneris checkout interface...');

      // Try the direct integration first
      final htmlContent = MonerisHtmlTemplates.buildCheckoutPage(
        isTestMode: widget.isTestMode,
        ticket: _checkoutTicket!,
      );

      await _webViewController.loadHtmlString(htmlContent);
      _log('Moneris checkout interface loaded successfully');

    } catch (e) {
      _logError('Direct integration failed, trying iframe fallback: $e');

      // Fallback to iframe approach
      try {
        final iframeHtml = MonerisHtmlTemplates.buildIframeCheckoutPage(
          isTestMode: widget.isTestMode,
          ticket: _checkoutTicket!,
        );

        await _webViewController.loadHtmlString(iframeHtml);
        _log('Moneris iframe fallback loaded successfully');

      } catch (e2, stackTrace2) {
        final errorMsg = MonerisErrorHandler.handleError(e2, stackTrace2);
        _logError('Both integration methods failed: $errorMsg');

        // Load error page as final fallback
        final errorHtml = MonerisHtmlTemplates.buildErrorPage(errorMsg);
        await _webViewController.loadHtmlString(errorHtml);
        _handlePaymentError(errorMsg);
      }
    }
  }

// Update the _handleMonerisCallback method to handle retry requests
  Future<void> _handleMonerisCallback(String message) async {
    _log('Received callback from Moneris: $message');

    try {
      final callbackData = _parseCallbackData(message);
      if (callbackData == null) return;

      final handler = callbackData['handler'] as String?;
      final ticket = callbackData['ticket'] as String?;
      final responseCode = _safeGetResponseCode(callbackData['response_code']);

      _log('Processing callback - Handler: $handler, Response Code: $responseCode');

      if (handler == null) {
        _logError('Invalid callback data - missing handler');
        return;
      }

      // Handle retry requests from error page
      if (handler == 'retry_requested') {
        _log('Retry requested by user');
        _retryPayment();
        return;
      }

      if (ticket == null) {
        _logError('Invalid callback data - missing ticket');
        return;
      }

      await _routeCallbackHandler(handler, ticket, responseCode, callbackData);

    } catch (e, stackTrace) {
      final errorMsg = MonerisErrorHandler.handleError(e, stackTrace);
      _logError('$errorMsg\nStack trace: $stackTrace');
      _handlePaymentError(errorMsg);
    }
  }

  /// Retry the payment process
  void _retryPayment() {
    _log('Retrying payment process...');
    setState(() {
      _isLoading = true;
      _paymentStatus = PaymentStatus.initializing;
    });

    // Clear the current WebView content
    _webViewController.clearCache();

    // Restart the payment flow
    _initializePaymentFlow();
  }

  /// Parses callback data
  Map<String, dynamic>? _parseCallbackData(String message) {
    try {
      dynamic data = jsonDecode(message);

      if (data is String) {
        _log('Detected double-encoded JSON, parsing again...');
        data = jsonDecode(data);
      }

      if (data is Map) {
        return Map<String, dynamic>.from(data);
      } else {
        _logError('Callback data is not a Map: ${data.runtimeType}');
        return null;
      }
    } catch (e, stackTrace) {
      _logError('Failed to parse callback data: $e\nStack trace: $stackTrace');
      return null;
    }
  }

  /// Safely extracts response code
  String? _safeGetResponseCode(dynamic responseCode) {
    if (responseCode == null) return null;
    return responseCode.toString();
  }

  /// Routes callback to appropriate handler
  Future<void> _routeCallbackHandler(
      String handler,
      String ticket,
      String? responseCode,
      Map<String, dynamic> data
      ) async {
    switch (handler) {
      case 'payment_complete':
      case 'payment_receipt':
        if (responseCode == '001') {
          await _handleSuccessfulPayment(ticket);
        } else {
          _handlePaymentError('Payment failed with code: $responseCode');
        }
        break;

      case 'cancel_transaction':
        _handlePaymentCancellation();
        break;

      case 'error_event':
        _handlePaymentError('Payment error: $responseCode');
        break;

      case 'page_loaded':
        _log('Moneris checkout page loaded successfully');
        break;

      default:
        _log('Unhandled callback type: $handler');
        break;
    }
  }

  /// Handles successful payment
  Future<void> _handleSuccessfulPayment(String ticket) async {
    _log('Payment completed successfully, fetching receipt...');
    _updatePaymentStatus(PaymentStatus.receiptFetching);

    try {
      final transactionDetails = await _fetchReceiptDetails(ticket);
      await _completePaymentSuccess(transactionDetails);
    } catch (e) {
      _logError('Failed to complete payment: $e');
      rethrow;
    }
  }

  /// Fetches receipt details
  Future<Map<String, dynamic>> _fetchReceiptDetails(String ticket) async {
    try {
      _log('Fetching receipt details for ticket: $ticket');

      final response = await http.post(
        Uri.parse(widget.receiptUrl),
        headers: _buildRequestHeaders(),
        body: jsonEncode({'ticket': ticket}),
      ).timeout(const Duration(seconds: 30));

      _log('Receipt response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        final validationError = MonerisErrorHandler.validateReceiptResponse(responseData);
        if (validationError != null) {
          throw Exception(validationError);
        }

        final transactionDetails = responseData['transactionDetails'] as Map<String, dynamic>;
        _log('Receipt fetched successfully');
        return transactionDetails;
      } else {
        throw Exception('Receipt fetch failed with status: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Receipt fetch timed out after 30 seconds');
    } catch (e) {
      _logError('Error fetching receipt: $e');
      throw Exception('Failed to fetch receipt details: $e');
    }
  }

  /// Completes payment with success
  Future<void> _completePaymentSuccess(Map<String, dynamic> transactionDetails) async {
    try {
      final result = _buildTransactionResult(transactionDetails);

      _log('Payment completed successfully: $result');
      _updatePaymentStatus(PaymentStatus.paymentCompleted);

      await _closeMonerisCheckout();
      widget.onSuccess?.call(result);

    } catch (e, stackTrace) {
      final errorMsg = MonerisErrorHandler.handleError(e, stackTrace);
      _logError('$errorMsg\nStack trace: $stackTrace');
      _handlePaymentError(errorMsg);
    }
  }

  /// Builds transaction result
  // Map<String, dynamic> _buildTransactionResult(Map<String, dynamic> transactionDetails) {
  //   return {
  //     'ticket': _checkoutTicket,
  //     'transaction_no': transactionDetails['transaction_no']?.toString() ?? 'N/A',
  //     'card_type': transactionDetails['card_type']?.toString() ?? 'N/A',
  //     'first6last4': transactionDetails['first6last4']?.toString() ?? 'N/A',
  //     'expiry_date': transactionDetails['expiry_date']?.toString() ?? 'N/A',
  //     'amount': transactionDetails['amount']?.toString() ?? 'N/A',
  //     'response_code': transactionDetails['response_code']?.toString() ?? 'N/A',
  //     'result': transactionDetails['result']?.toString() ?? 'N/A',
  //     'data_key': transactionDetails['tokenize']?['data_key']?.toString(),
  //     'timestamp': DateTime.now().toIso8601String(),
  //     'environment': widget.isTestMode ? 'test' : 'production',
  //   };
  // }

  /// Returns structured data but keeps raw data available
  Map<String, dynamic> _buildTransactionResult(Map<String, dynamic> transactionDetails) {
    return {
      // Raw data for advanced users
      'raw_data': transactionDetails,

      // Common fields for convenience (nullable)
      'transaction_id': transactionDetails['transaction_no']?.toString(),
      'transaction_no': transactionDetails['transaction_no']?.toString(),
      'reference_no': transactionDetails['reference_no']?.toString(),
      'authorization_code': transactionDetails['auth_code']?.toString(),

      // Payment method info
      'card_type': transactionDetails['card_type']?.toString(),
      'card_brand': _parseCardBrand(transactionDetails['card_type']?.toString()),
      'masked_card_number': transactionDetails['first6last4']?.toString(),
      'expiry_date': transactionDetails['expiry_date']?.toString(),

      // Amount and currency
      'amount': transactionDetails['amount']?.toString(),
      'currency': 'CAD', // Moneris typically uses CAD

      // Response codes
      'response_code': transactionDetails['response_code']?.toString(),
      'iso_code': transactionDetails['iso_code']?.toString(),
      'result_code': transactionDetails['result']?.toString(),
      'result_message': _parseResultMessage(transactionDetails['result']?.toString()),

      // Tokenization
      'token': transactionDetails['tokenize']?['data_key']?.toString(),
      'is_tokenized': transactionDetails['tokenize']?['data_key'] != null,

      // Metadata
      'ticket': _checkoutTicket,
      'timestamp': DateTime.now().toIso8601String(),
      'environment': widget.isTestMode ? 'test' : 'production',
      'success': _isTransactionSuccessful(transactionDetails),
    };
  }

  /// Helper method to parse card brand
  String? _parseCardBrand(String? cardType) {
    if (cardType == null) return null;
    final Map<String, String> cardBrands = {
      'V': 'Visa',
      'M': 'MasterCard',
      'AX': 'American Express',
      'DI': 'Discover',
      'NO': 'Novus',
      'SE': 'SE',
    };
    return cardBrands[cardType];
  }

  /// Helper method to parse result message
  String _parseResultMessage(String? resultCode) {
    const Map<String, String> resultMessages = {
      'a': 'Transaction approved',
      'd': 'Transaction declined',
      'r': 'Transaction retry',
      't': 'Transaction timeout',
    };
    return resultMessages[resultCode?.toLowerCase()] ?? 'Unknown result: $resultCode';
  }

  /// Helper method to determine if transaction was successful
  bool _isTransactionSuccessful(Map<String, dynamic> transactionDetails) {
    final result = transactionDetails['result']?.toString().toLowerCase();
    final responseCode = transactionDetails['response_code']?.toString();

    // Transaction is successful if result is 'a' (approved)
    // and response code is '001' (approved) or similar
    return result == 'a' && (responseCode == '001' || responseCode == '027');
  }

  /// Handles payment cancellation
  void _handlePaymentCancellation() {
    _log('Payment cancelled by user');
    _updatePaymentStatus(PaymentStatus.paymentCancelled);
    widget.onCancel?.call();
  }

  /// Handles payment errors
  void _handlePaymentError(String error) {
    _logError('Payment error: $error');
    _updatePaymentStatus(PaymentStatus.paymentFailed);
    widget.onError?.call(error);
  }

  /// Closes Moneris checkout
  Future<void> _closeMonerisCheckout() async {
    try {
      if (_checkoutTicket != null) {
        await _webViewController.runJavaScript('''
          if (typeof myCheckout !== 'undefined') {
            myCheckout.closeCheckout("$_checkoutTicket");
          }
        ''');
        _log('Moneris checkout closed successfully');
      }
    } catch (e) {
      _log('Note: Could not close Moneris checkout: $e');
    }
  }

  /// Updates payment status
  void _updatePaymentStatus(PaymentStatus status) {
    if (widget.enableDebugLogs) {
      _log('Payment status changed: ${_paymentStatus.name} -> ${status.name}');
    }
    setState(() {
      _paymentStatus = status;
    });
  }

  /// Logging methods
  void _log(String message) {
    MonerisErrorHandler.logInfo(message, enableDebugLogs: widget.enableDebugLogs);
  }

  void _logError(String message) {
    MonerisErrorHandler.logError(message);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      decoration: BoxDecoration(
        border: widget.enableDebugLogs
            ? Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 1)
            : null,
      ),
      child: _isLoading
          ? _buildLoadingState()
          : _buildWebViewState(),
    );
  }

  /// Builds loading state
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text(
            'Initializing Secure Payment...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          if (widget.showCancelButtonOnLoading && widget.onCancel != null) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _handlePaymentCancellation,
              icon: const Icon(Icons.close, size: 18),
              label: Text(widget.cancelButtonText ?? 'Cancel Payment'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                side: BorderSide(color: Colors.grey.shade400),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds WebView state
  Widget _buildWebViewState() {
    return Stack(
      children: [
        WebViewWidget(controller: _webViewController),
        if (widget.showCancelButtonOnPayment && widget.onCancel != null)
          Positioned(
            top: 10,
            left: 10,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _handlePaymentCancellation,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.close, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        widget.cancelButtonText ?? 'Cancel',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (widget.enableDebugLogs) ..._buildDebugOverlay(),
      ],
    );
  }

  /// Builds debug overlay
  List<Widget> _buildDebugOverlay() {
    return [
      Positioned(
        top: 10,
        right: 10,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Status: ${_paymentStatus.name}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    ];
  }

  @override
  void dispose() {
    _log('Disposing MonerisPaymentWidget...');
    super.dispose();
  }
}