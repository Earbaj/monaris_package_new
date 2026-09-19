## 1.0.4

- **Security & Privacy Improvements**:
  - Fixed iOS App Transport Security (ATS) documentation to remove unsafe global `NSAllowsArbitraryLoads: true` and recommend TLS/HTTPS with domain-specific exceptions.
  - Removed deprecated iOS `io.flutter.embedded_views_preview` setting.
- **Documentation & Links**:
  - Replaced repository and issues placeholders with active repository links (`Earbaj/monaris_package_new`).
  - Fixed broken `mailto` link in documentation.
  - Added missing `dart:math` import in README code samples.
  - Added server-side payment verification and security best practices guide.
  - Updated Android SDK documentation recommendations to compileSdk/targetSdk 34 and minSdk 21.
- **Features & Enhancements**:
  - Added configurable cancel button support (`cancelButtonText`, `showCancelButtonOnLoading`, `showCancelButtonOnPayment`) to `MonerisPaymentWidget`.
  - Added full example project in `example/` directory.
  - Added comprehensive unit and widget tests covering error handler, payment status, and HTML templates.
  - Cleaned up unused legacy code from package source.
- **Dependencies & Metadata**:
  - Upgraded `flutter_lints` to `^5.0.0`.
  - Added `repository`, `homepage`, `issue_tracker`, and `topics` to `pubspec.yaml` for pub.dev points.

## 1.0.3

- Version release with initial updates.

## 1.0.2

- Updated README documentation and fixed callback parsing issues.
- Enhanced transaction details parsing and structured response formatting.
- Added support for card brand detection (Visa, MasterCard, Amex, Discover).
- Improved error handling for nested and double-encoded JSON callbacks.

## 1.0.1

- Updated README file with integration tutorials and setup guidelines.
- Fixed minor WebView navigation handling issues on iOS and Android.

## 1.0.0

- Initial release.
- Complete Moneris Checkout integration.
- Support for test (QA) and production environments.
- Comprehensive error handling, status tracking, and callbacks.
- Cross-platform compatibility (Android & iOS).
- Tokenization support for recurring payments.
- Customizable UI with cancel callbacks and loading states.
- Dynamic transaction data handling.