import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ContactFormScreen extends ConsumerWidget {
  const ContactFormScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const String googleFormUrl =
        'https://docs.google.com/forms/d/e/1FAIpQLSejcekT2-Orb3fJ1SL2fYFvsjqWQ4CdmKXHbMFEg5SypO-lfQ/viewform?usp=sf_link';
    const String emailAddress = 'otatakeru.dev@gmail.com';

    return Scaffold(
      appBar: AppBar(
        title: const Text('問い合わせ'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 20),
            Text(
              'メールアドレス：',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            SelectableText(
              emailAddress,
              style: TextStyle(fontSize: 16, color: Colors.blue),
            ),
            SizedBox(height: 44),

            // ElevatedButton.icon(
            //   onPressed: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => WebViewScreen(url: googleFormUrl),
            //       ),
            //     );
            //   },
            //   icon: const Icon(Icons.web),
            //   label: const Text('Google Formで問い合わせ'),
            //   style: ElevatedButton.styleFrom(
            //     padding: const EdgeInsets.symmetric(vertical: 12),
            //   ),
            // ),
            // const SizedBox(height: 16),
            // ElevatedButton.icon(
            //   onPressed: () async {
            //     final Uri emailLaunchUri = Uri(
            //       scheme: 'mailto',
            //       path: emailAddress,
            //       query: encodeQueryParameters(<String, String>{
            //         'subject': 'アプリに関する問い合わせ',
            //       }),
            //     );
            //     if (await canLaunchUrl(emailLaunchUri)) {
            //       await launchUrl(emailLaunchUri);
            //     } else {
            //       ScaffoldMessenger.of(context).showSnackBar(
            //         const SnackBar(content: Text('メールアプリを開けませんでした')),
            //       );
            //     }
            //   },
            //   icon: const Icon(Icons.email),
            //   label: const Text('メールで問い合わせ'),
            //   style: ElevatedButton.styleFrom(
            //     padding: const EdgeInsets.symmetric(vertical: 12),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}

class WebViewScreen extends StatelessWidget {
  final String url;

  const WebViewScreen({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    final WebViewController controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://docs.google.com/')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(url));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Form'),
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
