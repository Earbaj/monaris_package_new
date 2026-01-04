# 💳 Moneris Payment for Flutter

<div align="center">

![Moneris Flutter](https://img.shields.io/badge/Moneris-Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Version](https://img.shields.io/badge/version-1.0.0-blue?style=for-the-badge)
![License](https://img.shields.io/badge/license-BSD_3_Clause-green?style=for-the-badge)

A modern, secure Flutter package for seamless Moneris Checkout integration.

[Getting Started](#installation) • [Examples](#flutter-usage) • [Documentation](#important-notes) • [Support](#support)

</div>

## ✨ Features

<div align="left">

🔒 **PCI-Compliant Processing**
- Secure payment handling through Moneris hosted pages
- Bank-grade security standards

🚀 **Dual Environment Support**
- Test/QA environment for development
- Production mode for live transactions

🛡️ **Error Handling & Validation**
- Comprehensive error messages
- Smart callback system
- Detailed transaction logging

💎 **Advanced Features**
- Tokenization for recurring payments
- AVS/CVD verification support
- 3D-Secure ready

🎨 **Rich UI Components**
- Customizable cancel buttons
- Loading state indicators
- Debug mode toggles

📱 **Cross-Platform**
- Full Android support
- Complete iOS compatibility
- Responsive design

📚 **Developer Experience**
- Extensive documentation
- Code examples
- Integration guides

</div>

---

## 📦 Installation

<div align="left">

1️⃣ Add to your `pubspec.yaml`:

```yaml
dependencies:
  moneris_payment: ^1.0.0
```

2️⃣ Run in your terminal:

```bash
$ flutter pub get
```

3️⃣ Import in your Dart code:

```dart
import 'package:moneris_payment/moneris_payment.dart';
```

</div>

---

## 🛠️ Platform Configuration

<details>
<summary><b>📱 Android Setup</b></summary>

1. Add permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    
    <application
        android:label="Your App Name"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
        </activity>
    </application>
</manifest>
```

2. Update `android/app/build.gradle`:

```gradle
android {
    compileSdkVersion 33
    
    defaultConfig {
        minSdkVersion 19    // Required for WebView
        targetSdkVersion 33
    }
}
```

</details>

<details>
<summary><b>🍎 iOS Setup</b></summary>

1. Update `ios/Runner/Info.plist`:

```xml
<dict>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
    <key>io.flutter.embedded_views_preview</key>
    <true/>
</dict>
```

2. Configure `ios/Podfile`:

```ruby
platform :ios, '11.0'  # Required for WebView support
```

</details>

---

## 🔌 Backend Integration

<div align="center">

![Node.js](https://img.shields.io/badge/Node.js-43853D?style=for-the-badge&logo=node.js&logoColor=white)
![PHP](https://img.shields.io/badge/PHP-777BB4?style=for-the-badge&logo=php&logoColor=white)

</div>

Two backend endpoints are required for Moneris integration:
- 🎟️ **Preload Endpoint**: Generates checkout tickets
- 📝 **Receipt Endpoint**: Fetches transaction details

> 🔐 **SECURITY ALERT**: Never expose Moneris credentials (Store ID, API Token, Checkout ID) in client-side code.

### 🎟️ Preload Endpoint

This endpoint generates a Moneris checkout ticket. The Flutter client calls this endpoint to get a `ticket` used to open the hosted Moneris page.

Node.js example (Express + axios):

```javascript
const express = require('express');
const axios = require('axios');
const app = express();

app.use(express.json());

// Your Moneris credentials
const STORE_ID = 'your_store_id';
const API_TOKEN = 'your_api_token';
const CHECKOUT_ID = 'your_checkout_id';
const MONERIS_TEST_URL = 'https://gatewayt.moneris.com/chkt/request/request.php';
const MONERIS_PROD_URL = 'https://gateway.moneris.com/chkt/request/request.php';

// Endpoint: Flutter calls this to get ticket (Preload)
app.post('/preload', async (req, res) => {
	const { 
		txn_total, 
		order_no, 
		cust_id, 
		contact_details 
	} = req.body;

	const preloadData = {
		store_id: STORE_ID,
		api_token: API_TOKEN,
		checkout_id: CHECKOUT_ID,
		txn_total: Number(txn_total).toFixed(2),
		environment: 'qa',  // 'prod' for production
		action: 'preload',
		order_no: order_no || '',
		cust_id: cust_id || '',
		contact_details: contact_details || {},
	};

	try {
		const response = await axios.post(MONERIS_TEST_URL, preloadData, {
			headers: { 'Content-Type': 'application/json' },
		});
    
		if (response.data.response.success === 'true') {
			res.json({ ticket: response.data.response.ticket });
		} else {
			res.status(400).json({ error: response.data.response.error });
		}
	} catch (error) {
		console.error('Preload error:', error);
		res.status(500).json({ error: 'Preload failed' });
	}
});
```

PHP example:

```php
<?php
// preload.php
$STORE_ID = 'your_store_id';
$API_TOKEN = 'your_api_token';
$CHECKOUT_ID = 'your_checkout_id';
$MONERIS_URL = 'https://gatewayt.moneris.com/chkt/request/request.php';

header('Content-Type: application/json');

$input = json_decode(file_get_contents('php://input'), true);

$preloadData = [
		'store_id' => $STORE_ID,
		'api_token' => $API_TOKEN,
		'checkout_id' => $CHECKOUT_ID,
		'txn_total' => number_format($input['txn_total'], 2, '.', ''),
		'environment' => 'qa',
		'action' => 'preload',
		'order_no' => $input['order_no'] ?? '',
		'cust_id' => $input['cust_id'] ?? '',
		'contact_details' => $input['contact_details'] ?? []
];

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $MONERIS_URL);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($preloadData));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

if ($response) {
		$data = json_decode($response, true);
		if ($data['response']['success'] === 'true') {
				echo json_encode(['ticket' => $data['response']['ticket']]);
		} else {
				http_response_code(400);
				echo json_encode(['error' => $data['response']['error']]);
		}
} else {
		http_response_code(500);
		echo json_encode(['error' => 'Preload failed']);
}
?>
```

### 2) Receipt Endpoint

This endpoint fetches transaction details after payment completion. The Flutter client calls this endpoint with the `ticket` returned from the hosted Moneris page.

Node.js example:

```javascript
// Endpoint: Flutter calls this after payment complete to get receipt details
app.post('/receipt', async (req, res) => {
	const { ticket } = req.body;

	const receiptData = {
		store_id: STORE_ID,
		api_token: API_TOKEN,
		checkout_id: CHECKOUT_ID,
		ticket,
		environment: 'qa',  // 'prod' for production
		action: 'receipt',
	};

	try {
		const response = await axios.post(MONERIS_TEST_URL, receiptData, {
			headers: { 'Content-Type': 'application/json' },
		});
    
		if (response.data.response.success === 'true') {
			const transactionDetails = response.data.response.receipt;
      
			// Extract important transaction details
			const result = {
				transaction_no: transactionDetails.transaction_no,
				reference_no: transactionDetails.reference_no,
				card_type: transactionDetails.card_type,
				first6last4: transactionDetails.first6last4,
				expiry_date: transactionDetails.expiry_date,
				amount: transactionDetails.amount,
				response_code: transactionDetails.response_code,
				result: transactionDetails.result,
				data_key: transactionDetails.tokenize?.data_key, // For tokenization
			};

			res.json({ transactionDetails: result });
		} else {
			res.status(400).json({ error: 'Receipt fetch failed' });
		}
	} catch (error) {
		console.error('Receipt error:', error);
		res.status(500).json({ error: 'Receipt failed' });
	}
});
```

PHP example:

```php
<?php
// receipt.php
$STORE_ID = 'your_store_id';
$API_TOKEN = 'your_api_token';
$CHECKOUT_ID = 'your_checkout_id';
$MONERIS_URL = 'https://gatewayt.moneris.com/chkt/request/request.php';

header('Content-Type: application/json');

$input = json_decode(file_get_contents('php://input'), true);
$ticket = $input['ticket'];

$receiptData = [
		'store_id' => $STORE_ID,
		'api_token' => $API_TOKEN,
		'checkout_id' => $CHECKOUT_ID,
		'ticket' => $ticket,
		'environment' => 'qa',
		'action' => 'receipt'
];

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $MONERIS_URL);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($receiptData));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

