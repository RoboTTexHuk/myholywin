import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class HelpLite extends StatefulWidget {
  const HelpLite({super.key});

  @override
  State<HelpLite> createState() => _HelpLiteState();
}

class _HelpLiteState extends State<HelpLite> {
  InAppWebViewController? _wvc;
  bool _ld = true;

  Future<bool> _goBackInWebViewIfPossible() async {
    if (_wvc == null) return false;
    try {
      final canBack = await _wvc!.canGoBack();
      if (canBack) {
        await _wvc!.goBack();
        return true;
      }
    } catch (_) {}
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final handled = await _goBackInWebViewIfPossible();
        return handled ? false : false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,

        body: SafeArea(
          child: Stack(
            children: [
              InAppWebView(
                initialFile: 'assets/holywin.html',
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  supportZoom: false,
                  disableHorizontalScroll: false,
                  disableVerticalScroll: false,
                  transparentBackground: true,
                  mediaPlaybackRequiresUserGesture: false,
                  disableDefaultErrorPage: true,
                  allowsInlineMediaPlayback: true,
                  allowsPictureInPictureMediaPlayback: true,
                  useOnDownloadStart: true,
                  javaScriptCanOpenWindowsAutomatically: true,
                ),
                onWebViewCreated: (controller) => _wvc = controller,
                onLoadStart: (controller, url) => setState(() => _ld = true),
                onLoadStop: (controller, url) async => setState(() => _ld = false),
                onLoadError: (controller, url, code, message) =>
                    setState(() => _ld = false),
              ),

            ],
          ),
        ),
      ),
    );
  }
}