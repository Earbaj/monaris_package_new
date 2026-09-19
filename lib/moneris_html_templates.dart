/// HTML Template Manager for Moneris Checkout
class MonerisHtmlTemplates {
  /// Builds the complete HTML page for Moneris Checkout
  static String buildCheckoutPage({
    required bool isTestMode,
    required String ticket,
  }) {
    final monerisJsUrl = _getMonerisJsUrl(isTestMode);
    final mode = isTestMode ? 'qa' : 'prod';

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Moneris Checkout</title>
    ${_getContentSecurityPolicy()}
    ${_getStyles()}
    ${_getPreloadScripts()}
    <script src="$monerisJsUrl"></script>
</head>
<body>
    ${_getBodyContent()}
    ${_getJavaScript(mode: mode, ticket: ticket)}
</body>
</html>
    ''';
  }

  /// Content Security Policy to allow Moneris scripts
  static String _getContentSecurityPolicy() {
    return '''
    <meta http-equiv="Content-Security-Policy" content="
      default-src 'self' https://gatewayt.moneris.com https://gateway.moneris.com https://www.google.com https://www.gstatic.com;
      script-src 'self' 'unsafe-inline' 'unsafe-eval' https://gatewayt.moneris.com https://gateway.moneris.com https://www.google.com https://www.gstatic.com;
      style-src 'self' 'unsafe-inline' https://gatewayt.moneris.com https://gateway.moneris.com https://fonts.googleapis.com;
      img-src 'self' data: https: http:;
      font-src 'self' https://fonts.gstatic.com;
      connect-src 'self' https://gatewayt.moneris.com https://gateway.moneris.com;
      frame-src 'self' https://gatewayt.moneris.com https://gateway.moneris.com;
    ">
    ''';
  }

  /// Preload critical scripts to avoid CSP issues
  static String _getPreloadScripts() {
    return '''
    <link rel="preconnect" href="https://gatewayt.moneris.com">
    <link rel="preconnect" href="https://gateway.moneris.com">
    <link rel="dns-prefetch" href="https://gatewayt.moneris.com">
    <link rel="dns-prefetch" href="https://gateway.moneris.com">
    ''';
  }

  /// Gets the appropriate Moneris JS URL based on environment
  static String _getMonerisJsUrl(bool isTestMode) {
    return isTestMode
        ? 'https://gatewayt.moneris.com/chkt/js/chkt_v1.00.js'
        : 'https://gateway.moneris.com/chkt/js/chkt_v1.00.js';
  }

  /// Returns CSS styles for the checkout page
  static String _getStyles() {
    return '''
    <style>
        body { 
            margin: 0; 
            padding: 0; 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #f5f5f5;
            -webkit-font-smoothing: antialiased;
        }
        #monerisCheckout { 
            width: 100%; 
            height: 100vh; 
            min-height: 500px;
        }
        .loading-container { 
            display: flex; 
            justify-content: center; 
            align-items: center; 
            height: 100vh; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            flex-direction: column;
        }
        .loading-spinner {
            border: 3px solid #f3f3f3;
            border-top: 3px solid #3498db;
            border-radius: 50%;
            width: 40px;
            height: 40px;
            animation: spin 1s linear infinite;
            margin-bottom: 16px;
        }
        .loading-text {
            font-size: 18px;
            font-weight: 500;
            margin-bottom: 8px;
        }
        .loading-subtext {
            font-size: 14px;
            opacity: 0.8;
        }
        .error-container {
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            background: #ff6b6b;
            color: white;
            flex-direction: column;
            text-align: center;
            padding: 20px;
        }
        .error-icon {
            font-size: 48px;
            margin-bottom: 16px;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
    </style>
    ''';
  }

  /// Returns the HTML body content
  static String _getBodyContent() {
    return '''
    <div id="monerisCheckout"></div>
    <div id="loading" class="loading-container">
        <div class="loading-spinner"></div>
        <div class="loading-text">Initializing Secure Payment</div>
        <div class="loading-subtext">Please wait while we load the payment interface</div>
    </div>
    <div id="error" class="error-container" style="display: none;">
        <div class="error-icon">⚠️</div>
        <div style="font-size: 18px; font-weight: 500; margin-bottom: 8px;">
            Payment Service Unavailable
        </div>
        <div style="font-size: 14px; opacity: 0.8;">
            We're unable to load the payment interface at the moment. Please try again later.
        </div>
    </div>
    ''';
  }

  /// Returns the JavaScript code for Moneris integration
  static String _getJavaScript({
    required String mode,
    required String ticket,
  }) {
    return '''
    <script>
        // Moneris Checkout Configuration and Initialization
        const MONERIS_CONFIG = {
            mode: "$mode",
            ticket: "$ticket",
            checkoutDivId: "monerisCheckout",
            loadingDivId: "loading",
            errorDivId: "error",
            flutterChannel: "monerisFlutterChannel"
        };

        /**
         * Initializes Moneris Checkout with error handling
         */
        function initializeMonerisCheckout() {
            try {
                // Validate that Moneris library is loaded
                if (typeof monerisCheckout === 'undefined') {
                    throw new Error('Moneris checkout library not loaded');
                }

                // Create checkout instance
                const checkout = new monerisCheckout();
                
                // Configure checkout
                checkout.setMode(MONERIS_CONFIG.mode);
                checkout.setCheckoutDiv(MONERIS_CONFIG.checkoutDivId);

                // Set up event callbacks
                setupCheckoutCallbacks(checkout);
                
                // Start the checkout process
                checkout.startCheckout(MONERIS_CONFIG.ticket);
                
                console.log('Moneris checkout initialized successfully');
                
            } catch (error) {
                handleCheckoutError(error);
            }
        }

        /**
         * Sets up all required Moneris checkout callbacks
         */
        function setupCheckoutCallbacks(checkout) {
            // Page loaded successfully
            checkout.setCallback("page_loaded", function(data) {
                hideLoadingScreen();
                logEvent('Page loaded', data);
                postToFlutter(data);
            });
            
            // User cancelled the transaction
            checkout.setCallback("cancel_transaction", function(data) {
                logEvent('Transaction cancelled', data);
                postToFlutter(data);
            });
            
            // Error occurred during payment
            checkout.setCallback("error_event", function(data) {
                logEvent('Payment error', data);
                postToFlutter(data);
            });
            
            // Payment receipt received
            checkout.setCallback("payment_receipt", function(data) {
                logEvent('Payment receipt', data);
                postToFlutter(data);
            });
            
            // Payment completed successfully
            checkout.setCallback("payment_complete", function(data) {
                logEvent('Payment complete', data);
                postToFlutter(data);
            });
        }

        /**
         * Handles checkout initialization errors
         */
        function handleCheckoutError(error) {
            console.error('Moneris checkout initialization failed:', error);
            
            // Hide loading screen and show error
            hideLoadingScreen();
            showErrorScreen();
            
            // Notify Flutter about the error
            postToFlutter({
                handler: 'error_event',
                error: 'Checkout initialization failed: ' + error.message,
                timestamp: new Date().toISOString()
            });
        }

        /**
         * Hides the loading screen
         */
        function hideLoadingScreen() {
            const loadingDiv = document.getElementById(MONERIS_CONFIG.loadingDivId);
            if (loadingDiv) {
                loadingDiv.style.display = 'none';
            }
        }

        /**
         * Shows the error screen
         */
        function showErrorScreen() {
            const errorDiv = document.getElementById(MONERIS_CONFIG.errorDivId);
            if (errorDiv) {
                errorDiv.style.display = 'flex';
            }
        }

        /**
         * Posts data to Flutter channel
         */
        function postToFlutter(data) {
            try {
                if (window[MONERIS_CONFIG.flutterChannel]) {
                    window[MONERIS_CONFIG.flutterChannel].postMessage(JSON.stringify(data));
                } else {
                    console.warn('Flutter channel not available');
                }
            } catch (error) {
                console.error('Error posting to Flutter:', error);
            }
        }

        /**
         * Logs events for debugging
         */
        function logEvent(eventName, data) {
            console.log(`Moneris Event: \${eventName}`, data);
        }

        // Initialize checkout when Moneris script is loaded
        if (typeof monerisCheckout !== 'undefined') {
            initializeMonerisCheckout();
        } else {
            // Fallback: Check periodically if Moneris loads
            let loadAttempts = 0;
            const maxLoadAttempts = 10;
            
            const checkMonerisLoaded = setInterval(() => {
                loadAttempts++;
                
                if (typeof monerisCheckout !== 'undefined') {
                    clearInterval(checkMonerisLoaded);
                    initializeMonerisCheckout();
                } else if (loadAttempts >= maxLoadAttempts) {
                    clearInterval(checkMonerisLoaded);
                    handleCheckoutError(new Error('Moneris library failed to load after ' + maxLoadAttempts + ' attempts'));
                }
            }, 500);
        }

        // Handle any global errors
        window.addEventListener('error', function(event) {
            console.error('Global error caught:', event.error);
            postToFlutter({
                handler: 'error_event',
                error: 'Global error: ' + event.error.message,
                timestamp: new Date().toISOString()
            });
        });

        // Handle unhandled promise rejections
        window.addEventListener('unhandledrejection', function(event) {
            console.error('Unhandled promise rejection:', event.reason);
            postToFlutter({
                handler: 'error_event', 
                error: 'Unhandled promise rejection: ' + event.reason,
                timestamp: new Date().toISOString()
            });
        });
    </script>
    ''';
  }

  /// Alternative method: Load Moneris in an iframe to bypass CSP issues
  static String buildIframeCheckoutPage({
    required bool isTestMode,
    required String ticket,
  }) {
    final displayUrl = isTestMode
        ? 'https://gatewayt.moneris.com/chkt/display/index.php?tck=$ticket'
        : 'https://gateway.moneris.com/chkt/display/index.php?tck=$ticket';

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Moneris Checkout</title>
    <style>
        body, html {
            margin: 0;
            padding: 0;
            height: 100%;
            width: 100%;
            overflow: hidden;
        }
        #monerisFrame {
            width: 100%;
            height: 100vh;
            border: none;
        }
        .loading {
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            font-family: -apple-system, BlinkMacSystemFont, sans-serif;
            background: #f5f5f5;
        }
    </style>
</head>
<body>
    <iframe 
        id="monerisFrame" 
        src="$displayUrl" 
        sandbox="allow-scripts allow-forms allow-same-origin allow-popups"
        allow="payment"
        loading="eager">
    </iframe>
    
    <script>
        // Listen for messages from the iframe
        window.addEventListener('message', function(event) {
            // Forward messages from Moneris iframe to Flutter
            if (event.data && typeof event.data === 'object') {
                window.monerisFlutterChannel.postMessage(JSON.stringify(event.data));
            }
        });

        // Handle iframe load events
        document.getElementById('monerisFrame').addEventListener('load', function() {
            console.log('Moneris iframe loaded successfully');
        });

        // Handle iframe errors
        document.getElementById('monerisFrame').addEventListener('error', function() {
            console.error('Failed to load Moneris iframe');
            window.monerisFlutterChannel.postMessage(JSON.stringify({
                handler: 'error_event',
                error: 'Failed to load payment interface'
            }));
        });
    </script>
</body>
</html>
    ''';
  }

  /// Builds a simple error page for WebView fallback
  static String buildErrorPage(String errorMessage) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Payment Error</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, sans-serif;
            background: #ff6b6b;
            color: white;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            text-align: center;
            padding: 20px;
        }
        .container {
            max-width: 400px;
        }
        .icon {
            font-size: 64px;
            margin-bottom: 20px;
        }
        .title {
            font-size: 24px;
            font-weight: bold;
            margin-bottom: 16px;
        }
        .message {
            font-size: 16px;
            opacity: 0.9;
            line-height: 1.5;
        }
        .retry-button {
            background: white;
            color: #ff6b6b;
            border: none;
            padding: 12px 24px;
            border-radius: 6px;
            font-size: 16px;
            font-weight: 600;
            margin-top: 20px;
            cursor: pointer;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="icon">⚠️</div>
        <div class="title">Payment Error</div>
        <div class="message">$errorMessage</div>
        <button class="retry-button" onclick="window.monerisFlutterChannel.postMessage(JSON.stringify({handler: 'retry_requested'}))">
            Try Again
        </button>
    </div>
</body>
</html>
    ''';
  }
}