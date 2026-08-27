import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// WebView-based payment screen for server-side integrations.
/// This screen loads a payment gateway URL and handles the result.
class WebViewPaymentScreen extends StatefulWidget {
  final String paymentUrl;
  final String orderId;
  final double amount;

  const WebViewPaymentScreen({
    Key? key,
    required this.paymentUrl,
    required this.orderId,
    required this.amount,
  }) : super(key: key);

  @override
  State<WebViewPaymentScreen> createState() => _WebViewPaymentScreenState();
}

class _WebViewPaymentScreenState extends State<WebViewPaymentScreen> {
  late WebViewController _webViewController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          setState(() => _isLoading = true);
          _checkPaymentCallback(url);
        },
        onPageFinished: (url) {
          setState(() => _isLoading = false);
        },
        onWebResourceError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${error.description}')),
          );
        },
      ))
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _checkPaymentCallback(String url) {
    // Check if this is a success or failure callback URL.
    // Customize these patterns based on your payment provider's callback URLs.
    if (url.contains('success') || url.contains('status=success')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment successful!')),
      );
      Navigator.pop(context, true);
    } else if (url.contains('failure') || url.contains('status=failed')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment failed. Please try again.')),
      );
      Navigator.pop(context, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await _webViewController.canGoBack()) {
          await _webViewController.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Pay ${widget.amount} PKR'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context, false),
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _webViewController),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