if ($response) {
		$data = json_decode($response, true);
		if ($data['response']['success'] === 'true') {
				$receipt = $data['response']['receipt'];
				$transactionDetails = [
						'transaction_no' => $receipt['transaction_no'],
						'reference_no' => $receipt['reference_no'],
						'card_type' => $receipt['card_type'],
						'first6last4' => $receipt['first6last4'],
						'expiry_date' => $receipt['expiry_date'],
						'amount' => $receipt['amount'],
						'response_code' => $receipt['response_code'],
						'result' => $receipt['result'],
						'data_key' => $receipt['tokenize']['data_key'] ?? null,
				];
				echo json_encode(['transactionDetails' => $transactionDetails]);
		} else {
				http_response_code(400);
				echo json_encode(['error' => 'Receipt fetch failed']);
		}
} else {
		http_response_code(500);
		echo json_encode(['error' => 'Receipt failed']);
}
?>
```

---

## Flutter Usage

Below are basic and advanced usage examples for integrating the `MonerisPaymentWidget` in your Flutter app.

### Basic Implementation

```dart
import 'package:flutter/material.dart';
import 'package:moneris_payment/moneris_payment.dart';

class PaymentScreen extends StatefulWidget {
	const PaymentScreen({super.key});

	@override
	State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
	String _generateOrderId() {
		final timestamp = DateTime.now().millisecondsSinceEpoch;
		final random = _generateRandomString(6);
		return 'ORD_${timestamp}_$random';
	}

