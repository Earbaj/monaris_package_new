/// Payment status tracking for better state management
enum PaymentStatus {
  initializing,
  preloadInProgress,
  preloadFailed,
  webviewLoading,
  webviewReady,
  paymentInProgress,
  paymentCompleted,
  paymentFailed,
  paymentCancelled,
  receiptFetching,
  receiptFailed
}

/// Extension for enum utilities
extension PaymentStatusExtension on PaymentStatus {
  String get name {
    switch (this) {
      case PaymentStatus.initializing:
        return 'initializing';
      case PaymentStatus.preloadInProgress:
        return 'preloadInProgress';
      case PaymentStatus.preloadFailed:
        return 'preloadFailed';
      case PaymentStatus.webviewLoading:
        return 'webviewLoading';
      case PaymentStatus.webviewReady:
        return 'webviewReady';
      case PaymentStatus.paymentInProgress:
        return 'paymentInProgress';
      case PaymentStatus.paymentCompleted:
        return 'paymentCompleted';
      case PaymentStatus.paymentFailed:
        return 'paymentFailed';
      case PaymentStatus.paymentCancelled:
        return 'paymentCancelled';
      case PaymentStatus.receiptFetching:
        return 'receiptFetching';
      case PaymentStatus.receiptFailed:
        return 'receiptFailed';
    }
  }

  bool get isError {
    return this == PaymentStatus.preloadFailed ||
        this == PaymentStatus.paymentFailed ||
        this == PaymentStatus.receiptFailed;
  }

  bool get isSuccess {
    return this == PaymentStatus.paymentCompleted;
  }

  bool get isLoading {
    return this == PaymentStatus.initializing ||
        this == PaymentStatus.preloadInProgress ||
        this == PaymentStatus.webviewLoading ||
        this == PaymentStatus.receiptFetching;
  }
}