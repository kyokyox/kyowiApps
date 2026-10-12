import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/seraph_header.dart';

class FileCompressorPage extends StatefulWidget {
  const FileCompressorPage({super.key});

  @override
  State<FileCompressorPage> createState() => _FileCompressorPageState();
}

class _FileCompressorPageState extends State<FileCompressorPage> {
  bool _isZipMode = true;
  List<PlatformFile> _selectedFiles = [];
  PlatformFile? _selectedZip;
  bool _busy = false;
  String? _resultPath;
  String? _error;

  Future<void> _pickFilesToZip() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true, withData: true);
    if (result == null) return;
    setState(() {
      _selectedFiles = result.files;
      _resultPath = null;
      _error = null;
    });
  }

  Future<void> _pickZipToExtract() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _selectedZip = result.files.first;
      _resultPath = null;
      _error = null;
    });
  }

  Future<void> _zipFiles() async {
    if (_selectedFiles.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final archive = Archive();
      for (final file in _selectedFiles) {
        if (file.bytes == null) continue;
        archive.addFile(ArchiveFile(file.name, file.bytes!.length, file.bytes));
      }
      final zipBytes = ZipEncoder().encode(archive);
      if (zipBytes == null) throw Exception('Gagal encode zip.');

      final tempDir = await getTemporaryDirectory();
      final outFile = File('${tempDir.path}/kyowi_compressed_${DateTime.now().millisecondsSinceEpoch}.zip');
      await outFile.writeAsBytes(zipBytes);

      final savedPath = await FilePicker.platform.saveFile(
        fileName: 'compressed.zip',
        bytes: Uint8List.fromList(zipBytes),
      );

      setState(() => _resultPath = savedPath ?? outFile.path);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _extractZip() async {
    if (_selectedZip?.bytes == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final archive = ZipDecoder().decodeBytes(_selectedZip!.bytes!);
      final tempDir = await getTemporaryDirectory();
      final extractDir = Directory('${tempDir.path}/extracted_${DateTime.now().millisecondsSinceEpoch}');
      await extractDir.create(recursive: true);

      for (final file in archive) {
        if (file.isFile) {
          final data = file.content as List<int>;
          final outFile = File('${extractDir.path}/${file.name}');
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(data);
        } else {
          await Directory('${extractDir.path}/${file.name}').create(recursive: true);
        }
      }

      setState(() => _resultPath = extractDir.path);
    } catch (e) {
      setState(() => _error = 'Gagal ekstrak (mungkin bukan file zip valid): $e');
    } finally {
      setState(() => _busy = false);
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
        const SeraphHeader(title: 'File', accent: 'Compressor', subtitle: 'Kompres/ekstrak file .zip'),
        Row(
          children: [
            Expanded(child: _modeBtn('Zip File', _isZipMode, () => setState(() => _isZipMode = true))),
            const SizedBox(width: 8),
            Expanded(child: _modeBtn('Unzip', !_isZipMode, () => setState(() => _isZipMode = false))),
          ],
        ),
        const SizedBox(height: 16),
        if (_isZipMode) ...[
          OutlinedButton.icon(
            onPressed: _pickFilesToZip,
            icon: const Icon(Icons.attach_file, color: AppColors.cyan),
            label: const Text('Pilih File(s)', style: TextStyle(color: AppColors.ink)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.line), padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
          if (_selectedFiles.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final f in _selectedFiles)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• ${f.name} (${_formatSize(f.size)})', style: const TextStyle(color: AppColors.gray, fontSize: 11)),
              ),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _busy ? null : _zipFiles, child: Text(_busy ? 'MEMPROSES...' : 'KOMPRES JADI ZIP')),
          ],
        ] else ...[
          OutlinedButton.icon(
            onPressed: _pickZipToExtract,
            icon: const Icon(Icons.folder_zip_outlined, color: AppColors.cyan),
            label: Text(_selectedZip?.name ?? 'Pilih File .zip', style: const TextStyle(color: AppColors.ink)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.line), padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
          if (_selectedZip != null) ...[
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _busy ? null : _extractZip, child: Text(_busy ? 'MEMPROSES...' : 'EKSTRAK')),
          ],
        ],
        if (_error != null) ...[
          const SizedBox(height: 14),
          Text(_error!, style: const TextStyle(color: AppColors.magenta, fontSize: 12)),
        ],
        if (_resultPath != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.panel, border: Border.all(color: AppColors.cyan.withValues(alpha: 0.4)), borderRadius: BorderRadius.circular(10)),
            child: Text('✓ Selesai: $_resultPath', style: const TextStyle(color: AppColors.cyan, fontSize: 11)),
          ),
        ],
      ],
    );
  }

  Widget _modeBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: active ? AppColors.panel2 : AppColors.panel, border: Border.all(color: active ? AppColors.cyan : AppColors.line), borderRadius: BorderRadius.circular(10)),
        child: Text(label, style: TextStyle(color: active ? AppColors.ink : AppColors.gray, fontWeight: FontWeight.w700, fontSize: 12)),
      ),
    );
  }
}