	String _generateRandomString(int length) {
		const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
		final random = Random();
		return String.fromCharCodes(
			Iterable.generate(
				length, 
				(_) => chars.codeUnitAt(random.nextInt(chars.length))
			)
		);
	}

	void _showPaymentDialog(BuildContext context) {
		final orderId = _generateOrderId();
		final customerId = 'CUST_${_generateRandomString(8)}';

		showDialog(
			context: context,
			builder: (context) => AlertDialog(
				title: const Text('Complete Payment'),
				content: SizedBox(
					height: MediaQuery.of(context).size.height * 0.8,
					width: MediaQuery.of(context).size.width * 0.9,
					child: MonerisPaymentWidget(
						preloadUrl: 'https://your-backend.com/preload',
						receiptUrl: 'https://your-backend.com/receipt',
						txnTotal: 99.99,
						orderNo: orderId, // MUST be unique for each transaction
						custId: customerId, // Should identify the customer
						email: 'customer@example.com',
						isTestMode: true, // Set to false for production
						onSuccess: (details) {
							print('Payment Success: ${details['transaction_no']}');
							Navigator.pop(context);
							ScaffoldMessenger.of(context).showSnackBar(
								SnackBar(
									content: Text('Payment Successful! Transaction: ${details['transaction_no']}'),
									backgroundColor: Colors.green,
								),
							);
						},
						onError: (error) {
							print('Payment Error: $error');
							Navigator.pop(context);
							ScaffoldMessenger.of(context).showSnackBar(
								SnackBar(
									content: Text('Payment Failed: $error'),
									backgroundColor: Colors.red,
								),
							);
						},
						onCancel: () {
							print('Payment cancelled by user');
							Navigator.pop(context);
							ScaffoldMessenger.of(context).showSnackBar(
								const SnackBar(content: Text('Payment Cancelled')),
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
			appBar: AppBar(title: const Text('Payment')),
			body: Center(
				child: Column(
					mainAxisAlignment: MainAxisAlignment.center,
					children: [
						ElevatedButton(
							onPressed: () => _showPaymentDialog(context),
							child: const Text('Make Payment'),
						),
						const SizedBox(height: 20),
						const Text('Test Credit Cards:'),
						const Text('Visa: 4242424242424242'),
						const Text('Expiry: 12/25, CVD: 123'),
					],
				),
			),
		);
	}
}
```

### Advanced Implementation with Order Management

```dart
class CheckoutPage extends StatefulWidget {
	final double totalAmount;
	final String userEmail;
	final String userId;

	const CheckoutPage({
		super.key,
		required this.totalAmount,
		required this.userEmail,
		required this.userId,
	});

	@override
	State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
	late String _orderId;
	late String _customerId;

	@override
	void initState() {
		super.initState();
		_orderId = _generateOrderId();
		_customerId = 'USER_${widget.userId}';
    
		// Pre-create order in your database
		_createOrderRecord(_orderId);
	}

	String _generateOrderId() {
		final timestamp = DateTime.now().millisecondsSinceEpoch;
		final randomSuffix = Random().nextInt(9999).toString().padLeft(4, '0');
		return 'ECO_${widget.userId}_${timestamp}_$randomSuffix';
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('Checkout')),
			body: MonerisPaymentWidget(
				preloadUrl: 'https://your-backend.com/preload',
				receiptUrl: 'https://your-backend.com/receipt',
				txnTotal: widget.totalAmount,
				orderNo: _orderId,
				custId: _customerId,
				email: widget.userEmail,
				isTestMode: false, // Production mode
				enableDebugLogs: true, // Enable for debugging
				cancelButtonText: 'Cancel Order',
				showCancelButtonOnLoading: true,
				showCancelButtonOnPayment: true,
				onSuccess: (details) {
					// Update order status in your database
					_updateOrderStatus(_orderId, 'SUCCESS', details);
					Navigator.pushReplacement(
						context,
						MaterialPageRoute(
							builder: (context) => OrderConfirmationPage(
								orderId: _orderId,
								transactionDetails: details,
							),
						),
					);
				},
				onError: (error) {
					// Update order status to failed
					_updateOrderStatus(_orderId, 'FAILED', null, error);
					ScaffoldMessenger.of(context).showSnackBar(
						SnackBar(
							content: Text('Payment Failed: $error'),
							backgroundColor: Colors.red,
						),
					);
				},
				onCancel: () {
					// Update order status to cancelled
					_updateOrderStatus(_orderId, 'CANCELLED');
					Navigator.pop(context);
				},
			),
		);
	}

	void _createOrderRecord(String orderId) {
		// Implement your order creation logic
		print('Creating order: $orderId');
	}

	void _updateOrderStatus(String orderId, String status, 
												 [Map<String, dynamic>? details, String? error]) {
		// Implement your order update logic
		print('Updating order $orderId to $status');
	}
}
```

---

## Important Notes

### Order ID Requirements

- MUST be unique for each transaction
- Never reuse order IDs
- Store in your database before starting payment
- Maximum 50 characters
- Format: Alphanumeric and underscores only

### Customer ID Requirements

- Should identify the customer
- Can be user ID, session ID, or guest ID
- Maximum 50 characters

### Security Best Practices

- Keep your Moneris credentials secure on the backend
- Never expose API tokens in client-side code
- Use HTTPS in production
- Validate all input data on your backend
- Implement proper error logging

---

## 🧪 Testing

<div align="center">

### 💳 Test Credit Cards

| Card Type | Number | Expiry | CVD |
|-----------|---------|---------|-----|
| Visa | `4242 4242 4242 4242` | `12/25` | `123` |
| MasterCard | `5555 5555 5555 4444` | `12/25` | `123` |
| AMEX | `3782 822463 10005` | `12/25` | `123` |

</div>

## 🔧 Moneris Setup

<div align="left">

1. 📝 **Get Your Credentials**
    - Contact Moneris for Store ID, API Token, and Checkout ID
    - Choose between Test/Production environment

2. 🏦 **Account Setup**
    - Configure Moneris MRC for testing
    - Set up Production account for live transactions

3. 🛡️ **Security Configuration**
    - Enable AVS (Address Verification)
    - Configure CVD validation
    - Set up 3-D Secure if needed

4. 🔄 **Advanced Features**
    - Configure tokenization for recurring payments
    - Set up webhook URLs for notifications
    - Test transaction flows

</div>

## ⚠️ Troubleshooting

<details>
<summary><b>🚫 Common Issues & Solutions</b></summary>

### CSP (Content Security Policy)
- ✅ Package handles CSP errors automatically
- ✅ No additional configuration needed

### 🌐 Network Issues
- ✅ Verify backend endpoint accessibility
- ✅ Check JSON response format
- ✅ Validate SSL certificates

### 🆔 Order ID Problems
- ✅ Ensure unique IDs for each transaction
- ✅ Follow format requirements
- ✅ Verify database storage

### 💳 Payment Declined
- ✅ Use test cards in test mode
- ✅ Check Moneris dashboard
- ✅ Verify amount format

</details>

### 🐛 Debug Mode

Enable detailed logging:

```dart
MonerisPaymentWidget(
  enableDebugLogs: true,    // Enable debugging
  isTestMode: true,         // Use test environment
  // ... other parameters
)
```

---

## 💬 Support

<div align="center">

[![Discord](https://img.shields.io/discord/YOUR_DISCORD_ID?color=7289da&label=Discord&logo=discord&logoColor=white&style=for-the-badge)](https://discord.gg/YOUR_INVITE)
[![GitHub Issues](https://img.shields.io/github/issues/YOUR_REPO?style=for-the-badge)](https://github.com/YOUR_REPO/issues)

</div>

<div align="center">
  <table>
    <tr>
      <td align="center">
        <b>📧 Email Support</b><br>
        <a href="mailto:Earbaj">earbajsaria3@gmail.com</a>
      </td>
      <td align="center">
        <b>💻 GitHub Issues</b><br>
        <a href="https://github.com/YOUR_REPO/issues">Create an Issue</a>
      </td>
      <td align="center">
        <b>💭 Discord Chat</b><br>
        <a href="https://discord.gg/YOUR_INVITE">Join Community</a>
      </td>
    </tr>
  </table>
</div>

### 📋 When Reporting Issues

Please include:
- Flutter version: `flutter --version`
- Package version: `pubspec.yaml` entry
- Error logs (if any)
- Steps to reproduce
- Expected vs actual behavior

## 📜 License

<div align="center">

[![License](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg?style=for-the-badge)](LICENSE)

Copyright (c) 2026 Earbaj Md Saria

</div>

## 📝 Changelog

<details>
<summary><b>Version 1.0.0</b> - October 2024</summary>

### ✨ Initial Release

- 🎉 Complete Moneris Checkout integration
- 🔄 Test & Production environment support
- 🛡️ Comprehensive error handling
- 📱 Cross-platform compatibility
- 📚 Full documentation

### 🔨 Technical Updates

- Implemented secure payment processing
- Added callback system
- Integrated WebView handling
- Enhanced error reporting

</details>

---

<div align="center">

### Made with ❤️ for the Flutter Community

⭐ Found it helpful? Star us on GitHub! ⭐

</div>
