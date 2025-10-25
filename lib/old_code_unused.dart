// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:webview_flutter_android/webview_flutter_android.dart';
// import 'dart:convert';
// import 'dart:io';
//
// /// A user-friendly widget for Moneris payment integration.
// ///
// /// Allows configuration of server URLs and transaction details.
// /// Handles preload, WebView display, receipt fetching, and callbacks.
// class MonerisPaymentWidget extends StatefulWidget {
//   /// URL for preload endpoint (e.g., 'http://your-server.com/preload')
//   final String preloadUrl;
//
//   /// URL for receipt endpoint (e.g., 'http://your-server.com/receipt')
//   final String receiptUrl;
//
//   /// Transaction total amount
//   final double txnTotal;
//
//   /// Order number
//   final String orderNo;
//
//   /// Customer ID
//   final String custId;
//
//   /// Customer email
//   final String email;
//
//   /// Callback on payment success with transaction details
//   final Function(Map<String, dynamic> details)? onSuccess;
//
//   /// Callback on error with message
//   final Function(String error)? onError;
//
//   /// Callback on transaction cancel
//   final VoidCallback? onCancel;
//
//   /// Optional: Test mode (default true)
//   final bool isTestMode;
//
//   const MonerisPaymentWidget({
//     super.key,
//     required this.preloadUrl,
//     required this.receiptUrl,
//     required this.txnTotal,
//     required this.orderNo,
//     required this.custId,
//     required this.email,
//     this.onSuccess,
//     this.onError,
//     this.onCancel,
//     this.isTestMode = true,
//   });
//
//   @override
//   _MonerisPaymentWidgetState createState() => _MonerisPaymentWidgetState();
// }
//
// class _MonerisPaymentWidgetState extends State<MonerisPaymentWidget> {
//   late WebViewController _controller;
//   String? _ticket;
//   bool _isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setBackgroundColor(const Color(0x00000000))
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           onProgress: (int progress) {
//             // Optional: Show progress
//           },
//           onPageStarted: (String url) {},
//           onPageFinished: (String url) {},
//           onWebResourceError: (WebResourceError error) {
//             widget.onError?.call('WebView error: ${error.description}');
//           },
//         ),
//       )
//       ..addJavaScriptChannel(
//         'flutterChannel',
//         onMessageReceived: (JavaScriptMessage message) {
//           _handleCallback(message.message);
//         },
//       );
//
//     //_configurePlatformSpecifics();
//
//     _getTicketAndLoadMCO();
//   }
//
//   // Optional: Platform-specific configuration for advanced features
//   void _configurePlatformSpecifics() async {
//     if (Platform.isAndroid) {
//       // For Android-specific features, you can cast the platform controller
//       // final androidController = _controller.platform as AndroidWebViewController?;
//       // if (androidController != null) {
//       //   await androidController.setMediaPlaybackRequiresUserGesture(false);
//       // }
//     } else if (Platform.isIOS) {
//       // For iOS-specific features
//       // final iosController = _controller.platform as IOSWebViewController?;
//       // if (iosController != null) {
//       //   await iosController.setAllowsInlineMediaPlayback(true);
//       // }
//     }
//   }
//
//   Future<void> _getTicketAndLoadMCO() async {
//     try {
//       final response = await http.post(
//         Uri.parse(widget.preloadUrl),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           'txn_total': widget.txnTotal,
//           'order_no': widget.orderNo,
//           'cust_id': widget.custId,
//           'contact_details': {
//             'email': widget.email,
//           },
//         }),
//       );
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         setState(() {
//           _ticket = data['ticket'];
//           _isLoading = false;
//         });
//         _loadMCOInWebView();
//       } else {
//         final error = jsonDecode(response.body)['error'];
//         widget.onError?.call('Preload failed: ${jsonEncode(error)}');
//       }
//     } catch (e) {
//       widget.onError?.call('Error: $e');
//     }
//   }
//
//   void _loadMCOInWebView() {
//     if (_ticket == null) return;
//
//     final String monerisJsUrl = widget.isTestMode
//         ? 'https://gatewayt.moneris.com/chkt/js/chkt_v1.00.js'
//         : 'https://gateway.moneris.com/chkt/js/chkt_v1.00.js';
//     final String mode = widget.isTestMode ? 'qa' : 'prod';
//
//     final String html = '''
//       <!DOCTYPE html>
//       <html>
//         <head>
//           <script src="$monerisJsUrl"></script>
//         </head>
//         <body>
//           <div id="monerisCheckout" style="width:100%; height:100vh;"></div>
//           <script>
//             var myCheckout = new monerisCheckout();
//             myCheckout.setMode("$mode");
//             myCheckout.setCheckoutDiv("monerisCheckout");
//
//             myCheckout.setCallback("page_loaded", function(data) { flutterChannel.postMessage(JSON.stringify(data)); });
//             myCheckout.setCallback("cancel_transaction", function(data) { flutterChannel.postMessage(JSON.stringify(data)); });
//             myCheckout.setCallback("error_event", function(data) { flutterChannel.postMessage(JSON.stringify(data)); });
//             myCheckout.setCallback("payment_receipt", function(data) { flutterChannel.postMessage(JSON.stringify(data)); });
//             myCheckout.setCallback("payment_complete", function(data) { flutterChannel.postMessage(JSON.stringify(data)); });
//
//             myCheckout.startCheckout("$_ticket");
//           </script>
//         </body>
//       </html>
//     ''';
//
//     _controller.loadHtmlString(html);
//   }
//
//   // Future<void> _handleCallback(String message) async {
//   //   final data = jsonDecode(message);
//   //   final handler = data['handler'];
//   //   final ticket = data['ticket'];
//   //   final responseCode = data['response_code'];
//   //
//   //   if (handler == 'payment_complete' && responseCode == '001') {
//   //     try {
//   //       final response = await http.post(
//   //         Uri.parse(widget.receiptUrl),
//   //         headers: {'Content-Type': 'application/json'},
//   //         body: jsonEncode({'ticket': ticket}),
//   //       );
//   //
//   //       if (response.statusCode == 200) {
//   //         final receiptData = jsonDecode(response.body)['transactionDetails'];
//   //         final transactionDetails = {
//   //           'ticket': ticket,
//   //           'transaction_no': receiptData['transaction_no'],
//   //           'card_type': receiptData['card_type'],
//   //           'first6last4': receiptData['first6last4'],
//   //           'expiry_date': receiptData['expiry_date'],
//   //           'amount': receiptData['amount'],
//   //           'response_code': receiptData['response_code'],
//   //           'result': receiptData['result'],
//   //           'data_key': receiptData['tokenize']?['data_key'],
//   //         };
//   //
//   //         widget.onSuccess?.call(transactionDetails);
//   //       } else {
//   //         widget.onError?.call('Receipt fetch failed: ${response.body}');
//   //       }
//   //     } catch (e) {
//   //       widget.onError?.call('Error fetching receipt: $e');
//   //     }
//   //   } else if (handler == 'cancel_transaction') {
//   //     widget.onCancel?.call();
//   //   } else if (handler == 'error_event') {
//   //     widget.onError?.call('Error: $responseCode');
//   //   }
//   //
//   //   await _controller.runJavaScript('myCheckout.closeCheckout("$ticket");');
//   // }
//
//   Future<void> _handleCallback(String message) async {
//     print('=== MONERIS CALLBACK START ===');
//     print('Raw message: $message');
//
//     try {
//       // Handle double-encoded JSON (message might be a JSON string wrapped in quotes)
//       dynamic data;
//
//       // First, try to parse the message directly
//       try {
//         data = jsonDecode(message);
//         print('First parse result: $data');
//         print('First parse type: ${data.runtimeType}');
//       } catch (e) {
//         print('First parse failed: $e');
//         widget.onError?.call('Invalid JSON received: $e');
//         return;
//       }
//
//       // If the first parse returns a String, it means we have double-encoded JSON
//       if (data is String) {
//         print('Detected double-encoded JSON, parsing again...');
//         try {
//           data = jsonDecode(data);
//           print('Second parse result: $data');
//           print('Second parse type: ${data.runtimeType}');
//         } catch (e) {
//           print('Second parse failed: $e');
//           widget.onError?.call('Invalid nested JSON: $e');
//           return;
//         }
//       }
//
//       // Now data should be a Map, but let's verify
//       if (data is! Map) {
//         print('❌ Data is not a Map after parsing. Type: ${data.runtimeType}');
//         widget.onError?.call('Unexpected data format: ${data.runtimeType}');
//         return;
//       }
//
//       // Convert to Map<String, dynamic> for safe access
//       final Map<String, dynamic> callbackData = Map<String, dynamic>.from(data);
//       print('Final parsed data: $callbackData');
//       print('Data keys: ${callbackData.keys.toList()}');
//
//       // Safely extract values with null checks
//       final handler = callbackData['handler'] as String?;
//       final ticket = callbackData['ticket'] as String?;
//
//       // response_code might be a string or int, so handle both
//       dynamic responseCode = callbackData['response_code'];
//       if (responseCode != null) {
//         responseCode = responseCode.toString();
//       }
//
//       print('Handler: $handler');
//       print('Ticket: $ticket');
//       print('Response Code: $responseCode');
//
//       // Check if we have the required data
//       if (handler == null || ticket == null) {
//         print('❌ Missing required data: handler=$handler, ticket=$ticket');
//         widget.onError?.call('Invalid callback data received');
//         return;
//       }
//
//       // Handle different callback types
//       if (handler == 'payment_complete' && responseCode == '001') {
//         print('🟢 Payment completed successfully, fetching receipt...');
//         await _handleSuccessfulPayment(ticket);
//       } else if (handler == 'payment_receipt' && responseCode == '001') {
//         print('🟢 Payment receipt received with success code, fetching receipt...');
//         await _handleSuccessfulPayment(ticket);
//       } else if (handler == 'cancel_transaction') {
//         print('⚠️ CANCELLED: User cancelled transaction');
//         widget.onCancel?.call();
//       } else if (handler == 'error_event') {
//         print('🔴 ERROR: Moneris error event - $responseCode');
//         widget.onError?.call('Payment Error: $responseCode');
//       } else if (handler == 'page_loaded') {
//         print('📄 Moneris page loaded successfully');
//       } else if (handler == 'payment_receipt') {
//         print('📄 Payment receipt received (non-success code: $responseCode)');
//       } else {
//         print('🔵 Other handler: $handler with code: $responseCode');
//       }
//
//     } catch (e, stackTrace) {
//       print('❌ ERROR parsing callback message: $e');
//       print('❌ Stack trace: $stackTrace');
//       widget.onError?.call('Error parsing callback: $e');
//     }
//
//     print('=== MONERIS CALLBACK END ===');
//   }
//
//   Future<void> _handleSuccessfulPayment(String ticket) async {
//     try {
//       final response = await http.post(
//         Uri.parse(widget.receiptUrl),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({'ticket': ticket}),
//       );
//
//       print('Receipt API Response Status: ${response.statusCode}');
//       print('Receipt API Response Body: ${response.body}');
//
//       if (response.statusCode == 200) {
//         final responseData = jsonDecode(response.body);
//         print('Receipt response data: $responseData');
//
//         // Safely extract transactionDetails
//         final transactionDetails = responseData['transactionDetails'] as Map<String, dynamic>?;
//
//         if (transactionDetails == null) {
//           print('❌ transactionDetails is null in response');
//           widget.onError?.call('No transaction details received');
//           return;
//         }
//
//         final result = {
//           'ticket': ticket,
//           'transaction_no': transactionDetails['transaction_no']?.toString() ?? 'N/A',
//           'card_type': transactionDetails['card_type']?.toString() ?? 'N/A',
//           'first6last4': transactionDetails['first6last4']?.toString() ?? 'N/A',
//           'expiry_date': transactionDetails['expiry_date']?.toString() ?? 'N/A',
//           'amount': transactionDetails['amount']?.toString() ?? 'N/A',
//           'response_code': transactionDetails['response_code']?.toString() ?? 'N/A',
//           'result': transactionDetails['result']?.toString() ?? 'N/A',
//           'data_key': transactionDetails['tokenize']?['data_key']?.toString(),
//         };
//
//         print('✅ SUCCESS: Calling onSuccess callback');
//         print('✅ Transaction Details: $result');
//         widget.onSuccess?.call(result);
//       } else {
//         print('❌ Receipt fetch failed with status: ${response.statusCode}');
//         widget.onError?.call('Receipt fetch failed: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('❌ Error fetching receipt: $e');
//       widget.onError?.call('Error fetching receipt: $e');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: double.infinity,
//       width: double.infinity,
//       child: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : WebViewWidget(controller: _controller),
//     );
//   }
// }