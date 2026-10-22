import 'dart:typed_data';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:zikzak_inappwebview/zikzak_inappwebview.dart' hide SettingsController;
import '../../../core/theme/app_theme.dart';
import '../../../core/storage/settings_controller.dart';
import '../../../core/models/app_settings.dart';
import 'adblock_list.dart';

class BrowserPage extends StatefulWidget {
  final String initialUrl;
  const BrowserPage({super.key, this.initialUrl = 'https://www.google.com'});

  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage> {
  static const String homeUrl = 'https://www.google.com';

  InAppWebViewController? _controller;
  late TextEditingController _urlController;

  bool _loading = true;
  double _progress = 0;
  String? _errorMessage;
  bool _canGoBack = false;
  bool _canGoForward = false;

  bool _adBlockOn = true;
  bool _dataSaverOn = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialUrl);
  }

  // ============================== NAVIGASI ==============================

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
    _controller?.loadUrl(urlRequest: URLRequest(url: WebUri(target)));
  }

  Future<void> _goBack() async {
    if (await _controller?.canGoBack() ?? false) _controller?.goBack();
  }

  Future<void> _goForward() async {
    if (await _controller?.canGoForward() ?? false) _controller?.goForward();
  }

  void _goHome() {
    _urlController.text = homeUrl;
    _controller?.loadUrl(urlRequest: URLRequest(url: WebUri(homeUrl)));
  }

  void _reload() => _controller?.reload();

  Future<void> _updateNavState() async {
    final back = await _controller?.canGoBack() ?? false;
    final forward = await _controller?.canGoForward() ?? false;
    if (mounted) setState(() {
      _canGoBack = back;
      _canGoForward = forward;
    });
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

  // ============================== UI ==============================

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _toolbar(),
        _addressBar(),
        if (_loading)
          LinearProgressIndicator(
            value: _progress > 0 && _progress < 1 ? _progress : null,
            minHeight: 2,
            color: AppColors.cyan,
            backgroundColor: AppColors.line,
          ),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(child: _webView()),
              if (_errorMessage != null) Positioned.fill(child: _errorOverlay()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _toolbar() {
    return Container(
      height: 40,
      color: AppColors.bg,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, size: 18, color: _canGoBack ? AppColors.ink : AppColors.gray.withValues(alpha: 0.35)),
            onPressed: _canGoBack ? _goBack : null,
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward, size: 18, color: _canGoForward ? AppColors.ink : AppColors.gray.withValues(alpha: 0.35)),
            onPressed: _canGoForward ? _goForward : null,
          ),
          IconButton(icon: const Icon(Icons.refresh, size: 18, color: AppColors.ink), onPressed: _reload),
          IconButton(icon: const Icon(Icons.home_outlined, size: 18, color: AppColors.ink), onPressed: _goHome),
          const Spacer(),
          IconButton(
            onPressed: () => setState(() => _adBlockOn = !_adBlockOn),
            icon: Icon(Icons.shield, size: 16, color: _adBlockOn ? AppColors.cyan : AppColors.gray),
            tooltip: _adBlockOn ? 'AdBlock: ON' : 'AdBlock: OFF',
          ),
          IconButton(
            onPressed: () => setState(() => _dataSaverOn = !_dataSaverOn),
            icon: Icon(Icons.data_saver_off, size: 16, color: _dataSaverOn ? AppColors.cyan : AppColors.gray),
            tooltip: _dataSaverOn ? 'Data Saver: ON' : 'Data Saver: OFF',
          ),
          IconButton(
            onPressed: () => _openProxySettings(context),
            icon: const Icon(Icons.security, size: 16, color: AppColors.gray),
            tooltip: 'Pengaturan Proxy',
          ),
        ],
      ),
    );
  }

  Widget _addressBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      decoration: const BoxDecoration(
        color: AppColors.panel,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
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
    );
  }

  Widget _webView() {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        useOnDownloadStart: true,
        mediaPlaybackRequiresUserGesture: _dataSaverOn,
      ),
      onWebViewCreated: (controller) => _controller = controller,
      onLoadStart: (controller, url) {
        setState(() {
          _loading = true;
          _progress = 0;
          _errorMessage = null;
          if (url != null) _urlController.text = url.toString();
        });
      },
      onProgressChanged: (controller, progress) {
        setState(() => _progress = progress / 100);
      },
      onLoadStop: (controller, url) async {
        setState(() => _loading = false);
        await _updateNavState();
      },
      onReceivedError: (controller, request, error) async {
        // Resource kecil (iklan, tracker, gambar) sering gagal load wajar -
        // cuma tampilin error kalau yang gagal itu HALAMAN UTAMA-nya.
        if (!(request.isForMainFrame ?? true)) return;

        final connectivity = await Connectivity().checkConnectivity();
        final isOffline = connectivity.contains(ConnectivityResult.none) || connectivity.isEmpty;

        if (!mounted) return;
        setState(() {
          _loading = false;
          if (isOffline) {
            _errorMessage = 'Gak ada koneksi internet. Cek WiFi/data seluler kamu.';
          } else if (error.description.toLowerCase().contains('refused')) {
            _errorMessage =
                'Server situs ini menolak koneksi (connection refused). Biasanya masalah dari situsnya sendiri (lagi down/nolak), bukan dari koneksi kamu.';
          } else if (error.description.toLowerCase().contains('name_not_resolved') ||
              error.description.toLowerCase().contains('dns')) {
            _errorMessage = 'Alamat situs ini gak ketemu (DNS gagal). Cek lagi URL-nya.';
          } else {
            _errorMessage = 'Gagal buka halaman ini: ${error.description}';
          }
        });
      },
      shouldInterceptRequest: (controller, request) async {
        final url = request.url.toString();
        if (_adBlockOn && AdBlockList.isBlocked(url)) {
          return WebResourceResponse(contentType: 'text/plain', data: Uint8List(0));
        }
        if (_dataSaverOn && _looksLikeImage(url)) {
          return WebResourceResponse(contentType: 'text/plain', data: Uint8List(0));
        }
        return null;
      },
    );
  }

  Widget _errorOverlay() {
    return Container(
      color: AppColors.bg,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppColors.gray, size: 40),
          const SizedBox(height: 14),
          Text(_errorMessage!,
              textAlign: TextAlign.center, style: const TextStyle(color: AppColors.gray, fontSize: 12.5, height: 1.5)),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: _reload,
            icon: const Icon(Icons.refresh, size: 16, color: AppColors.cyan),
            label: const Text('Coba Lagi', style: TextStyle(color: AppColors.ink)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.line)),
          ),
        ],
      ),
    );
  }

  void _openProxySettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.panel,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _ProxySettingsSheet(onApplied: _reload),
    );
  }
}

