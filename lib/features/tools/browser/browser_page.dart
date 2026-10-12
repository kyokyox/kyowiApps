import 'dart:typed_data';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:zikzak_inappwebview/zikzak_inappwebview.dart' hide SettingsController;
import '../../../core/theme/app_theme.dart';
import '../../../core/storage/settings_controller.dart';
import '../../../core/models/app_settings.dart';
import 'adblock_list.dart';

class _BrowserTab {
  InAppWebViewController? controller;
  String title;
  String url;
  final int? windowId; // null = tab utama, ada isinya = tab hasil "buka di tab baru"
  bool loading = true;
  String? errorMessage;

  _BrowserTab({
    required this.title,
    required this.url,
    this.windowId,
  });
}

class BrowserPage extends StatefulWidget {
  final String initialUrl;
  const BrowserPage({super.key, this.initialUrl = 'https://www.google.com'});

  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage> {
  final List<_BrowserTab> _tabs = [];
  int _activeIndex = 0;
  late TextEditingController _urlController;
  bool _adBlockOn = true;
  bool _dataSaverOn = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialUrl);
    _tabs.add(_BrowserTab(title: 'Baru', url: widget.initialUrl));
  }

  void _addTab({String url = 'https://www.google.com', int? windowId}) {
    setState(() {
      _tabs.add(_BrowserTab(title: 'Baru', url: url, windowId: windowId));
      _activeIndex = _tabs.length - 1;
      _urlController.text = url;
    });
  }

  void _closeTab(int index) {
    if (_tabs.length == 1) return; // minimal 1 tab
    setState(() {
      _tabs.removeAt(index);
      if (_activeIndex >= _tabs.length) _activeIndex = _tabs.length - 1;
      _urlController.text = _tabs[_activeIndex].url;
    });
  }

  void _switchTab(int index) {
    setState(() {
      _activeIndex = index;
      _urlController.text = _tabs[index].url;
    });
  }

  void _go(String input) {
    var target = input.trim();
    if (target.isEmpty) return;
    final looksLikeUrl = target.startsWith('http://') ||
        target.startsWith('https://') ||
        (target.contains('.') && !target.contains(' '));
    if (!looksLikeUrl) {
      final engine = SettingsController.instance.settings.searchEngine;
      target = engine.urlFor(target);
    } else if (!target.startsWith('http')) {
      target = 'https://$target';
    }
    _tabs[_activeIndex].controller?.loadUrl(urlRequest: URLRequest(url: WebUri(target)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _tabBar(),
        _addressBar(),
        Expanded(
          child: IndexedStack(
            index: _activeIndex,
            children: [
              for (var i = 0; i < _tabs.length; i++) _buildWebView(i),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tabBar() {
    return Container(
      height: 40,
      color: AppColors.bg,
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _tabs.length,
              itemBuilder: (context, i) {
                final active = i == _activeIndex;
                return GestureDetector(
                  onTap: () => _switchTab(i),
                  child: Container(
                    margin: const EdgeInsets.only(left: 6, top: 4, bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    constraints: const BoxConstraints(maxWidth: 130),
                    decoration: BoxDecoration(
                      color: active ? AppColors.panel2 : AppColors.panel,
                      border: Border.all(color: active ? AppColors.cyan : AppColors.line),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            _tabs[i].title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: active ? AppColors.ink : AppColors.gray, fontSize: 10.5),
                          ),
                        ),
                        if (_tabs.length > 1) ...[
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => _closeTab(i),
                            child: const Icon(Icons.close, size: 13, color: AppColors.gray),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            onPressed: () => _addTab(),
            icon: const Icon(Icons.add, size: 18, color: AppColors.cyan),
          ),
          IconButton(
            onPressed: () => setState(() => _adBlockOn = !_adBlockOn),
            icon: Icon(Icons.shield,
                size: 16, color: _adBlockOn ? AppColors.cyan : AppColors.gray),
            tooltip: _adBlockOn ? 'AdBlock: ON' : 'AdBlock: OFF',
          ),
          IconButton(
            onPressed: () => setState(() => _dataSaverOn = !_dataSaverOn),
            icon: Icon(Icons.data_saver_off,
                size: 16, color: _dataSaverOn ? AppColors.cyan : AppColors.gray),
            tooltip: _dataSaverOn ? 'Data Saver: ON (gambar & video diblok)' : 'Data Saver: OFF',
          ),
        ],
      ),
    );
  }

  Widget _addressBar() {
    final tab = _tabs[_activeIndex];
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      decoration: const BoxDecoration(
        color: AppColors.panel,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () async {
              if (await tab.controller?.canGoBack() ?? false) {
                tab.controller?.goBack();
              }
            },
            icon: const Icon(Icons.arrow_back, size: 18, color: AppColors.ink),
          ),
          Expanded(
            child: TextField(
              controller: _urlController,
              style: const TextStyle(color: AppColors.ink, fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'Cari atau ketik URL...',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onSubmitted: _go,
            ),
          ),
          IconButton(
            onPressed: () => tab.controller?.reload(),
            icon: const Icon(Icons.refresh, size: 18, color: AppColors.cyan),
          ),
        ],
      ),
    );
  }

  Widget _buildWebView(int index) {
    final tab = _tabs[index];
    return Stack(
      children: [
        Positioned.fill(child: _buildInAppWebView(tab, index)),
        if (tab.errorMessage != null) Positioned.fill(child: _buildErrorOverlay(tab)),
      ],
    );
  }

  Widget _buildErrorOverlay(_BrowserTab tab) {
    return Container(
      color: AppColors.bg,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppColors.gray, size: 40),
          const SizedBox(height: 14),
          Text(tab.errorMessage!,
              textAlign: TextAlign.center, style: const TextStyle(color: AppColors.gray, fontSize: 12.5, height: 1.5)),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => tab.controller?.reload(),
            icon: const Icon(Icons.refresh, size: 16, color: AppColors.cyan),
            label: const Text('Coba Lagi', style: TextStyle(color: AppColors.ink)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.line)),
          ),
        ],
      ),
    );
  }

  Widget _buildInAppWebView(_BrowserTab tab, int index) {
    return InAppWebView(
      windowId: tab.windowId,
      initialUrlRequest: tab.windowId == null ? URLRequest(url: WebUri(tab.url)) : null,
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        useOnDownloadStart: true,
        supportMultipleWindows: true,
        javaScriptCanOpenWindowsAutomatically: true,
        mediaPlaybackRequiresUserGesture: _dataSaverOn,
      ),
      onWebViewCreated: (controller) => tab.controller = controller,
      onLoadStart: (controller, url) {
        setState(() {
          tab.loading = true;
          tab.errorMessage = null; // reload/navigasi baru -> bersihin error lama
          tab.url = url?.toString() ?? tab.url;
          if (index == _activeIndex) _urlController.text = tab.url;
        });
      },
      onLoadStop: (controller, url) async {
        final title = await controller.getTitle();
        setState(() {
          tab.loading = false;
          tab.title = (title?.isNotEmpty ?? false) ? title! : (url?.host ?? 'Tab');
        });
      },
      onReceivedError: (controller, request, error) async {
        // Resource kecil (iklan, tracker, gambar) sering gagal load wajar -
        // itu bukan masalah, jangan nampilin halaman error full buat itu.
        // Cuma tampilin error kalau yang gagal itu HALAMAN UTAMA-nya.
        if (!(request.isForMainFrame ?? true)) return;

        final connectivity = await Connectivity().checkConnectivity();
        final isOffline = connectivity.contains(ConnectivityResult.none) || connectivity.isEmpty;

        setState(() {
          tab.loading = false;
          if (isOffline) {
            tab.errorMessage = 'Gak ada koneksi internet. Cek WiFi/data seluler kamu.';
          } else if (error.description.toLowerCase().contains('refused')) {
            tab.errorMessage =
                'Server situs ini menolak koneksi (connection refused). Biasanya ini masalah dari situsnya sendiri (lagi down/nolak), bukan dari koneksi kamu - coba lagi nanti atau cek apakah linknya bener.';
          } else if (error.description.toLowerCase().contains('name_not_resolved') ||
              error.description.toLowerCase().contains('dns')) {
            tab.errorMessage =
                'Alamat situs ini gak ketemu (DNS gagal). Coba cek lagi URL-nya, atau ganti DNS di Settings > Browser kalau sering kejadian.';
          } else {
            tab.errorMessage = 'Gagal buka halaman ini: ${error.description}';
          }
        });
      },
      onCreateWindow: (controller, createWindowAction) async {
        // Situs coba buka tab baru (target="_blank" / window.open) ->
        // kita buatin tab baru beneran, bukan diilangin.
        _addTab(
          url: createWindowAction.request.url?.toString() ?? 'https://www.google.com',
          windowId: createWindowAction.windowId,
        );
        return true;
      },
      shouldInterceptRequest: (controller, request) async {
        final url = request.url.toString();
        if (_adBlockOn && AdBlockList.isBlocked(url)) {
          return WebResourceResponse(contentType: 'text/plain', data: Uint8List(0));
        }
        if (_dataSaverOn && _looksLikeImage(url)) {
          return WebResourceResponse(contentType: 'text/plain', data: Uint8List(0));
        }
        return null; // biarin request jalan normal
      },
    );
  }

  static bool _looksLikeImage(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.bmp') ||
        lower.endsWith('.svg');
  }
}
