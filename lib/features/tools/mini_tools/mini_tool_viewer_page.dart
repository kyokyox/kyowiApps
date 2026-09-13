import 'package:flutter/material.dart';
import 'package:zikzak_inappwebview/zikzak_inappwebview.dart';
import '../../../core/theme/app_theme.dart';

/// Nampilin 1 mini tool (halaman web) di dalam WebView - dipake buat
/// tools yang di-load dari manifest jarak jauh (jadi bisa nambah tools
/// baru tanpa update APK).
class MiniToolViewerPage extends StatefulWidget {
  final String title;
  final String url;
  const MiniToolViewerPage({super.key, required this.title, required this.url});

  @override
  State<MiniToolViewerPage> createState() => _MiniToolViewerPageState();
}

class _MiniToolViewerPageState extends State<MiniToolViewerPage> {
  bool _loading = true;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontSize: 14, color: AppColors.ink)),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.url)),
              initialSettings: InAppWebViewSettings(javaScriptEnabled: true),
              onLoadStart: (controller, url) => setState(() {
                _loading = true;
                _error = null;
              }),
              onLoadStop: (controller, url) => setState(() => _loading = false),
              onReceivedError: (controller, request, error) => setState(() {
                _loading = false;
                _error = 'Gagal muat tool ini: ${error.description}';
              }),
            ),
            if (_loading)
              const Center(child: CircularProgressIndicator(color: AppColors.cyan)),
            if (_error != null)
              Container(
                color: AppColors.bg,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(24),
                child: Text(_error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.magenta, fontSize: 13)),
              ),
          ],
        ),
      ),
    );
  }
}
