import 'dart:async';

import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

/// Error Handler for Moneris Payment
class MonerisErrorHandler {
  /// Handles different types of errors with appropriate messages
  static String handleError(dynamic error, [StackTrace? stackTrace]) {
    if (error is http.ClientException) {
      return 'Network error: ${error.message}';
    } else if (error is TimeoutException) {
      return 'Request timed out. Please check your internet connection and try again.';
    } else if (error is FormatException) {
      return 'Invalid response format from server. Please try again.';
    } else if (error is String) {
      return error;
    } else {
      developer.log('Unexpected error: $error\nStack trace: $stackTrace',
          name: 'MonerisPayment', error: error);
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Validates preload response data
  static String? validatePreloadResponse(Map<String, dynamic> response) {
    if (response['ticket'] == null) {
      return 'No ticket received from payment server';
    }

    final ticket = response['ticket'].toString();
    if (ticket.isEmpty) {
      return 'Empty ticket received from payment server';
    }

    return null;
  }

  /// Validates receipt response data
  static String? validateReceiptResponse(Map<String, dynamic> response) {
    if (response['transactionDetails'] == null) {
      return 'No transaction details received from server';
    }

    final transactionDetails = response['transactionDetails'] as Map<String, dynamic>?;
    if (transactionDetails == null || transactionDetails.isEmpty) {
      return 'Empty transaction details received';
    }

    return null;
  }

  /// Logs errors with consistent formatting
  static void logError(String message, {dynamic error, StackTrace? stackTrace}) {
    developer.log('🔴 MonerisPayment: $message',
        name: 'MonerisPayment',
        error: error,
        stackTrace: stackTrace);
  }

  /// Logs informational messages
  static void logInfo(String message, {bool enableDebugLogs = false}) {
    if (enableDebugLogs) {
      developer.log('🔵 MonerisPayment: $message', name: 'MonerisPayment');
    }
  }
}