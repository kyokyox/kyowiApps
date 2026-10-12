import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/seraph_header.dart';
import '../../../core/network/skippable_loading.dart';

/// Pake endpoint publik speed.cloudflare.com - ini endpoint resmi yang
/// beneran dipake produk speed test Cloudflare sendiri (bukan API abal-abal),
/// gratis, gak butuh API key, dan reliable karena disebar lewat jaringan
/// anycast Cloudflare.
class NetworkSpeedTestPage extends StatefulWidget {
  const NetworkSpeedTestPage({super.key});

  @override
  State<NetworkSpeedTestPage> createState() => _NetworkSpeedTestPageState();
}

enum _TestStage { idle, ping, download, upload, done }

class _NetworkSpeedTestPageState extends State<NetworkSpeedTestPage> with SkippableLoading<NetworkSpeedTestPage> {
  _TestStage _stage = _TestStage.idle;
  double? _pingMs;
  double? _downloadMbps;
  double? _uploadMbps;
  String? _error;

  static const _downloadTestBytes = 5 * 1000 * 1000; // 5 MB
  static const _uploadTestBytes = 2 * 1000 * 1000; // 2 MB

  Future<void> _runTest() async {
    final gen = startLoading();
    setState(() {
      _stage = _TestStage.ping;
      _pingMs = null;
      _downloadMbps = null;
      _uploadMbps = null;
      _error = null;
    });

    try {
      // 1. Ping - request kecil, ukur waktu round-trip
      final pingStart = DateTime.now();
      await http.get(Uri.parse('https://speed.cloudflare.com/__down?bytes=0'));
      if (!isCurrent(gen)) return;
      final pingMs = DateTime.now().difference(pingStart).inMilliseconds.toDouble();
      setState(() {
        _pingMs = pingMs;
        _stage = _TestStage.download;
      });

      // 2. Download test
      final downloadStart = DateTime.now();
      final downloadRes = await http.get(Uri.parse('https://speed.cloudflare.com/__down?bytes=$_downloadTestBytes'));
      if (!isCurrent(gen)) return;
      final downloadSeconds = DateTime.now().difference(downloadStart).inMilliseconds / 1000;
      final downloadMbps = (downloadRes.bodyBytes.length * 8 / 1000000) / downloadSeconds;
      setState(() {
        _downloadMbps = downloadMbps;
        _stage = _TestStage.upload;
      });

      // 3. Upload test
      final uploadData = Uint8List(_uploadTestBytes);
      final uploadStart = DateTime.now();
      await http.post(Uri.parse('https://speed.cloudflare.com/__up'), body: uploadData);
      if (!isCurrent(gen)) return;
      final uploadSeconds = DateTime.now().difference(uploadStart).inMilliseconds / 1000;
      final uploadMbps = (uploadData.length * 8 / 1000000) / uploadSeconds;
      setState(() {
        _uploadMbps = uploadMbps;
        _stage = _TestStage.done;
      });
    } catch (e) {
      if (!isCurrent(gen)) return;
      setState(() {
        _error = 'Tes gagal: $e';
        _stage = _TestStage.idle;
      });
    } finally {
      stopLoading();
    }
  }

  void _skip() {
    skipLoading();
    setState(() {
      _stage = _TestStage.idle;
      _error = 'Dibatalkan.';
    });
  }

  String get _stageLabel {
    switch (_stage) {
      case _TestStage.idle:
        return 'Tap buat mulai tes';
      case _TestStage.ping:
        return 'Mengukur ping...';
      case _TestStage.download:
        return 'Mengukur kecepatan download...';
      case _TestStage.upload:
        return 'Mengukur kecepatan upload...';
      case _TestStage.done:
        return 'Selesai!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _stage != _TestStage.idle && _stage != _TestStage.done;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
      children: [
        const SeraphHeader(title: 'Speed', accent: 'Test', subtitle: 'Tes kecepatan internet beneran, bukan gimmick'),
        Center(
          child: Column(
            children: [
              Text(_stageLabel, style: const TextStyle(color: AppColors.gray, fontSize: 12)),
              const SizedBox(height: 20),
              if (busy) const CircularProgressIndicator(color: AppColors.cyan),
              if (busy) SkipButton(visible: showSkipButton, onSkip: _skip),
              if (!busy)
                ElevatedButton(onPressed: _runTest, child: const Text('MULAI TES')),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.magenta, fontSize: 12)),
        ],
        if (_pingMs != null || _downloadMbps != null || _uploadMbps != null) ...[
          const SizedBox(height: 24),
          if (_pingMs != null) _resultCard('Ping', '${_pingMs!.toStringAsFixed(0)} ms', Icons.speed),
          if (_downloadMbps != null) _resultCard('Download', '${_downloadMbps!.toStringAsFixed(1)} Mbps', Icons.download),
          if (_uploadMbps != null) _resultCard('Upload', '${_uploadMbps!.toStringAsFixed(1)} Mbps', Icons.upload),
        ],
      ],
    );
  }

  Widget _resultCard(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.panel, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.cyan, size: 22),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(color: AppColors.gray, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(color: AppColors.ink, fontSize: 16, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
