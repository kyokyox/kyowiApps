import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zikzak_inappwebview/zikzak_inappwebview.dart';
import 'web_snippet.dart';

/// Nampilin HTML tersimpan FULL LAYAR - status bar disembunyiin biar
/// bener-bener immersive, dan dirender dari data lokal (initialData)
/// jadi kebuka meski gak ada internet sama sekali.
class WebSnippetViewerPage extends StatefulWidget {
  final WebSnippet snippet;
  const WebSnippetViewerPage({super.key, required this.snippet});

  @override
  State<WebSnippetViewerPage> createState() => _WebSnippetViewerPageState();
}

class _WebSnippetViewerPageState extends State<WebSnippetViewerPage> {
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: InAppWebView(
              initialData: InAppWebViewInitialData(data: widget.snippet.html),
              initialSettings: InAppWebViewSettings(javaScriptEnabled: true),
            ),
          ),
          // Tap area kecil di pojok kiri atas buat toggle tombol back
          // (biar HTML-nya bener-bener full tanpa ada chrome yang ganggu
          // terus-terusan, tapi tetep gampang keluar kapan aja).
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => setState(() => _showControls = !_showControls),
                child: AnimatedOpacity(
                  opacity: _showControls ? 1 : 0.15,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
