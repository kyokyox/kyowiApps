import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/seraph_header.dart';

class ImageCompressorPage extends StatefulWidget {
  const ImageCompressorPage({super.key});

  @override
  State<ImageCompressorPage> createState() => _ImageCompressorPageState();
}

class _ImageCompressorPageState extends State<ImageCompressorPage> {
  Uint8List? _sourceBytes;
  int _sourceSizeBytes = 0;
  int _sourceWidth = 0;
  int _sourceHeight = 0;

  double _quality = 80;
  double _resizePercent = 100;

  Uint8List? _resultBytes;
  bool _busy = false;
  String? _error;

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.first.bytes;
    if (bytes == null) return;

    final decoded = img.decodeImage(bytes);
    setState(() {
      _sourceBytes = bytes;
      _sourceSizeBytes = bytes.length;
      _sourceWidth = decoded?.width ?? 0;
      _sourceHeight = decoded?.height ?? 0;
      _resultBytes = null;
      _error = null;
    });
  }

  Future<void> _process() async {
    if (_sourceBytes == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await Future(() {
        var image = img.decodeImage(_sourceBytes!);
        if (image == null) throw Exception('Gagal baca gambar.');

        if (_resizePercent < 100) {
          final newWidth = (image.width * _resizePercent / 100).round();
          image = img.copyResize(image, width: newWidth);
        }
        return Uint8List.fromList(img.encodeJpg(image, quality: _quality.round()));
      });
      setState(() => _resultBytes = result);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _saveToGallery() async {
    if (_resultBytes == null) return;
    try {
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: true);
        if (!granted) throw Exception('Izin akses galeri ditolak.');
      }
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(_resultBytes!);
      await Gal.putImage(file.path, album: 'Kyowi');
      await file.delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Tersimpan di Galeri')));
      }
    } catch (e) {
      setState(() => _error = 'Gagal simpan: $e');
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
      children: [
        const SeraphHeader(
            title: 'Image', accent: 'Compressor', subtitle: 'Kecilin ukuran & resize gambar, full lokal'),
        OutlinedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.image_outlined, color: AppColors.cyan),
          label: Text(_sourceBytes == null ? 'Pilih Gambar' : 'Ganti Gambar', style: const TextStyle(color: AppColors.ink)),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.line), padding: const EdgeInsets.symmetric(vertical: 14)),
        ),
        if (_sourceBytes != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(_sourceBytes!, height: 160, fit: BoxFit.cover, width: double.infinity),
          ),
          const SizedBox(height: 6),
          Text('Asli: ${_formatSize(_sourceSizeBytes)} • ${_sourceWidth}x$_sourceHeight px',
              style: const TextStyle(color: AppColors.gray, fontSize: 10.5)),
          const SizedBox(height: 18),
          Row(children: [
            const Text('Kualitas JPEG', style: TextStyle(color: AppColors.ink, fontSize: 12)),
            const Spacer(),
            Text('${_quality.round()}%', style: const TextStyle(color: AppColors.cyan, fontSize: 12)),
          ]),
          Slider(
            value: _quality, min: 10, max: 100, divisions: 18,
            activeColor: AppColors.cyan, inactiveColor: AppColors.line,
            onChanged: (v) => setState(() => _quality = v),
          ),
          Row(children: [
            const Text('Resize', style: TextStyle(color: AppColors.ink, fontSize: 12)),
            const Spacer(),
            Text('${_resizePercent.round()}% (${(_sourceWidth * _resizePercent / 100).round()}px)',
                style: const TextStyle(color: AppColors.cyan, fontSize: 12)),
          ]),
          Slider(
            value: _resizePercent, min: 10, max: 100, divisions: 18,
            activeColor: AppColors.cyan, inactiveColor: AppColors.line,
            onChanged: (v) => setState(() => _resizePercent = v),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _busy ? null : _process,
            child: Text(_busy ? 'MEMPROSES...' : 'PROSES GAMBAR'),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 14),
          Text(_error!, style: const TextStyle(color: AppColors.magenta, fontSize: 12)),
        ],
        if (_resultBytes != null) ...[
          const SizedBox(height: 18),
          const Text('HASIL', style: TextStyle(color: AppColors.gray, fontSize: 10, letterSpacing: 1)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(_resultBytes!, height: 180, fit: BoxFit.contain, width: double.infinity),
          ),
          const SizedBox(height: 6),
          Text('Hasil: ${_formatSize(_resultBytes!.length)} (hemat ${(100 - (_resultBytes!.length / _sourceSizeBytes * 100)).clamp(0, 100).toStringAsFixed(0)}%)',
              style: const TextStyle(color: AppColors.cyan, fontSize: 11)),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: _saveToGallery, child: const Text('SIMPAN KE GALERI')),
        ],
      ],
    );
  }
}