class _ProxySettingsSheet extends StatefulWidget {
  final VoidCallback onApplied;
  const _ProxySettingsSheet({required this.onApplied});

  @override
  State<_ProxySettingsSheet> createState() => _ProxySettingsSheetState();
}

enum _ProxyStatus { idle, checking, connected, failed, unsupported }

class _ProxySettingsSheetState extends State<_ProxySettingsSheet> {
  bool _useProxy = false;
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '8080');
  String? _hostError;
  String? _portError;
  _ProxyStatus _status = _ProxyStatus.idle;
  String? _statusDetail;

  // Host: hostname (proxy.contoh.com) atau IPv4.
  static final _hostPattern = RegExp(
    r'^(([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}|'
    r'(\d{1,3}\.){3}\d{1,3})$',
  );

  bool _validate() {
    setState(() {
      _hostError = null;
      _portError = null;
    });
    var valid = true;

    final host = _hostController.text.trim();
    if (host.isEmpty) {
      setState(() => _hostError = 'Host gak boleh kosong');
      valid = false;
    } else if (!_hostPattern.hasMatch(host)) {
      setState(() => _hostError = 'Format host gak valid (contoh: 192.168.1.1 atau proxy.contoh.com)');
      valid = false;
    }

    final port = int.tryParse(_portController.text.trim());
    if (port == null) {
      setState(() => _portError = 'Port harus angka');
      valid = false;
    } else if (port < 1 || port > 65535) {
      setState(() => _portError = 'Port harus antara 1-65535');
      valid = false;
    }

    return valid;
  }

  Future<void> _apply() async {
    if (!_useProxy) {
      try {
        await ProxyController.instance().clearProxyOverride();
        setState(() {
          _status = _ProxyStatus.idle;
          _statusDetail = 'Proxy dimatiin, pakai jaringan normal.';
        });
        widget.onApplied();
      } catch (e) {
        setState(() {
          _status = _ProxyStatus.failed;
          _statusDetail = 'Gagal matiin proxy: $e';
        });
      }
      return;
    }

    if (!_validate()) return;

    setState(() {
      _status = _ProxyStatus.checking;
      _statusDetail = null;
    });

    try {
      final supported = await WebViewFeature.isFeatureSupported(WebViewFeature.PROXY_OVERRIDE);
      if (!supported) {
        setState(() {
          _status = _ProxyStatus.unsupported;
          _statusDetail = 'WebView di device ini gak dukung pengaturan proxy custom.';
        });
        return;
      }

      final host = _hostController.text.trim();
      final port = _portController.text.trim();

      await ProxyController.instance().setProxyOverride(
        settings: ProxySettings(
          proxyRules: [ProxyRule(url: '$host:$port')],
          bypassRules: [],
        ),
      );

      setState(() {
        _status = _ProxyStatus.connected;
        _statusDetail = 'Proxy diterapkan ($host:$port). Halaman bakal di-reload.';
      });
      widget.onApplied();
    } catch (e) {
      setState(() {
        _status = _ProxyStatus.failed;
        _statusDetail = 'Gagal terapin proxy: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pengaturan Proxy', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 4),
          const Text(
            'Proxy diterapkan lewat ProxyController, API resmi Android WebView (BUKAN teknik bypass/scraping). Kamu yang isi host & port server proxy milikmu sendiri.',
            style: TextStyle(color: AppColors.gray, fontSize: 10.5, height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: Text('Gunakan Proxy', style: TextStyle(color: AppColors.ink, fontSize: 13))),
              Switch(value: _useProxy, activeColor: AppColors.cyan, onChanged: (v) => setState(() => _useProxy = v)),
            ],
          ),
          if (_useProxy) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _hostController,
              style: const TextStyle(color: AppColors.ink, fontSize: 13),
              decoration: InputDecoration(hintText: 'Host, contoh: 192.168.1.10', errorText: _hostError),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _portController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.ink, fontSize: 13),
              decoration: InputDecoration(hintText: 'Port, contoh: 8080', errorText: _portError),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _status == _ProxyStatus.checking ? null : _apply,
            child: Text(_status == _ProxyStatus.checking ? 'MENGECEK...' : 'TERAPKAN'),
          ),
          if (_status != _ProxyStatus.idle || _statusDetail != null) ...[
            const SizedBox(height: 12),
            _statusCard(),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.line)),
            child: const Text(
              '⚠ Batasan penting: proxy ini cuma ngatur jaringan WebView di app ini, bukan seluruh HP. Proxy TIDAK MENJAMIN semua jenis pemblokiran bisa dilewatin (ada blokir di level DNS, SNI/TLS, atau konten yang gak terpengaruh proxy HTTP biasa). Pastiin proxy yang kamu pakai legal, server milikmu sendiri atau yang kamu percaya, dan tetap patuhi kebijakan platform & hukum yang berlaku di wilayahmu.',
              style: TextStyle(color: AppColors.gray, fontSize: 10, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCard() {
    Color color;
    IconData icon;
    switch (_status) {
      case _ProxyStatus.connected:
        color = AppColors.cyan;
        icon = Icons.check_circle_outline;
        break;
      case _ProxyStatus.failed:
      case _ProxyStatus.unsupported:
        color = AppColors.magenta;
        icon = Icons.error_outline;
        break;
      case _ProxyStatus.checking:
        color = AppColors.gray;
        icon = Icons.hourglass_empty;
        break;
      case _ProxyStatus.idle:
        color = AppColors.gray;
        icon = Icons.info_outline;
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), border: Border.all(color: color.withValues(alpha: 0.4)), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(_statusDetail ?? '', style: TextStyle(color: color, fontSize: 11))),
        ],
      ),
    );
  }
}
